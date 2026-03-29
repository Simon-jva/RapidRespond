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
 
    // Passed in from ContentView so popup shows on all tabs
    @Binding var responderCount: Int
    @Binding var showResponderPopup: Bool
 
    // Persist SOS state across app restarts
    @AppStorage("activeSosID") private var activeSosID: String = ""
    @AppStorage("sosActivated") private var sosActivated: Bool = false
 
    @State private var showResourcePicker = false
    @State private var sosListener: ListenerRegistration? = nil
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
            }
            .padding(.vertical, 60)
        }
        .confirmationDialog("What do you need?", isPresented: $showResourcePicker, titleVisibility: .visible) {
            Button("Narcan") { sendSOS(resourceNeeded: "narcan") }
            Button("EpiPen") { sendSOS(resourceNeeded: "epipen") }
            Button("Cancel", role: .cancel) {}
        }
        .onAppear {
            // If app was closed while SOS was active, re-attach the listener
            if sosActivated && !activeSosID.isEmpty && sosListener == nil {
                listenForResponders(sosID: activeSosID)
            }
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
            "senderID": deviceID
        ]
 
        let docRef = db.collection("sos_alerts").addDocument(data: sosData) { error in
            if let error = error {
                print("Error sending SOS: \(error)")
                sosActivated = false
                activeSosID = ""
            }
        }
 
        // Persist the doc ID so we can restore after app restart
        activeSosID = docRef.documentID
        listenForResponders(sosID: docRef.documentID)
    }
 
    func listenForResponders(sosID: String) {
        let db = Firestore.firestore()
 
        sosListener = db.collection("sos_alerts").document(sosID)
            .addSnapshotListener { snapshot, error in
                guard let data = snapshot?.data() else { return }
 
                // If resolved externally (e.g. edge case), clean up
                let status = data["status"] as? String ?? "active"
                if status != "active" {
                    sosActivated = false
                    activeSosID = ""
                    responderCount = 0
                    sosListener?.remove()
                    sosListener = nil
                    return
                }
 
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
 
    func resolveSOS() {
        sosListener?.remove()
        sosListener = nil
 
        let id = activeSosID
        guard !id.isEmpty else {
            sosActivated = false
            activeSosID = ""
            return
        }
 
        let db = Firestore.firestore()
        db.collection("sos_alerts").document(id).updateData(["status": "resolved"]) { _ in
            sosActivated = false
            activeSosID = ""
            responderCount = 0
            withAnimation { showResponderPopup = false }
        }
    }
}
 
