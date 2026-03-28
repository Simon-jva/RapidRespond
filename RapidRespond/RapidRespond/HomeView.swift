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
    let deviceID: String
 
    @State private var sosActivated = false
    @State private var activeSosID: String? = nil
    @State private var showResourcePicker = false
    @State private var responderCount = 0
    @State private var showResponderPopup = false
    @State private var sosListener: ListenerRegistration? = nil
 
    @StateObject private var locationManager = LocationManager()
    @AppStorage("carriesNarcan") private var carriesNarcan = false
    @AppStorage("carriesEpiPen") private var carriesEpiPen = false
 
    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
 
            VStack(spacing: 40) {
                Text("RapidRespond")
                    .font(.system(size: 28, weight: .bold))
                    .foregroundColor(.white)
 
                Spacer()
 
                Button(action: {
                    if sosActivated {
                        resolveSOS()
                    } else {
                        showResourcePicker = true
                    }
                }) {
                    ZStack {
                        Circle()
                            .fill(sosActivated ? Color.green : Color.red)
                            .frame(width: 220, height: 220)
                            .shadow(
                                color: (sosActivated ? Color.green : Color.red).opacity(0.6),
                                radius: sosActivated ? 40 : 20
                            )
 
                        VStack(spacing: 4) {
                            Text(sosActivated ? "✅" : "SOS")
                                .font(.system(size: sosActivated ? 48 : 60, weight: .black))
                                .foregroundColor(.white)
                            if sosActivated {
                                Text("RESOLVED")
                                    .font(.system(size: 16, weight: .bold))
                                    .foregroundColor(.white)
                            }
                        }
                    }
                }
                .scaleEffect(sosActivated ? 0.95 : 1.0)
                .animation(.easeInOut(duration: 0.1), value: sosActivated)
 
                if sosActivated {
                    Text("Alerting nearby responders...")
                        .foregroundColor(.red)
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
 
                    Toggle("EpiPen", isOn: $carriesEpiPen)
                        .foregroundColor(.white)
                        .tint(.red)
                }
                .padding()
                .background(Color.white.opacity(0.05))
                .cornerRadius(16)
                .padding(.horizontal)
            }
            .padding(.vertical, 60)
 
            // "Help is on the way" popup
            if showResponderPopup {
                VStack {
                    Spacer()
                    HStack(spacing: 12) {
                        Text("🚀")
                            .font(.system(size: 28))
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Help is on the way!")
                                .font(.system(size: 16, weight: .bold))
                                .foregroundColor(.white)
                            Text("\(responderCount) responder\(responderCount == 1 ? "" : "s") responded")
                                .font(.system(size: 13))
                                .foregroundColor(.gray)
                        }
                        Spacer()
                    }
                    .padding()
                    .background(Color(white: 0.12))
                    .cornerRadius(16)
                    .padding(.horizontal)
                    .padding(.bottom, 30)
                }
                .transition(.move(edge: .bottom).combined(with: .opacity))
                .animation(.spring(), value: showResponderPopup)
            }
 
 
        }
        .confirmationDialog("What do you need?", isPresented: $showResourcePicker, titleVisibility: .visible) {
            Button("Narcan") { sendSOS(resourceNeeded: "narcan") }
            Button("EpiPen") { sendSOS(resourceNeeded: "epipen") }
            Button("Cancel", role: .cancel) {}
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
            "status": "active",
            "responderCount": 0,
            "senderID": deviceID  // stored so responders don't get their own alert
        ]
 
        let docRef = db.collection("sos_alerts").addDocument(data: sosData) { error in
            if let error = error {
                print("Error sending SOS: \(error)")
                sosActivated = false
            }
        }
 
        listenForResponders(sosID: docRef.documentID)
    }
 
    func listenForResponders(sosID: String) {
        activeSosID = sosID
        let db = Firestore.firestore()
 
        sosListener = db.collection("sos_alerts").document(sosID)
            .addSnapshotListener { snapshot, error in
                guard let data = snapshot?.data() else { return }
                let count = data["responderCount"] as? Int ?? 0
                if count > responderCount && count > 0 {
                    responderCount = count
                    withAnimation { showResponderPopup = true }
                    DispatchQueue.main.asyncAfter(deadline: .now() + 5) {
                        withAnimation { showResponderPopup = false }
                    }
                }
            }
    }
 
    // Only the SOS sender can call this — marks resolved for everyone
    func resolveSOS() {
        sosListener?.remove()
        sosListener = nil
 
        guard let id = activeSosID else {
            sosActivated = false
            return
        }
 
        let db = Firestore.firestore()
        db.collection("sos_alerts").document(id).updateData(["status": "resolved"]) { _ in
            sosActivated = false
            activeSosID = nil
            responderCount = 0
            showResponderPopup = false
        }
    }
 
}
