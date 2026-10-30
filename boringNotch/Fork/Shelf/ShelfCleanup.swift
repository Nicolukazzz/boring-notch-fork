//
//  ShelfCleanup.swift
//  boringNotch
//
//  Empties the shelf: a button on the shelf panel, a button in Settings and
//  an optional wipe every time the app launches (e.g. after a restart).
//  Original files are never touched; only the shelf's own temporary copies.
//

import Defaults
import SwiftUI

extension ShelfStateViewModel {
    /// Called once from `init`, right after the saved items are loaded.
    func clearOnLaunchIfNeeded() {
        guard Defaults[.shelfClearOnLaunch], !isEmpty else { return }
        removeAll()
        flushSync()
    }
}

/// Small trash button pinned to the top-right corner of the shelf panel.
struct ShelfClearButton: View {
    @ObservedObject private var shelfState = ShelfStateViewModel.shared
    @State private var isHovering = false

    var body: some View {
        if !shelfState.isEmpty {
            Button {
                ShelfSelectionModel.shared.clear()
                withAnimation(.smooth(duration: 0.3)) {
                    shelfState.removeAll()
                }
            } label: {
                Image(systemName: "trash")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(isHovering ? .white : .gray)
                    .frame(width: 24, height: 24)
                    .background(Circle().fill(Color.black.opacity(isHovering ? 0.9 : 0.6)))
                    .overlay(Circle().stroke(Color.white.opacity(0.1), lineWidth: 1))
                    .contentShape(Circle())
            }
            .buttonStyle(PlainButtonStyle())
            .help("Clear shelf")
            .onHover { hovering in
                withAnimation(.smooth(duration: 0.2)) {
                    isHovering = hovering
                }
            }
            .padding(6)
            .transition(.opacity)
        }
    }
}

/// Extra rows for the Shelf settings page.
struct ShelfCleanupSettingsSection: View {
    @ObservedObject private var shelfState = ShelfStateViewModel.shared

    var body: some View {
        Section {
            Defaults.Toggle(key: .shelfClearOnLaunch) {
                Text("Clear shelf when the app starts")
            }
            HStack {
                Text(shelfState.isEmpty ? "The shelf is empty" : "\(shelfState.items.count) item(s) on the shelf")
                    .foregroundStyle(.secondary)
                Spacer()
                Button("Clear shelf now") {
                    shelfState.removeAll()
                }
                .disabled(shelfState.isEmpty)
            }
        } header: {
            Text("Cleanup")
        } footer: {
            Text("Only removes items from the shelf. Your original files stay where they are.")
        }
    }
}
