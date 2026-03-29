//
//  ContentView.swift
//  device-location-ios
//
//  Created by Kilo Loco on 12/7/21.
//

import SwiftUI
import FirebaseFirestore
 
struct ContentView: View {
    @State private var showOnboarding = !UserDefaults.standard.bool(forKey: "onboardingComplete")
 
    @AppStorage("carriesNarcan") private var carriesNarcan = false
    @AppStorage("carriesEpiPen") private var carriesEpiPen = false
 
    // Global incoming alert state
    @State private var incomingAlertID: String? = nil
    @State private var incomingAlertMessage: String = ""
    @State private var incomingMapsLink: String = ""
    @State private var showIncomingAlert: Bool = false
    @State private var globalListener: ListenerRegistration? = nil
 
    // Responder popup — lives here so it overlays ALL tabs
    @State private var responderCount: Int = 0
    @State private var showResponderPopup: Bool = false
 
    let deviceID = UIDevice.current.identifierForVendor?.uuidString ?? UUID().uuidString
 
    var body: some View {
        if showOnboarding {
            OnboardingView(showOnboarding: $showOnboarding)
        } else {
            ZStack {
                TabView {
                    HomeView(
                        deviceID: deviceID,
                        responderCount: $responderCount,
                        showResponderPopup: $showResponderPopup
                    )
                    .tabItem {
                        Label("SOS", systemImage: "sos.circle.fill")
                    }
 
                    AlertView(
                        carriesNarcan: carriesNarcan,
                        carriesEpiPen: carriesEpiPen,
                        showIncomingAlert: $showIncomingAlert,
                        incomingAlertMessage: $incomingAlertMessage,
                        incomingMapsLink: $incomingMapsLink,
                        incomingAlertID: $incomingAlertID
                    )
                    .tabItem {
                        Label("Alerts", systemImage: "bell.fill")
                    }
 
                    ProfileView()
                    .tabItem {
                        Label("Profile", systemImage: "person.fill")
                    }
                }
                .accentColor(.red)
 
                // Incoming alert banner — overlays ALL tabs, same style as responder popup
                if showIncomingAlert {
                    VStack {
                        Spacer()
                        HStack(spacing: 12) {
                            Text("⚠️")
                                .font(.system(size: 28))
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Someone nearby needs help!")
                                    .font(.system(size: 16, weight: .bold))
                                    .foregroundColor(.white)
                                Text(incomingAlertMessage)
                                    .font(.system(size: 13))
                                    .foregroundColor(.gray)
                                    .lineLimit(1)
                            }
                            Spacer()
                            Text("→ Alerts")
                                .font(.system(size: 12, weight: .semibold))
                                .foregroundColor(.red)
                        }
                        .padding()
                        .background(Color(white: 0.12))
                        .cornerRadius(16)
                        .padding(.horizontal)
                        .padding(.bottom, 90)
                    }
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                    .animation(.spring(), value: showIncomingAlert)
                    .allowsHitTesting(false)
                }
 
                // Responder popup overlays ALL tabs
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
                        .padding(.bottom, 90) // sit above tab bar
                    }
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                    .animation(.spring(), value: showResponderPopup)
                    .allowsHitTesting(false) // don't block taps on tabs below
                }
            }
            .onAppear {
                startGlobalListener()
            }
            .onDisappear {
                globalListener?.remove()
            }
        }
    }
 
    func startGlobalListener() {
        let startTime = Date()
        let db = Firestore.firestore()
 
        globalListener = db.collection("sos_alerts")
            .whereField("status", isEqualTo: "active")
            .addSnapshotListener { snapshot, error in
                guard let snapshot = snapshot else { return }
 
                for change in snapshot.documentChanges {
                    if change.type == .added {
                        let doc = change.document
                        let data = doc.data()
 
                        // Skip stale alerts
                        if let ts = data["timestamp"] as? Timestamp {
                            if ts.dateValue() < startTime { continue }
                        }
 
                        // Skip our own SOS
                        let senderID = data["senderID"] as? String ?? ""
                        if senderID == deviceID { continue }
 
                        let resourceNeeded = data["resourceNeeded"] as? String ?? ""
                        let lat = data["latitude"] as? Double ?? 0.0
                        let lng = data["longitude"] as? Double ?? 0.0
 
                        let shouldAlert = (resourceNeeded == "narcan" && carriesNarcan) ||
                                          (resourceNeeded == "epipen" && carriesEpiPen)
 
                        if shouldAlert {
                            incomingAlertID = doc.documentID
                            incomingAlertMessage = "Someone nearby needs \(resourceNeeded.capitalized)!"
                            incomingMapsLink = "https://maps.google.com/?q=\(lat),\(lng)"
                            showIncomingAlert = true
                        }
                    }
 
                    if change.type == .removed {
                        if change.document.documentID == incomingAlertID {
                            showIncomingAlert = false
                            incomingAlertID = nil
                            incomingAlertMessage = ""
                            incomingMapsLink = ""
                        }
                    }
                }
            }
    }
}
