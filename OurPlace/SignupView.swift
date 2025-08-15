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
                    CustomTextField(
                        placeholder: "Name",
                        text: $name,
                        icon: "person"
                    )
                    
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
                    
                    PasswordStrengthView(password: password)
                    
                    CustomTextField(
                        placeholder: "Confirm Password",
                        text: $confirmPassword,
                        isSecure: true,
                        icon: "key.fill"
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