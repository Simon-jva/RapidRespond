//
//  Profileview.swift
//  RapidRespond
//
//  Created by simon roeser on 3/28/26.
//

import SwiftUI
 
struct ProfileView: View {
    @AppStorage("carriesNarcan") private var carriesNarcan = false
    @AppStorage("carriesEpiPen") private var carriesEpiPen = false
 
    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
 
            VStack(spacing: 32) {
                Text("RapidRespond")
                    .font(.system(size: 28, weight: .bold))
                    .foregroundColor(.white)
 
                Text("What do you carry?")
                    .font(.system(size: 22, weight: .semibold))
                    .foregroundColor(.white)
 
                Text("You'll only be alerted for emergencies\nthat match what you're carrying.")
                    .font(.system(size: 15))
                    .foregroundColor(.gray)
                    .multilineTextAlignment(.center)
 
                VStack(spacing: 0) {
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Narcan (Naloxone)")
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(.white)
                            Text("For opioid overdoses")
                                .font(.system(size: 13))
                                .foregroundColor(.gray)
                        }
                        Spacer()
                        Toggle("", isOn: $carriesNarcan)
                            .tint(.red)
                            .labelsHidden()
                    }
                    .padding()
 
                    Divider().background(Color.white.opacity(0.1))
 
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("EpiPen")
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(.white)
                            Text("For severe allergic reactions")
                                .font(.system(size: 13))
                                .foregroundColor(.gray)
                        }
                        Spacer()
                        Toggle("", isOn: $carriesEpiPen)
                            .tint(.red)
                            .labelsHidden()
                    }
                    .padding()
                }
                .background(Color.white.opacity(0.05))
                .cornerRadius(16)
                .padding(.horizontal)
 
                Spacer()
            }
            .padding(.top, 60)
        }
    }
}
 
