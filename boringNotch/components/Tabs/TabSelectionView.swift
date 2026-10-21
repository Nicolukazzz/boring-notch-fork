//
//  TabSelectionView.swift
//  boringNotch
//
//  Created by Hugo Persson on 2024-08-25.
//

import SwiftUI

struct TabModel: Identifiable {
    let id = UUID()
    let label: String
    let icon: String
    let view: NotchViews
}

let tabs = [
    TabModel(label: "Home", icon: "house.fill", view: .home),
    TabModel(label: "Shelf", icon: "tray.fill", view: .shelf)
]

struct TabSelectionView: View {
    @ObservedObject var coordinator = BoringViewCoordinator.shared
    @Namespace var animation
    var body: some View {
        // fork: pill-style tab bar; the selected capsule slides between tabs.
        HStack(spacing: 2) {
            ForEach(tabs) { tab in
                let isSelected = coordinator.currentView == tab.view
                TabButton(label: tab.label, icon: tab.icon, selected: isSelected) {
                    withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                        coordinator.currentView = tab.view
                    }
                }
                .background {
                    if isSelected {
                        Capsule()
                            .fill(Color(nsColor: .secondarySystemFill))
                            .matchedGeometryEffect(id: "capsule", in: animation)
                    }
                }
            }
        }
        .padding(2)
        .background(Capsule().fill(Color.white.opacity(0.04)))
    }
}

#Preview {
    BoringHeader().environmentObject(BoringViewModel(camera: CameraModel()))
}
