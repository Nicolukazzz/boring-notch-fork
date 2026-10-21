//
//  SystemStatsManager.swift
//  boringNotch
//
//  Created by Nicolas on 2026-10-21.
//

import AppKit
import Darwin
import SwiftUI

@MainActor
final class SystemStatsManager: ObservableObject {
    static let shared = SystemStatsManager()

    struct TopApp: Equatable {
        let name: String
        let icon: NSImage
        let cpu: Double
    }

    @Published private(set) var cpuUsage: Double = 0
    @Published private(set) var memoryUsed: UInt64 = 0
    let memoryTotal: UInt64 = ProcessInfo.processInfo.physicalMemory
    /// Chip temperature in °C; nil when the helper can't read sensors.
    @Published private(set) var temperature: Double?
    @Published private(set) var thermalState: ProcessInfo.ThermalState = ProcessInfo.processInfo.thermalState
    @Published private(set) var diskFree: Int64 = 0
    @Published private(set) var topApp: TopApp?

    private var samplingTask: Task<Void, Never>?
    private var previousCPUTicks: (used: UInt64, total: UInt64)?
    private var viewers = 0

    private init() {}

    var memoryFraction: Double {
        memoryTotal > 0 ? Double(memoryUsed) / Double(memoryTotal) : 0
    }

    // MARK: - Lifecycle

    /// Samples only while some view is showing the stats, so nothing runs in the background.
    func start() {
        viewers += 1
        guard samplingTask == nil else { return }
        samplingTask = Task { [weak self] in
            while !Task.isCancelled {
                await self?.sample()
                try? await Task.sleep(for: .seconds(2))
            }
        }
    }

    func stop() {
        viewers = max(0, viewers - 1)
        guard viewers == 0 else { return }
        samplingTask?.cancel()
        samplingTask = nil
        previousCPUTicks = nil
    }

    // MARK: - Sampling

    private func sample() async {
        cpuUsage = readCPUUsage() ?? cpuUsage
        memoryUsed = readMemoryUsed() ?? memoryUsed
        diskFree = readDiskFree() ?? diskFree
        thermalState = ProcessInfo.processInfo.thermalState

        async let temperature = XPCHelperClient.shared.currentTemperature()
        async let apps = XPCHelperClient.shared.topCPUApps()
        self.temperature = await temperature
        let topApps = await apps
        if !topApps.isEmpty {
            topApp = resolveTopApp(from: topApps)
        }
    }

    private func readCPUUsage() -> Double? {
        var info = host_cpu_load_info()
        var count = mach_msg_type_number_t(MemoryLayout<host_cpu_load_info>.stride / MemoryLayout<integer_t>.stride)
        let result = withUnsafeMutablePointer(to: &info) {
            $0.withMemoryRebound(to: integer_t.self, capacity: Int(count)) {
                host_statistics(mach_host_self(), HOST_CPU_LOAD_INFO, $0, &count)
            }
        }
        guard result == KERN_SUCCESS else { return nil }

        let user = UInt64(info.cpu_ticks.0), system = UInt64(info.cpu_ticks.1)
        let idle = UInt64(info.cpu_ticks.2), nice = UInt64(info.cpu_ticks.3)
        let used = user + system + nice
        let total = used + idle
        defer { previousCPUTicks = (used, total) }

        guard let previous = previousCPUTicks, total > previous.total else { return nil }
        return Double(used - previous.used) / Double(total - previous.total)
    }

    /// Matches Activity Monitor's "Memory Used": app memory + wired + compressed.
    private func readMemoryUsed() -> UInt64? {
        var stats = vm_statistics64()
        var count = mach_msg_type_number_t(MemoryLayout<vm_statistics64>.stride / MemoryLayout<integer_t>.stride)
        let result = withUnsafeMutablePointer(to: &stats) {
            $0.withMemoryRebound(to: integer_t.self, capacity: Int(count)) {
                host_statistics64(mach_host_self(), HOST_VM_INFO64, $0, &count)
            }
        }
        guard result == KERN_SUCCESS else { return nil }

        let pageSize = UInt64(sysconf(_SC_PAGESIZE))
        let appPages = UInt64(stats.internal_page_count) - UInt64(stats.purgeable_count)
        let pages = appPages + UInt64(stats.wire_count) + UInt64(stats.compressor_page_count)
        return pages * pageSize
    }

    private func readDiskFree() -> Int64? {
        let values = try? URL(fileURLWithPath: "/").resourceValues(forKeys: [.volumeAvailableCapacityForImportantUsageKey])
        return values?.volumeAvailableCapacityForImportantUsage
    }

    private func resolveTopApp(from apps: [(pid: pid_t, cpu: Double)]) -> TopApp? {
        let ownPID = ProcessInfo.processInfo.processIdentifier
        for entry in apps where entry.pid != ownPID {
            guard let app = NSRunningApplication(processIdentifier: entry.pid),
                  app.activationPolicy == .regular,
                  let name = app.localizedName
            else { continue }
            return TopApp(name: name, icon: app.icon ?? NSImage(), cpu: entry.cpu)
        }
        return nil
    }
}
