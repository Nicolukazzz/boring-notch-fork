//
//  ForkTabs.swift
//  boringNotch
//
//  Extra notch tabs added by this personal fork.
//

import Defaults

enum ForkTabs {
    static let pomodoro = TabModel(label: "Pomodoro", icon: "timer", view: .pomodoro)
    static let stats = TabModel(label: "Stats", icon: "gauge.with.dots.needle.33percent", view: .stats)

    /// Tabs appended after upstream's Home and Shelf.
    static var extra: [TabModel] {
        var result: [TabModel] = []
        if Defaults[.pomodoroEnabled] { result.append(pomodoro) }
        if Defaults[.statsEnabled] { result.append(stats) }
        return result
    }

    /// The tab bar must show whenever a fork tab exists, even with an empty shelf.
    static var showsTabBar: Bool {
        !extra.isEmpty
    }

    /// Falls back to Home when the current tab gets disabled in Settings.
    @MainActor
    static func leaveIfCurrent(_ view: NotchViews) {
        if BoringViewCoordinator.shared.currentView == view {
            BoringViewCoordinator.shared.currentView = .home
        }
    }
}
