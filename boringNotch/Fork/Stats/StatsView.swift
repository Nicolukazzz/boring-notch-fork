//
//  StatsView.swift
//  boringNotch
//
//  Created by Nicolas on 2026-10-21.
//

import SwiftUI

private enum StatLevel {
    case good, high, critical

    init(fraction: Double) {
        switch fraction {
        case ..<0.6: self = .good
        case ..<0.85: self = .high
        default: self = .critical
        }
    }

    var color: Color {
        switch self {
        case .good: return Color(red: 0.4, green: 0.824, blue: 0.4)
        case .high: return Color(red: 1.0, green: 0.8, blue: 0.0)
        case .critical: return Color(red: 1.0, green: 0.271, blue: 0.227)
        }
    }
}

private struct StatGauge: View {
    let value: String
    let title: String
    let subtitle: String?
    let fraction: Double
    let color: Color

    var body: some View {
        VStack(spacing: 6) {
            ZStack {
                PomodoroRing(progress: fraction, color: color, lineWidth: 6)
                Text(value)
                    .font(.system(size: 15, weight: .semibold, design: .rounded))
                    .monospacedDigit()
                    .foregroundStyle(.white)
                    .contentTransition(.numericText())
                    .animation(.smooth, value: value)
            }
            .frame(width: 66, height: 66)

            VStack(spacing: 1) {
                Text(title)
                    .font(.system(size: 12, weight: .semibold, design: .rounded))
                    .foregroundStyle(.white)
                Text(subtitle ?? " ")
                    .font(.system(size: 10, weight: .medium, design: .rounded))
                    .foregroundStyle(.gray)
                    .monospacedDigit()
            }
        }
        .frame(width: 84)
    }
}

struct StatsView: View {
    @EnvironmentObject var vm: BoringViewModel
    @ObservedObject var stats = SystemStatsManager.shared

    var body: some View {
        HStack(alignment: .center, spacing: 28) {
            HStack(spacing: 8) {
                cpuGauge
                memoryGauge
                temperatureGauge
            }
            details
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
        .transition(.asymmetric(insertion: .opacity.combined(with: .move(edge: .top)), removal: .opacity))
        .blur(radius: vm.notchState == .closed ? 30 : 0)
        .onAppear { stats.start() }
        .onDisappear { stats.stop() }
    }

    // MARK: - Gauges

    private var cpuGauge: some View {
        StatGauge(
            value: "\(Int((stats.cpuUsage * 100).rounded()))%",
            title: "CPU",
            subtitle: StatLevel(fraction: stats.cpuUsage) == .good ? "Relaxed" : "Busy",
            fraction: stats.cpuUsage,
            color: StatLevel(fraction: stats.cpuUsage).color
        )
    }

    private var memoryGauge: some View {
        StatGauge(
            value: "\(Int((stats.memoryFraction * 100).rounded()))%",
            title: "Memory",
            subtitle: "\(formatGB(stats.memoryUsed)) of \(formatGB(stats.memoryTotal))",
            fraction: stats.memoryFraction,
            color: StatLevel(fraction: stats.memoryFraction).color
        )
    }

    private var temperatureGauge: some View {
        let reading = temperatureReading
        return StatGauge(
            value: reading.value,
            title: "Temperature",
            subtitle: reading.label,
            fraction: reading.fraction,
            color: reading.level.color
        )
    }

    /// Celsius from the helper when available, otherwise macOS' coarse thermal state.
    private var temperatureReading: (value: String, label: String, fraction: Double, level: StatLevel) {
        if let celsius = stats.temperature {
            let fraction = min(1, max(0, (celsius - 25) / 75))
            switch celsius {
            case ..<50: return ("\(Int(celsius))°", "Cool", fraction, .good)
            case ..<70: return ("\(Int(celsius))°", "Warm", fraction, .good)
            case ..<85: return ("\(Int(celsius))°", "Hot", fraction, .high)
            default: return ("\(Int(celsius))°", "Very hot", fraction, .critical)
            }
        }
        switch stats.thermalState {
        case .nominal: return ("OK", "Normal", 0.25, .good)
        case .fair: return ("OK", "Warm", 0.5, .good)
        case .serious: return ("!", "Hot", 0.8, .high)
        case .critical: return ("!!", "Very hot", 1, .critical)
        @unknown default: return ("–", "Unknown", 0, .good)
        }
    }

    // MARK: - Details

    private var details: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(spacing: 10) {
                Image(systemName: "internaldrive.fill")
                    .font(.system(size: 18))
                    .foregroundStyle(.gray)
                    .frame(width: 28)
                VStack(alignment: .leading, spacing: 1) {
                    Text(stats.diskFree > 0 ? ByteCountFormatter.string(fromByteCount: stats.diskFree, countStyle: .file) : "–")
                        .font(.system(size: 14, weight: .semibold, design: .rounded))
                        .foregroundStyle(.white)
                    Text("free on disk")
                        .font(.system(size: 11, weight: .medium, design: .rounded))
                        .foregroundStyle(.gray)
                }
            }

            HStack(spacing: 10) {
                if let app = stats.topApp {
                    Image(nsImage: app.icon)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 28, height: 28)
                    VStack(alignment: .leading, spacing: 1) {
                        Text(app.name)
                            .font(.system(size: 14, weight: .semibold, design: .rounded))
                            .foregroundStyle(.white)
                            .lineLimit(1)
                        Text("is working hardest")
                            .font(.system(size: 11, weight: .medium, design: .rounded))
                            .foregroundStyle(.gray)
                    }
                } else {
                    Image(systemName: "app.dashed")
                        .font(.system(size: 18))
                        .foregroundStyle(.gray)
                        .frame(width: 28)
                    Text("Checking apps…")
                        .font(.system(size: 11, weight: .medium, design: .rounded))
                        .foregroundStyle(.gray)
                }
            }
            .animation(.smooth, value: stats.topApp?.name)
        }
        .frame(width: 170, alignment: .leading)
    }

    private func formatGB(_ bytes: UInt64) -> String {
        let gb = Double(bytes) / 1_073_741_824
        return gb >= 10 ? "\(Int(gb.rounded())) GB" : String(format: "%.1f GB", gb)
    }
}
