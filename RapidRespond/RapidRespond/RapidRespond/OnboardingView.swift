//
//  OnboardingView.swift
//  RapidRespond
//
//  Created by simon roeser on 3/28/26.
//

import SwiftUI

struct OnboardingView: View {
    @Binding var showOnboarding: Bool
    @State private var carriesNarcan = false
    @State private var carriesEpiPen = false

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            VStack(spacing: 32) {
                Spacer()

                Text("RapidRespond")
                    .font(.system(size: 36, weight: .black))
                    .foregroundColor(.white)

                Text("Save lives in seconds.\nNo 911 call required.")
                    .font(.system(size: 18))
                    .foregroundColor(.gray)
                    .multilineTextAlignment(.center)

                Spacer()

                VStack(alignment: .leading, spacing: 20) {
                    Text("What do you carry?")
                        .font(.system(size: 20, weight: .bold))
                        .foregroundColor(.white)

                    Toggle("Narcan (Naloxone)", isOn: $carriesNarcan)
                        .foregroundColor(.white)
                        .tint(.red)

                    Toggle("EpiPen", isOn: $carriesEpiPen)
                        .foregroundColor(.white)
                        .tint(.red)
                }
                .padding()
                .background(Color.white.opacity(0.05))
                .cornerRadius(16)
                .padding(.horizontal)

                Spacer()

                Button(action: {
                    UserDefaults.standard.set(carriesNarcan, forKey: "carriesNarcan")
                    UserDefaults.standard.set(carriesEpiPen, forKey: "carriesEpiPen")
                    UserDefaults.standard.set(true, forKey: "onboardingComplete")
                    showOnboarding = false
                }) {
                    Text("Get Started")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.red)
                        .cornerRadius(14)
                        .padding(.horizontal)
                }
            }
            .padding(.vertical, 60)
        }
    }
}
