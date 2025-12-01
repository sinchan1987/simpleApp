//
//  simpleAppApp.swift
//  simpleApp
//
//  Created by Sinchan Roychowdhury on 11/5/25.
//

import SwiftUI
import Firebase

@main
struct simpleAppApp: App {
    init() {
        print("🚀 App: Configuring Firebase...")
        FirebaseApp.configure()
        print("✅ App: Firebase configured successfully")

        if let app = FirebaseApp.app() {
            print("📱 App: Firebase app name: \(app.name)")
            print("📱 App: Firebase project ID: \(app.options.projectID ?? "unknown")")
        }
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}
