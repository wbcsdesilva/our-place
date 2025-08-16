//
//  LoginView.swift
//  OurPlace
//
//  Created by Chaniru Sandive on 2025-08-06.
//

import SwiftUI

struct LoginView: View {
    @EnvironmentObject var authVM: AuthViewModel
    @Binding var currentAuthScreen: AuthScreen
    @State private var email = ""
    @State private var password = ""
    @State private var showForgotPassword = false
    
    private var isFormValid: Bool {
        !email.isEmpty && !password.isEmpty
    }
    
    var body: some View {
        VStack(spacing: 0) {
            VStack(spacing: 20) {
                Text("Welcome Back")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .padding(.top, 50)
                
                FormSectionView(spacing: 15) {
                    CustomTextField(
                        placeholder: "Email",
                        text: $email,
                        keyboardType: .emailAddress,
                        autocapitalization: .none,
                        icon: "at"
                    )
                    
                    CustomTextField(
                        placeholder: "Password",
                        text: $password,
                        isSecure: true,
                        icon: "key"
                    )
                }
                
                HStack {
                    Spacer()
                    NavigationLink(destination: ForgotPasswordView()) {
                        Text("Forgot Password?")
                            .font(.caption)
                            .foregroundColor(.blue)
                    }
                }
                .padding(.horizontal, 20)
                
                if let errorMessage = authVM.errorMessage {
                    ErrorMessageView(message: errorMessage)
                }
            }
            
            Spacer()
            
            VStack(spacing: 16) {
                CustomButton(
                    title: "Login",
                    action: {
                        authVM.login(email: email, password: password)
                    },
                    isLoading: authVM.isLoading,
                    isEnabled: isFormValid,
                    backgroundColor: .blue,
                    disabledColor: .gray
                )
                .padding(.horizontal, 20)
                
                CustomButton(
                    title: "Login with Face ID",
                    action: {
                        Task {
                            await authVM.loginWithFaceID()
                        }
                    },
                    isEnabled: authVM.isFaceIDAvailable,
                    backgroundColor: .black,
                    disabledColor: .gray
                )
                .padding(.horizontal, 20)
                
                CustomSecondaryButton(
                    title: "Don't have an account? Sign Up!",
                    action: {
                        currentAuthScreen = .signup
                    }
                )
            }
            .padding(.bottom, 40)
        }
        .navigationTitle("Login")
        .navigationBarTitleDisplayMode(.large)
    }
}

#Preview {
    NavigationStack {
        LoginView(currentAuthScreen: .constant(.login))
            .environmentObject(AuthViewModel())
    }
} 