//
//  PomodoroView.swift
//  boringNotch
//
//  Created by Nicolas on 2026-10-21.
//

import SwiftUI

struct PomodoroRing: View {
    var progress: Double
    var color: Color
    var lineWidth: CGFloat

    var body: some View {
        ZStack {
            Circle()
                .stroke(Color.white.opacity(0.1), lineWidth: lineWidth)
            Circle()
                .trim(from: 0, to: progress)
                .stroke(color.gradient, style: StrokeStyle(lineWidth: lineWidth, lineCap: .round))
                .rotationEffect(.degrees(-90))
                .animation(.smooth(duration: 0.6), value: progress)
        }
    }
}

struct PomodoroView: View {
    @EnvironmentObject var vm: BoringViewModel
    @ObservedObject var pomodoro = PomodoroManager.shared

    var body: some View {
        HStack(alignment: .center, spacing: 24) {
            timerDial
                .frame(width: 110, height: 110)
            controls
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
        .transition(.asymmetric(insertion: .opacity.combined(with: .move(edge: .top)), removal: .opacity))
        .blur(radius: vm.notchState == .closed ? 30 : 0)
    }

    private var timerDial: some View {
        ZStack {
            PomodoroRing(progress: pomodoro.progress, color: pomodoro.phase.color, lineWidth: 8)
                .padding(4)
                .shadow(color: pomodoro.phase.color.opacity(pomodoro.isRunning ? 0.35 : 0), radius: 10)

            Text(pomodoro.formattedRemaining)
                .font(.system(size: 22, weight: .semibold, design: .rounded))
                .monospacedDigit()
                .foregroundStyle(.white)
                .contentTransition(.numericText(countsDown: true))
                .animation(.smooth, value: pomodoro.formattedRemaining)
        }
        .aspectRatio(1, contentMode: .fit)
        .animation(.smooth, value: pomodoro.phase)
    }

    private var controls: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 6) {
                Image(systemName: pomodoro.phase.icon)
                    .foregroundStyle(pomodoro.phase.color)
                    .contentTransition(.symbolEffect(.replace))
                Text(pomodoro.phase.title)
                    .font(.headline)
                    .foregroundStyle(.white)
                    .contentTransition(.opacity)
            }

            HStack(spacing: 8) {
                Text("Round \(pomodoro.currentRound) of \(pomodoro.roundsBeforeLongBreak)")
                    .font(.headline)
                    .fontWeight(.medium)
                    .foregroundStyle(.gray)
                roundDots
            }

            HStack(spacing: 10) {
                HoverButton(icon: "arrow.counterclockwise", iconColor: .gray) {
                    withAnimation(.smooth) { pomodoro.reset() }
                }
                HoverButton(icon: pomodoro.isRunning ? "pause.fill" : "play.fill", scale: .large) {
                    withAnimation(.smooth) { pomodoro.toggle() }
                }
                HoverButton(icon: "forward.fill", iconColor: .gray) {
                    withAnimation(.smooth) { pomodoro.skip() }
                }
            }
        }
        .fixedSize()
    }

    private var roundDots: some View {
        let total = pomodoro.roundsBeforeLongBreak
        let filled = pomodoro.phase == .longBreak ? total : pomodoro.completedRounds % total
        return HStack(spacing: 4) {
            ForEach(0..<total, id: \.self) { index in
                Circle()
                    .fill(index < filled ? PomodoroManager.Phase.focus.color : Color.white.opacity(0.15))
                    .frame(width: 6, height: 6)
            }
        }
        .animation(.smooth, value: filled)
    }
}
