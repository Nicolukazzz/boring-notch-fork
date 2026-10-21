//
//  PomodoroLiveActivity.swift
//  boringNotch
//
//  Created by Nicolas on 2026-10-21.
//

import SwiftUI

/// Closed-notch activity: progress ring on the left, a pulsing phase dot on the right.
/// When a phase ends, it widens briefly to announce the next one.
struct PomodoroLiveActivity: View {
    @EnvironmentObject var vm: BoringViewModel
    @ObservedObject var coordinator = BoringViewCoordinator.shared
    @ObservedObject var pomodoro = PomodoroManager.shared

    private var isAnnouncing: Bool {
        coordinator.expandingView.show && coordinator.expandingView.type == .pomodoro
    }

    private var sideSize: CGFloat {
        max(0, vm.effectiveClosedNotchHeight - 12)
    }

    private var announcement: String {
        pomodoro.phase == .focus ? String(localized: "Time to focus!") : String(localized: "Take a break!")
    }

    var body: some View {
        HStack {
            PomodoroRing(progress: isAnnouncing ? 1 : pomodoro.progress, color: pomodoro.phase.color, lineWidth: 2.5)
                .padding(2)
                .frame(width: sideSize, height: sideSize)

            Rectangle()
                .fill(.black)
                .overlay {
                    if isAnnouncing {
                        HStack {
                            Text(announcement)
                                .font(.subheadline)
                                .fontWeight(.semibold)
                                .foregroundStyle(pomodoro.phase.color)
                                .lineLimit(1)
                            Spacer(minLength: vm.closedNotchSize.width)
                            Image(systemName: pomodoro.phase.icon)
                                .foregroundStyle(pomodoro.phase.color)
                        }
                        .transition(.opacity)
                    }
                }
                .frame(width: isAnnouncing ? 380 : vm.closedNotchSize.width - cornerRadiusInsets.closed.top)

            Image(systemName: "circle.fill")
                .font(.system(size: 6))
                .foregroundStyle(pomodoro.phase.color)
                .symbolEffect(.pulse, isActive: pomodoro.isRunning && !isAnnouncing)
                .opacity(isAnnouncing ? 0 : 1)
                .frame(width: sideSize, height: sideSize)
        }
        .frame(height: vm.effectiveClosedNotchHeight, alignment: .center)
        .animation(.smooth, value: isAnnouncing)
    }
}
