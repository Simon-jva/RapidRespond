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
 
    // Shared state from ContentView — same data shown on both tabs
    @Binding var showIncomingAlert: Bool
    @Binding var incomingAlertMessage: String
    @Binding var incomingMapsLink: String
    @Binding var incomingAlertID: String?
 
    @State private var hasResponded = false
 
    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
 
            VStack(spacing: 30) {
                if showIncomingAlert {
                    VStack(spacing: 20) {
                        Text("⚠️ Someone Needs Help!")
                            .font(.system(size: 24, weight: .black))
                            .foregroundColor(.red)
 
                        Text(incomingAlertMessage)
                            .font(.system(size: 18))
                            .foregroundColor(.white)
                            .multilineTextAlignment(.center)
 
                        // Map link always stays visible
                        if !incomingMapsLink.isEmpty {
                            Link("📍 Open in Google Maps", destination: URL(string: incomingMapsLink)!)
                                .font(.system(size: 16, weight: .bold))
                                .foregroundColor(.white)
                                .padding()
                                .background(Color.red)
                                .cornerRadius(12)
                        }
 
                        // Button changes to confirmation after tapping — card stays up
                        if !hasResponded {
                            Button("I'm on my way") {
                                markResponding()
                            }
                            .font(.system(size: 16, weight: .bold))
                            .foregroundColor(.black)
                            .padding()
                            .background(Color.white)
                            .cornerRadius(12)
                        } else {
                            Text("✅ You're on your way")
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(.green)
                        }
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
        // Reset responded state when alert clears
        .onChange(of: showIncomingAlert) { visible in
            if !visible { hasResponded = false }
        }
    }
 
    func markResponding() {
        guard let alertID = incomingAlertID else { return }
        hasResponded = true
        let db = Firestore.firestore()
        db.collection("sos_alerts").document(alertID).updateData([
            "responderCount": FieldValue.increment(Int64(1))
        ]) { error in
            if let error = error {
                print("Error marking responding: \(error)")
            }
        }
        // Card stays up — map link remains visible
    }
}
 
