//
//  RapidRespondApp.swift
//  RapidRespond
//
//  Created by simon roeser on 3/28/26.
//
import SwiftUI
import Firebase

@main
struct RapidRespondApp: App {
    
    init() {
        FirebaseApp.configure()
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}
