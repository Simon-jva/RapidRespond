//
//  AlertView.swift
//  RapidRespond
//
//  Created by simon roeser on 3/28/26.
//

import SwiftUI
import FirebaseFirestore

struct AlertView: View {
    let carriesNarcan: Bool
    let carriesEpiPen: Bool
    @State private var alertMessage: String = ""
    @State private var mapsLink: String = ""
    @State private var showAlert = false
    @State private var listener: ListenerRegistration?

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            VStack(spacing: 30) {
                if showAlert {
                    VStack(spacing: 20) {
                        Text("⚠️ Someone Needs Help!")
                            .font(.system(size: 24, weight: .black))
                            .foregroundColor(.red)

                        Text(alertMessage)
                            .font(.system(size: 18))
                            .foregroundColor(.white)
                            .multilineTextAlignment(.center)

                        if !mapsLink.isEmpty {
                            Link("📍 Open in Google Maps", destination: URL(string: mapsLink)!)
                                .font(.system(size: 16, weight: .bold))
                                .foregroundColor(.white)
                                .padding()
                                .background(Color.red)
                                .cornerRadius(12)
                        }

                        Button("I'm on my way") {
                            showAlert = false
                        }
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(.black)
                        .padding()
                        .background(Color.white)
                        .cornerRadius(12)
                    }
                    .padding()
                    .background(Color.white.opacity(0.05))
                    .cornerRadius(20)
                    .padding()
                } else {
                    VStack(spacing: 16) {
                        Text("RapidRespond")
                            .font(.system(size: 28, weight: .bold))
                            .foregroundColor(.white)

                        Text("Listening for nearby alerts...")
                            .foregroundColor(.gray)
                            .font(.system(size: 16))

                        Circle()
                            .stroke(Color.red.opacity(0.5), lineWidth: 2)
                            .frame(width: 100, height: 100)
                            .overlay(
                                Circle()
                                    .fill(Color.red.opacity(0.2))
                                    .frame(width: 80, height: 80)
                            )
                    }
                }
            }
        }
        .onAppear {
            startListening()
        }
        .onDisappear {
            listener?.remove()
        }
    }

    func startListening() {
        let db = Firestore.firestore()

        listener = db.collection("sos_alerts")
            .whereField("status", isEqualTo: "active")
            .addSnapshotListener { snapshot, error in
                guard let snapshot = snapshot else { return }

                for change in snapshot.documentChanges {
                    if change.type == .added {
                        let data = change.document.data()
                        let resourceNeeded = data["resourceNeeded"] as? String ?? ""
                        let lat = data["latitude"] as? Double ?? 0.0
                        let lng = data["longitude"] as? Double ?? 0.0

                        // Only show alert if user carries the needed resource
                        let shouldAlert = (resourceNeeded == "narcan" && carriesNarcan) ||
                                         (resourceNeeded == "epipen" && carriesEpiPen)

                        if shouldAlert {
                            alertMessage = "Someone nearby needs \(resourceNeeded.capitalized)!"
                            mapsLink = "https://maps.google.com/?q=\(lat),\(lng)"
                            showAlert = true
                        }
                    }
                }
            }
    }
}
