//
//  TabButton.swift
//  boringNotch
//
//  Created by Hugo Persson on 2024-08-24.
//

import SwiftUI

struct TabButton: View {
    let label: String
    let icon: String
    let selected: Bool
    let onClick: () -> Void

    @State private var isHovering = false

    var body: some View {
        Button(action: onClick) {
            HStack(spacing: 6) {
                Image(systemName: icon)
                if selected {
                    Text(label)
                        .font(.system(size: 12, weight: .semibold, design: .rounded))
                        .lineLimit(1)
                        .fixedSize()
                        .transition(.opacity.combined(with: .move(edge: .leading)))
                }
            }
            .padding(.horizontal, selected ? 12 : 8)
            .frame(minWidth: 32, minHeight: 28)
            // Whole pill is clickable, not only the glyph.
            .contentShape(Capsule())
        }
        .buttonStyle(PlainButtonStyle())
        .foregroundStyle(selected ? .white : (isHovering ? Color.white.opacity(0.85) : .gray))
        .onHover { hovering in
            withAnimation(.smooth(duration: 0.2)) {
                isHovering = hovering
            }
        }
    }
}

#Preview {
    TabButton(label: "Home", icon: "tray.fill", selected: true) {
        Log.general.debug("Tapped")
    }
}
