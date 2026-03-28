//
//  ContentView.swift
//  device-location-ios
//
//  Created by Kilo Loco on 12/7/21.
//

import SwiftUI

struct ContentView: View {
    @State private var showOnboarding = !UserDefaults.standard.bool(forKey: "onboardingComplete")

    var body: some View {
        if showOnboarding {
            OnboardingView(showOnboarding: $showOnboarding)
        } else {
            TabView {
                HomeView()
                    .tabItem {
                        Label("SOS", systemImage: "sos.circle.fill")
                    }

                AlertView(
                    carriesNarcan: UserDefaults.standard.bool(forKey: "carriesNarcan"),
                    carriesEpiPen: UserDefaults.standard.bool(forKey: "carriesEpiPen")
                )
                .tabItem {
                    Label("Alerts", systemImage: "bell.fill")
                }
            }
            .accentColor(.red)
        }
    }
}
