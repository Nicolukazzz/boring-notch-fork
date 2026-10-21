//
//  BoringNotchXPCHelper+Stats.swift
//  BoringNotchXPCHelper
//
//  Fork-only helper calls for the Stats tab, kept out of BoringNotchXPCHelper.swift.
//

import Foundation

extension BoringNotchXPCHelper {
    @objc func currentTemperature(with reply: @escaping (NSNumber?) -> Void) {
        reply(SystemSensors.shared.temperature().map { NSNumber(value: $0) })
    }

    /// JSON array of `[pid, cpuPercent]` pairs, highest usage first.
    @objc func topCPUApps(with reply: @escaping (Data) -> Void) {
        let pairs = SystemSensors.shared.topCPUApps()
        reply((try? JSONSerialization.data(withJSONObject: pairs)) ?? Data("[]".utf8))
    }
}
