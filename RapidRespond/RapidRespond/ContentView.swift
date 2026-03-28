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
 
    // Global alert state — lives here so it works on ANY tab
    @State private var incomingAlertID: String? = nil
    @State private var incomingAlertMessage: String = ""
    @State private var incomingMapsLink: String = ""
    @State private var showIncomingAlert: Bool = false
    @State private var globalListener: ListenerRegistration? = nil
    @State private var listenerStartTime: Date? = nil
 
    // Stable device ID — same across app launches, identifies who sent an SOS
    let deviceID = UIDevice.current.identifierForVendor?.uuidString ?? UUID().uuidString
 
    var body: some View {
        if showOnboarding {
            OnboardingView(showOnboarding: $showOnboarding)
        } else {
            TabView {
                HomeView(deviceID: deviceID)
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
            }
            .accentColor(.red)
            .onAppear {
                startGlobalListener()
            }
            .onDisappear {
                globalListener?.remove()
            }
        }
    }
 
    // Single listener that runs no matter which tab is visible
    func startGlobalListener() {
        let startTime = Date()
        listenerStartTime = startTime
        let db = Firestore.firestore()
 
        globalListener = db.collection("sos_alerts")
            .whereField("status", isEqualTo: "active")
            .addSnapshotListener { snapshot, error in
                guard let snapshot = snapshot else { return }
 
                for change in snapshot.documentChanges {
                    if change.type == .added {
                        let doc = change.document
                        let data = doc.data()
 
                        // Skip stale alerts from before we launched
                        if let ts = data["timestamp"] as? Timestamp {
                            if ts.dateValue() < startTime { continue }
                        }
 
                        // Skip alerts sent by this device
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
 
                    // .removed fires when the doc leaves the "active" query
                    // (i.e. status changed to "resolved" or "cancelled")
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
