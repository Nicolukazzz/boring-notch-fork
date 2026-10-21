//
//  StatsSettingsView.swift
//  boringNotch
//
//  Created by Nicolas on 2026-10-21.
//

import Defaults
import SwiftUI

struct StatsSettingsView: View {
    @Default(.statsEnabled) var statsEnabled

    var body: some View {
        Form {
            Section {
                Defaults.Toggle(key: .statsEnabled) {
                    Text("Enable Stats tab")
                }
                .onChange(of: statsEnabled) {
                    if !statsEnabled {
                        ForkTabs.leaveIfCurrent(.stats)
                    }
                }
            } header: {
                Text("General")
            } footer: {
                Text("Shows CPU, memory, temperature, free disk space and the app using the most CPU. Stats are only measured while the tab is open.")
            }
        }
        .accentColor(.effectiveAccent)
        .navigationTitle("Stats")
    }
}
