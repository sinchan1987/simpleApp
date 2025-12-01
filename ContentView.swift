//
//  ContentView.swift
//  simpleApp
//
//  Created by Sinchan Roychowdhury on 11/5/25.
//

import SwiftUI

struct ContentView: View {
    @StateObject private var authService = AuthenticationService.shared

    var body: some View {
        WelcomeView()
            .environmentObject(authService)
    }
}

#Preview {
    ContentView()
        .environmentObject(AuthenticationService.shared)
}

