//
//  ResetPasswordView.swift
//  OurPlace
//
//  Created by Chaniru Sandive on 2025-08-06.
//

import SwiftUI

struct ResetPasswordView: View {
    @StateObject private var viewModel: ResetPasswordViewModel
    @Environment(\.dismiss) private var dismiss
    
    init(oobCode: String) {
        _viewModel = StateObject(wrappedValue: ResetPasswordViewModel(oobCode: oobCode))
    }
    
    private var isFormValid: Bool {
        !viewModel.newPassword.isEmpty && 
        !viewModel.confirmPassword.isEmpty && 
        viewModel.newPassword == viewModel.confirmPassword &&
        viewModel.newPassword.count >= 6
    }
    
    var body: some View {
        VStack(spacing: 0) {
            VStack(spacing: 24) {
                VStack(spacing: 8) {
                    Image(systemName: "lock.rotation")
                        .font(.system(size: 60))
                        .foregroundColor(.blue)
                    
                    Text("Reset Your Password")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                    
                    Text("Enter your new password below")
                        .font(.body)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
                .padding(.top, 40)
                
                FormSectionView(spacing: 16) {
                    TextInput(
                        title: "New Password",
                        placeholder: "Enter your new password",
                        text: $viewModel.newPassword,
                        isSecure: true,
                        icon: "lock"
                    )

                    PasswordStrengthView(password: viewModel.newPassword)

                    TextInput(
                        title: "Confirm New Password",
                        placeholder: "Confirm your new password",
                        text: $viewModel.confirmPassword,
                        isSecure: true,
                        icon: "lock"
                    )

                    if !viewModel.confirmPassword.isEmpty && viewModel.newPassword != viewModel.confirmPassword {
                        ErrorMessageView(
                            message: "Passwords do not match",
                            alignment: .leading
                        )
                    }
                }
                
                if let errorMessage = viewModel.errorMessage {
                    ErrorMessageView(message: errorMessage)
                }
            }
            
            Spacer()
            
            VStack(spacing: 16) {
                CustomButton(
                    title: "Reset Password",
                    action: {
                        viewModel.resetPassword()
                    },
                    isLoading: viewModel.isLoading,
                    isEnabled: isFormValid,
                    backgroundColor: .blue,
                    disabledColor: .gray
                )
                .padding(.horizontal, 20)
            }
            .padding(.bottom, 40)
        }
        .navigationTitle("Reset Password")
        .navigationBarTitleDisplayMode(.large)
        .alert("Password Reset Successful", isPresented: $viewModel.showSuccessAlert) {
            Button("OK") {
                dismiss()
            }
        } message: {
            Text("Your password has been successfully reset. You can now sign in with your new password.")
        }
    }
}

#Preview {
    NavigationStack {
        ResetPasswordView(oobCode: "sample-oob-code")
    }
}
