//
//  AuthWrapperView.swift
//  OurPlace
//
//  Created by Chaniru Sandive on 2025-08-06.
//

import SwiftUI

enum AuthScreen {
    case login
    case signup
}

struct AuthWrapperView: View {
    @EnvironmentObject var authVM: AuthViewModel
    @State private var currentAuthScreen: AuthScreen = .login
    
    var body: some View {
        Group {
            if authVM.user != nil {
                MainTabView()
            } else {
                NavigationStack {
                    switch currentAuthScreen {
                    case .login:
                        LoginView(currentAuthScreen: $currentAuthScreen)
                    case .signup:
                        SignupView(currentAuthScreen: $currentAuthScreen)
                    }
                }
            }
        }
    }
}

#Preview {
    AuthWrapperView()
        .environmentObject(AuthViewModel())
} 