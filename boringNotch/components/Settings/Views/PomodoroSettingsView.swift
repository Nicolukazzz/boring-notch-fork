//
//  PomodoroSettingsView.swift
//  boringNotch
//
//  Created by Nicolas on 2026-10-21.
//

import Defaults
import SwiftUI

struct PomodoroSettingsView: View {
    @Default(.pomodoroEnabled) var pomodoroEnabled
    @Default(.pomodoroFocusMinutes) var focusMinutes
    @Default(.pomodoroShortBreakMinutes) var shortBreakMinutes
    @Default(.pomodoroLongBreakMinutes) var longBreakMinutes
    @Default(.pomodoroRoundsBeforeLongBreak) var rounds

    var body: some View {
        Form {
            Section {
                Defaults.Toggle(key: .pomodoroEnabled) {
                    Text("Enable Pomodoro tab")
                }
                .onChange(of: pomodoroEnabled) {
                    if !pomodoroEnabled {
                        PomodoroManager.shared.reset()
                        ForkTabs.leaveIfCurrent(.pomodoro)
                    }
                }
                Defaults.Toggle(key: .pomodoroShowWhenClosed) {
                    Text("Show timer in closed notch")
                }
                .disabled(!pomodoroEnabled)
                Defaults.Toggle(key: .pomodoroSound) {
                    Text("Play sound when a session ends")
                }
                .disabled(!pomodoroEnabled)
            } header: {
                Text("General")
            }

            Section {
                Stepper(value: $focusMinutes, in: 1...120) {
                    Text("Focus: \(focusMinutes) min")
                }
                Stepper(value: $shortBreakMinutes, in: 1...60) {
                    Text("Short break: \(shortBreakMinutes) min")
                }
                Stepper(value: $longBreakMinutes, in: 1...90) {
                    Text("Long break: \(longBreakMinutes) min")
                }
                Stepper(value: $rounds, in: 1...12) {
                    Text("Rounds before long break: \(rounds)")
                }
            } header: {
                Text("Durations")
            } footer: {
                Text("Changes apply to the next session that hasn't started yet.")
            }
            .disabled(!pomodoroEnabled)
        }
        .accentColor(.effectiveAccent)
        .navigationTitle("Pomodoro")
    }
}
