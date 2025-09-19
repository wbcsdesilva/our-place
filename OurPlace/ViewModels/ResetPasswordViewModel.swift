//
//  ResetPasswordViewModel.swift
//  OurPlace
//
//  Created by Chaniru Sandive on 2025-08-06.
//

import SwiftUI
import Foundation

class ResetPasswordViewModel: ObservableObject {
    @Published var newPassword = ""
    @Published var confirmPassword = ""
    @Published var isLoading = false
    @Published var showSuccessAlert = false
    @Published var errorMessage: String?
    
    private let oobCode: String
    private let apiKey = "AIzaSyD16eiGE9GtDd8U4lkVKHbk84zvoFAu3y4"
    
    init(oobCode: String) {
        self.oobCode = oobCode
    }
    
    // MARK: - Validation Methods
    
    private func validatePassword(_ password: String) -> Bool {
        return password.count >= 6
    }
    
    private func validatePasswordStrength(_ password: String) -> (isValid: Bool, message: String?) {
        if password.count < 6 {
            return (false, "Password must be at least 6 characters long")
        }
        
        if password.count < 8 {
            return (true, "Consider using a longer password for better security")
        }
        
        return (true, nil)
    }
    
    // MARK: - Reset Password Method
    
    func resetPassword() {
        errorMessage = nil
        
        guard !newPassword.isEmpty else {
            errorMessage = "New password is required"
            return
        }
        
        guard !confirmPassword.isEmpty else {
            errorMessage = "Please confirm your new password"
            return
        }
        
        let passwordValidation = validatePasswordStrength(newPassword)
        guard passwordValidation.isValid else {
            errorMessage = passwordValidation.message
            return
        }
        
        guard newPassword == confirmPassword else {
            errorMessage = "Passwords do not match"
            return
        }
        
        isLoading = true
        
        let url = URL(string: "https://identitytoolkit.googleapis.com/v1/accounts:resetPassword?key=\(apiKey)")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let requestBody = [
            "oobCode": oobCode,
            "newPassword": newPassword
        ]
        
        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: requestBody)
        } catch {
            DispatchQueue.main.async {
                self.isLoading = false
                self.errorMessage = "Failed to prepare request"
            }
            return
        }
        
        URLSession.shared.dataTask(with: request) { [weak self] data, response, error in
            DispatchQueue.main.async {
                self?.isLoading = false
                
                if let error = error {
                    self?.errorMessage = "Network error: \(error.localizedDescription)"
                    return
                }
                
                guard let data = data else {
                    self?.errorMessage = "No response data received"
                    return
                }
                
                do {
                    if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any] {
                        if let error = json["error"] as? [String: Any] {
                            let message = error["message"] as? String ?? "Unknown error occurred"
                            self?.errorMessage = self?.getUserFriendlyErrorMessage(from: message)
                        } else {
                            self?.showSuccessAlert = true
                        }
                    }
                } catch {
                    self?.errorMessage = "Failed to parse response"
                }
            }
        }.resume()
    }
    
    // MARK: - Error Message Mapping
    
    private func getUserFriendlyErrorMessage(from firebaseMessage: String) -> String {
        if firebaseMessage.contains("INVALID_OOB_CODE") {
            return "Invalid or expired reset link. Please request a new password reset."
        } else if firebaseMessage.contains("WEAK_PASSWORD") {
            return "Password is too weak. Please choose a stronger password."
        } else if firebaseMessage.contains("EXPIRED_OOB_CODE") {
            return "Reset link has expired. Please request a new password reset."
        } else if firebaseMessage.contains("INVALID_PASSWORD") {
            return "Invalid password format. Please try again."
        } else {
            return "Failed to reset password. Please try again."
        }
    }
}
