//
//  SystemSensors.swift
//  BoringNotchXPCHelper
//
//  Created by Nicolas on 2026-10-21.
//

import Darwin
import Foundation

/// Reads data the sandboxed app cannot: chip temperature (private IOHID event system)
/// and per-app CPU usage across the user's processes.
final class SystemSensors: @unchecked Sendable { // mutable state is guarded by `lock`
    static let shared = SystemSensors()

    // MARK: - Temperature

    private typealias ClientCreateFn = @convention(c) (CFAllocator?) -> Unmanaged<AnyObject>?
    private typealias SetMatchingFn = @convention(c) (AnyObject, CFDictionary) -> Void
    private typealias CopyServicesFn = @convention(c) (AnyObject) -> Unmanaged<CFArray>?
    private typealias CopyEventFn = @convention(c) (AnyObject, Int64, Int32, Int64) -> Unmanaged<AnyObject>?
    private typealias GetFloatFn = @convention(c) (AnyObject, Int32) -> Double
    private typealias CopyPropertyFn = @convention(c) (AnyObject, CFString) -> Unmanaged<CFTypeRef>?

    private let kIOHIDEventTypeTemperature: Int64 = 15
    private let lock = NSLock()
    private var temperatureServices: [AnyObject] = []
    private var hidClient: AnyObject?
    private var copyEvent: CopyEventFn?
    private var getFloat: GetFloatFn?

    private init() {
        setUpTemperatureSensors()
    }

    private func setUpTemperatureSensors() {
        guard let handle = dlopen("/System/Library/Frameworks/IOKit.framework/IOKit", RTLD_NOW) else { return }
        func load<T>(_ name: String) -> T? {
            guard let sym = dlsym(handle, name) else { return nil }
            return unsafeBitCast(sym, to: T.self)
        }
        guard let create: ClientCreateFn = load("IOHIDEventSystemClientCreate"),
              let setMatching: SetMatchingFn = load("IOHIDEventSystemClientSetMatching"),
              let copyServices: CopyServicesFn = load("IOHIDEventSystemClientCopyServices"),
              let copyProperty: CopyPropertyFn = load("IOHIDServiceClientCopyProperty"),
              let copyEvent: CopyEventFn = load("IOHIDServiceClientCopyEvent"),
              let getFloat: GetFloatFn = load("IOHIDEventGetFloatValue"),
              let client = create(kCFAllocatorDefault)?.takeRetainedValue()
        else { return }

        // Apple vendor page 0xff00, usage 5 = temperature sensors.
        setMatching(client, ["PrimaryUsagePage": 0xff00, "PrimaryUsage": 5] as CFDictionary)
        let services = (copyServices(client)?.takeRetainedValue() as? [AnyObject]) ?? []

        // "tdie" sensors sit on the SoC die and track how hot the chip actually is.
        temperatureServices = services.filter { service in
            let name = copyProperty(service, "Product" as CFString)?.takeRetainedValue() as? String
            return name?.contains("tdie") == true
        }
        hidClient = client
        self.copyEvent = copyEvent
        self.getFloat = getFloat
    }

    /// Average chip temperature in °C, or nil when sensors are unavailable.
    func temperature() -> Double? {
        lock.lock()
        defer { lock.unlock() }
        guard let copyEvent, let getFloat, !temperatureServices.isEmpty else { return nil }

        let field = Int32(kIOHIDEventTypeTemperature << 16)
        let readings = temperatureServices.compactMap { service -> Double? in
            guard let event = copyEvent(service, kIOHIDEventTypeTemperature, 0, 0)?.takeRetainedValue() else { return nil }
            let value = getFloat(event, field)
            return (5...130).contains(value) ? value : nil
        }
        guard !readings.isEmpty else { return nil }
        return readings.reduce(0, +) / Double(readings.count)
    }

    // MARK: - Top apps by CPU

    private typealias ResponsiblePIDFn = @convention(c) (pid_t) -> pid_t
    private lazy var responsiblePID: ResponsiblePIDFn? = {
        guard let sym = dlsym(UnsafeMutableRawPointer(bitPattern: -2), "responsibility_get_pid_responsible_for_pid") else { return nil }
        return unsafeBitCast(sym, to: ResponsiblePIDFn.self)
    }()

    private var lastCPUTimes: [pid_t: UInt64] = [:]
    private var lastSampleTime: UInt64 = 0
    private lazy var timebase: mach_timebase_info_data_t = {
        var info = mach_timebase_info_data_t()
        mach_timebase_info(&info)
        return info
    }()

    /// Returns `[responsible pid, cpu percent]` pairs sorted by usage, measured since the previous call.
    /// The first call only primes the sample and returns an empty list.
    func topCPUApps(limit: Int = 8) -> [[Double]] {
        lock.lock()
        defer { lock.unlock() }

        let count = proc_listallpids(nil, 0)
        guard count > 0 else { return [] }
        var pids = [pid_t](repeating: 0, count: Int(count) * 2)
        let filled = proc_listallpids(&pids, Int32(pids.count * MemoryLayout<pid_t>.size))
        guard filled > 0 else { return [] }

        var cpuTimes: [pid_t: UInt64] = [:]
        for pid in pids.prefix(Int(filled)) where pid > 0 {
            var info = rusage_info_v4()
            let result = withUnsafeMutablePointer(to: &info) { pointer in
                pointer.withMemoryRebound(to: rusage_info_t?.self, capacity: 1) {
                    proc_pid_rusage(pid, RUSAGE_INFO_V4, $0)
                }
            }
            if result == 0 {
                cpuTimes[pid] = info.ri_user_time + info.ri_system_time
            }
        }

        let now = mach_absolute_time()
        defer {
            lastCPUTimes = cpuTimes
            lastSampleTime = now
        }
        guard lastSampleTime > 0 else { return [] }

        // rusage times are in mach ticks on Apple Silicon; convert both sides to nanoseconds.
        let wallNanos = Double(now - lastSampleTime) * Double(timebase.numer) / Double(timebase.denom)
        guard wallNanos > 0 else { return [] }

        var usageByApp: [pid_t: Double] = [:]
        for (pid, total) in cpuTimes {
            guard let previous = lastCPUTimes[pid], total >= previous else { continue }
            let cpuNanos = Double(total - previous) * Double(timebase.numer) / Double(timebase.denom)
            let owner = responsiblePID?(pid) ?? pid
            usageByApp[owner > 0 ? owner : pid, default: 0] += cpuNanos / wallNanos * 100
        }

        return usageByApp
            .sorted { $0.value > $1.value }
            .prefix(limit)
            .map { [Double($0.key), $0.value] }
    }
}
