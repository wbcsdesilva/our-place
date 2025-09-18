//
//  SignupView.swift
//  OurPlace
//
//  Created by Chaniru Sandive on 2025-08-06.
//

import SwiftUI

struct SignupView: View {
    @EnvironmentObject var authVM: AuthViewModel
    @Binding var currentAuthScreen: AuthScreen
    @State private var name = ""
    @State private var email = ""
    @State private var password = ""
    @State private var confirmPassword = ""
    
    var body: some View {
        VStack(spacing: 0) {
            VStack(spacing: 20) {
                Text("Create Account")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .padding(.top, 50)
                
                FormSectionView(spacing: 15) {
                    TextInput(
                        title: "Name",
                        placeholder: "Enter your full name",
                        text: $name,
                        icon: "person"
                    )

                    TextInput(
                        title: "Email",
                        placeholder: "Enter your email",
                        text: $email,
                        keyboardType: .emailAddress,
                        autocapitalization: .never,
                        icon: "at"
                    )

                    TextInput(
                        title: "Password",
                        placeholder: "Enter your password",
                        text: $password,
                        isSecure: true,
                        icon: "lock"
                    )

                    PasswordStrengthView(password: password)

                    TextInput(
                        title: "Confirm Password",
                        placeholder: "Confirm your password",
                        text: $confirmPassword,
                        isSecure: true,
                        icon: "lock"
                    )

                    if !confirmPassword.isEmpty && password != confirmPassword {
                        ErrorMessageView(
                            message: "Passwords do not match",
                            alignment: .leading
                        )
                    }
                }
                
                if let errorMessage = authVM.errorMessage {
                    ErrorMessageView(message: errorMessage)
                }
            }
            
            Spacer()
            
            VStack(spacing: 16) {
                CustomButton(
                    title: "Sign Up",
                    action: {
                        authVM.signup(email: email, password: password, confirmPassword: confirmPassword)
                    },
                    isLoading: authVM.isLoading,
                    backgroundColor: .blue
                )
                .padding(.horizontal, 20)
                
                CustomSecondaryButton(
                    title: "Already have an account? Login!",
                    action: {
                        currentAuthScreen = .login
                    }
                )
            }
            .padding(.bottom, 40)
        }
        .navigationTitle("Sign Up")
        .navigationBarTitleDisplayMode(.large)
    }
}

#Preview {
    NavigationStack {
        SignupView(currentAuthScreen: .constant(.signup))
            .environmentObject(AuthViewModel())
    }
} 