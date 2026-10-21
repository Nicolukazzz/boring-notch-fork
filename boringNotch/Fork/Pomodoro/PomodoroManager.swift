//
//  PomodoroManager.swift
//  boringNotch
//
//  Created by Nicolas on 2026-10-21.
//

import AppKit
import Combine
import Defaults
import SwiftUI

@MainActor
final class PomodoroManager: ObservableObject {
    static let shared = PomodoroManager()

    enum Phase {
        case focus
        case shortBreak
        case longBreak

        var title: String {
            switch self {
            case .focus: return String(localized: "Focus")
            case .shortBreak: return String(localized: "Break")
            case .longBreak: return String(localized: "Long break")
            }
        }

        var icon: String {
            switch self {
            case .focus: return "brain.head.profile"
            case .shortBreak, .longBreak: return "cup.and.saucer.fill"
            }
        }

        var color: Color {
            switch self {
            case .focus: return Color(red: 1.0, green: 0.42, blue: 0.29)
            case .shortBreak: return Color(red: 0.4, green: 0.824, blue: 0.4)
            case .longBreak: return Color(red: 0.35, green: 0.7, blue: 1.0)
            }
        }
    }

    @Published private(set) var phase: Phase = .focus
    @Published private(set) var isRunning: Bool = false
    @Published private(set) var remaining: TimeInterval = 0
    @Published private(set) var completedRounds: Int = 0

    /// True once the current phase was started at least once; untouched phases follow settings changes.
    private var hasStarted: Bool = false
    private var endDate: Date?
    private var timer: Timer?
    private var cancellables = Set<AnyCancellable>()

    private init() {
        remaining = duration(for: phase)

        Defaults.publisher(keys: .pomodoroFocusMinutes, .pomodoroShortBreakMinutes, .pomodoroLongBreakMinutes, options: [])
            .receive(on: DispatchQueue.main)
            .sink { [weak self] in
                guard let self, !self.hasStarted else { return }
                self.remaining = self.duration(for: self.phase)
            }
            .store(in: &cancellables)
    }

    var roundsBeforeLongBreak: Int {
        max(1, Defaults[.pomodoroRoundsBeforeLongBreak])
    }

    /// Round shown to the user, 1-based, within the current long-break cycle.
    var currentRound: Int {
        if phase == .focus {
            return completedRounds % roundsBeforeLongBreak + 1
        }
        // During a break, show the round that just ended.
        return completedRounds == 0 ? 1 : (completedRounds - 1) % roundsBeforeLongBreak + 1
    }

    var progress: Double {
        let total = duration(for: phase)
        guard total > 0 else { return 0 }
        return min(1, max(0, 1 - remaining / total))
    }

    var formattedRemaining: String {
        let seconds = max(0, Int(remaining.rounded(.up)))
        return String(format: "%02d:%02d", seconds / 60, seconds % 60)
    }

    func duration(for phase: Phase) -> TimeInterval {
        let minutes: Int
        switch phase {
        case .focus: minutes = Defaults[.pomodoroFocusMinutes]
        case .shortBreak: minutes = Defaults[.pomodoroShortBreakMinutes]
        case .longBreak: minutes = Defaults[.pomodoroLongBreakMinutes]
        }
        return TimeInterval(max(1, minutes) * 60)
    }

    // MARK: - Actions

    func toggle() {
        isRunning ? pause() : start()
    }

    func start() {
        guard !isRunning else { return }
        if remaining <= 0 { remaining = duration(for: phase) }
        hasStarted = true
        endDate = Date().addingTimeInterval(remaining)
        isRunning = true
        startTimer()
    }

    func pause() {
        guard isRunning else { return }
        tick()
        isRunning = false
        endDate = nil
        stopTimer()
    }

    func reset() {
        stopTimer()
        isRunning = false
        endDate = nil
        hasStarted = false
        phase = .focus
        completedRounds = 0
        remaining = duration(for: phase)
    }

    func skip() {
        advancePhase(countRound: false)
    }

    // MARK: - Timer

    private func startTimer() {
        stopTimer()
        let timer = Timer(timeInterval: 1, repeats: true) { [weak self] _ in
            Task { @MainActor in self?.tick() }
        }
        RunLoop.main.add(timer, forMode: .common)
        self.timer = timer
    }

    private func stopTimer() {
        timer?.invalidate()
        timer = nil
    }

    private func tick() {
        guard let endDate else { return }
        remaining = max(0, endDate.timeIntervalSinceNow)
        if remaining <= 0 {
            finishPhase()
        }
    }

    private func finishPhase() {
        let finished = phase
        advancePhase(countRound: true)

        if Defaults[.pomodoroSound] {
            NSSound(named: finished == .focus ? "Glass" : "Hero")?.play()
        }
        BoringViewCoordinator.shared.toggleExpandingView(status: true, type: .pomodoro)
    }

    private func advancePhase(countRound: Bool) {
        stopTimer()
        isRunning = false
        endDate = nil
        hasStarted = false

        if phase == .focus {
            if countRound { completedRounds += 1 }
            let roundsDone = countRound ? completedRounds : completedRounds + 1
            phase = roundsDone % roundsBeforeLongBreak == 0 ? .longBreak : .shortBreak
        } else {
            phase = .focus
        }
        remaining = duration(for: phase)
    }
}
