//
//  ForgotPasswordView.swift
//  OurPlace
//
//  Created by Chaniru Sandive on 2025-08-06.
//

import SwiftUI
import FirebaseAuth

struct ForgotPasswordView: View {
    @State private var email = ""
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var showSuccessAlert = false
    
    private var isFormValid: Bool {
        !email.isEmpty && isValidEmail(email)
    }
    
    var body: some View {
        VStack(spacing: 24) {
            // Header
            VStack(spacing: 8) {
                Image(systemName: "envelope")
                    .font(.system(size: 60))
                    .foregroundColor(.blue)
                
                Text("Forgot Password?")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                
                Text("Enter your email address and we'll send you a link to reset your password.")
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
            .padding(.top, 40)
            .padding(.horizontal, 20)
            
            // Email Field
            FormSectionView(spacing: 16) {
                TextInput(
                    title: "Email",
                    placeholder: "Enter your email address",
                    text: $email,
                    keyboardType: .emailAddress,
                    autocapitalization: .never,
                    icon: "at"
                )
            }
            
            // Error Message
            if let errorMessage = errorMessage {
                ErrorMessageView(message: errorMessage)
            }
            
            // Submit Button
            CustomButton(
                title: "Send Reset Link",
                action: {
                    sendPasswordResetEmail()
                },
                isLoading: isLoading,
                isEnabled: isFormValid,
                backgroundColor: .blue,
                disabledColor: .gray,
                cornerRadius: 12
            )
            .padding(.horizontal, 20)
            
            Spacer()
        }
        .navigationTitle("Forgot Password")
        .navigationBarTitleDisplayMode(.large)
        .alert("Reset Link Sent", isPresented: $showSuccessAlert) {
            Button("OK") {
                // User can navigate back using the back button
            }
        } message: {
            Text("If an account with that email exists, we've sent a password reset link. Please check your email and spam folder.")
        }
    }
    
    // MARK: - Helper Methods
    
    private func isValidEmail(_ email: String) -> Bool {
        let emailRegex = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}"
        let emailPredicate = NSPredicate(format: "SELF MATCHES %@", emailRegex)
        return emailPredicate.evaluate(with: email)
    }
    
    private func sendPasswordResetEmail() {
        isLoading = true
        errorMessage = nil
        
        print("Attempting to send password reset email to: \(email)")
        print("Firebase Auth instance: \(Auth.auth())")
        
        // Use the correct Firebase method for password reset
        Auth.auth().sendPasswordReset(withEmail: email) { error in
            DispatchQueue.main.async {
                self.isLoading = false
                
                if let error = error {
                    print("Password reset error: \(error.localizedDescription)")
                    print("Error code: \((error as NSError).code)")
                    self.errorMessage = self.getUserFriendlyErrorMessage(from: error)
                } else {
                    print("Password reset email sent successfully")
                    print("Check your email and spam folder for the reset link")
                    self.showSuccessAlert = true
                }
            }
        }
    }
    
    private func getUserFriendlyErrorMessage(from error: Error) -> String {
        let nsError = error as NSError
        
        switch nsError.code {
        case AuthErrorCode.invalidEmail.rawValue:
            return "Please enter a valid email address."
        case AuthErrorCode.userNotFound.rawValue:
            // Don't reveal if user exists or not for security
            return "If an account with that email exists, we've sent a password reset link."
        case AuthErrorCode.networkError.rawValue:
            return "Network error. Please check your internet connection."
        case AuthErrorCode.tooManyRequests.rawValue:
            return "Too many requests. Please try again later."
        case AuthErrorCode.operationNotAllowed.rawValue:
            return "Password reset is not enabled for this app."
        default:
            return "An error occurred. Please try again."
        }
    }
}

#Preview {
    NavigationStack {
        ForgotPasswordView()
    }
}
