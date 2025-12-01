//
//  AuthenticationContainerView.swift
//  simpleApp
//
//  Created by Sinchan Roychowdhury on 11/5/25.
//

import SwiftUI

struct AuthenticationContainerView: View {
    @EnvironmentObject var authService: AuthenticationService
    @Environment(\.dismiss) var dismiss

    @State private var showSignUp = false

    var body: some View {
        Group {
            if showSignUp {
                SignUpView()
                    .environmentObject(authService)
                    .transition(.move(edge: .trailing))
            } else {
                LoginView()
                    .environmentObject(authService)
                    .transition(.move(edge: .leading))
            }
        }
        .onReceive(authService.$isAuthenticated) { isAuth in
            if isAuth {
                dismiss()
            }
        }
    }
}

#Preview {
    AuthenticationContainerView()
        .environmentObject(AuthenticationService.shared)
}
