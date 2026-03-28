//
//  HomeView.swift
//  RapidRespond
//
//  Created by simon roeser on 3/28/26.
//

import SwiftUI
import Firebase
import FirebaseFirestore
import CoreLocation

struct HomeView: View {
    @State private var sosActivated = false
    @State private var carriesNarcan = UserDefaults.standard.bool(forKey: "carriesNarcan")
    @State private var carriesEpiPen = UserDefaults.standard.bool(forKey: "carriesEpiPen")
    @State private var showResourcePicker = false
    @StateObject private var locationManager = LocationManager()

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            VStack(spacing: 40) {
                Text("RapidRespond")
                    .font(.system(size: 28, weight: .bold))
                    .foregroundColor(.white)

                Spacer()

                Button(action: {
                    showResourcePicker = true
                }) {
                    ZStack {
                        Circle()
                            .fill(Color.red)
                            .frame(width: 220, height: 220)
                            .shadow(color: .red.opacity(0.6), radius: sosActivated ? 40 : 20)

                        Text("SOS")
                            .font(.system(size: 60, weight: .black))
                            .foregroundColor(.white)
                    }
                }
                .scaleEffect(sosActivated ? 0.95 : 1.0)
                .animation(.easeInOut(duration: 0.1), value: sosActivated)

                if sosActivated {
                    Text("Alerting nearby responders...")
                        .foregroundColor(.red0)
                        .font(.system(size: 16, weight: .semibold))
                        .transition(.opacity)
                }

                Spacer()

                VStack(alignment: .leading, spacing: 16) {
                    Text("I'm carrying:")
                        .foregroundColor(.gray)
                        .font(.system(size: 14, weight: .medium))

                    Toggle("Narcan", isOn: $carriesNarcan)
                        .foregroundColor(.white)
                        .tint(.red)
                        .onChange(of: carriesNarcan) { val in
                            UserDefaults.standard.set(val, forKey: "carriesNarcan")
                        }

                    Toggle("EpiPen", isOn: $carriesEpiPen)
                        .foregroundColor(.white)
                        .tint(.red)
                        .onChange(of: carriesEpiPen) { val in
                            UserDefaults.standard.set(val, forKey: "carriesEpiPen")
                        }
                }
                .padding()
                .background(Color.white.opacity(0.05))
                .cornerRadius(16)
                .padding(.horizontal)
            }
            .padding(.vertical, 60)
        }
        // Resource picker popup
        .confirmationDialog("What do you need?", isPresented: $showResourcePicker, titleVisibility: .visible) {
            Button("Narcan") {
                sendSOS(resourceNeeded: "narcan")
            }
            Button("EpiPen") {
                sendSOS(resourceNeeded: "epipen")
            }
            Button("Cancel", role: .cancel) {}
        }
        .alert("SOS Sent!", isPresented: $sosActivated) {
            Button("Cancel SOS", role: .destructive) {
                sosActivated = false
            }
        } message: {
            Text("Alerting nearby users with the right resource.")
        }
    }

    func sendSOS(resourceNeeded: String) {
        sosActivated = true
        let db = Firestore.firestore()

        let lat = locationManager.lastLocation?.coordinate.latitude ?? 0.0
        let lng = locationManager.lastLocation?.coordinate.longitude ?? 0.0

        let sosData: [String: Any] = [
            "timestamp": FieldValue.serverTimestamp(),
            "latitude": lat,
            "longitude": lng,
            "resourceNeeded": resourceNeeded,
            "status": "active"
        ]

        db.collection("sos_alerts").addDocument(data: sosData) { error in
            if let error = error {
                print("Error sending SOS: \(error)")
            } else {
                print("SOS sent! Resource: \(resourceNeeded) at \(lat), \(lng)")
            }
        }
    }
}
