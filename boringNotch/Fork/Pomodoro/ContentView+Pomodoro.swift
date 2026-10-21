//
//  ContentView+Pomodoro.swift
//  boringNotch
//
//  Closed-notch hooks for the Pomodoro live activity, kept outside ContentView.swift.
//

import Defaults
import SwiftUI

extension ContentView {
    var showsPomodoroActivity: Bool {
        let announcing = coordinator.expandingView.show && coordinator.expandingView.type == .pomodoro
        return vm.notchState == .closed && !vm.hideOnClosed && Defaults[.pomodoroEnabled]
            && (announcing || (pomodoro.isRunning && Defaults[.pomodoroShowWhenClosed]))
    }

    /// Extra chin width so the ring and the phase dot sit outside the hardware notch.
    var pomodoroChinExtraWidth: CGFloat {
        2 * max(0, vm.effectiveClosedNotchHeight - 12) + 20
    }
}
