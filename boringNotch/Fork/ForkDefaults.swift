//
//  ForkDefaults.swift
//  boringNotch
//
//  Settings keys for features that only exist in this personal fork.
//  Kept out of Constants.swift so upstream updates don't conflict with them.
//

import Defaults

extension Defaults.Keys {
    // MARK: Pomodoro
    static let pomodoroEnabled = Key<Bool>("pomodoroEnabled", default: true)
    static let pomodoroFocusMinutes = Key<Int>("pomodoroFocusMinutes", default: 25)
    static let pomodoroShortBreakMinutes = Key<Int>("pomodoroShortBreakMinutes", default: 5)
    static let pomodoroLongBreakMinutes = Key<Int>("pomodoroLongBreakMinutes", default: 15)
    static let pomodoroRoundsBeforeLongBreak = Key<Int>("pomodoroRoundsBeforeLongBreak", default: 4)
    static let pomodoroSound = Key<Bool>("pomodoroSound", default: true)
    static let pomodoroShowWhenClosed = Key<Bool>("pomodoroShowWhenClosed", default: true)
}
