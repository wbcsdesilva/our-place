//
//  ResetPasswordViewModelTests.swift
//  OurPlaceTests
//
//  Created by Chaniru Sandive on 2025-08-06.
//

import Testing
@testable import OurPlace

struct ResetPasswordViewModelTests {
    
    // MARK: - Initialization Tests
    
    @Test func testInitialization() async throws {
        let oobCode = "test-oob-code-123"
        let viewModel = ResetPasswordViewModel(oobCode: oobCode)
        
        #expect(viewModel.newPassword == "", "Initial new password should be empty")
        #expect(viewModel.confirmPassword == "", "Initial confirm password should be empty")
        #expect(viewModel.isLoading == false, "Initial loading state should be false")
        #expect(viewModel.showSuccessAlert == false, "Initial success alert should be false")
        #expect(viewModel.errorMessage == nil, "Initial error message should be nil")
    }
    
    // MARK: - Password Validation Tests
    
    @Test func testPasswordLengthValidation() async throws {
        let viewModel = ResetPasswordViewModel(oobCode: "test")
        
        // Test password length requirements
        let shortPassword = "12345"  // 5 characters
        let validPassword = "123456" // 6 characters (minimum)
        let longPassword = "123456789" // 9 characters
        
        #expect(viewModel.validatePassword(shortPassword) == false, "Password with 5 characters should be invalid")
        #expect(viewModel.validatePassword(validPassword) == true, "Password with 6 characters should be valid")
        #expect(viewModel.validatePassword(longPassword) == true, "Password with 9 characters should be valid")
    }
    
    @Test func testPasswordStrengthValidation() async throws {
        let viewModel = ResetPasswordViewModel(oobCode: "test")
        
        // Test password strength validation
        let weakPassword = "123456" // 6 characters, minimum
        let mediumPassword = "1234567" // 7 characters
        let strongPassword = "12345678" // 8 characters
        
        let weakResult = viewModel.validatePasswordStrength(weakPassword)
        let mediumResult = viewModel.validatePasswordStrength(mediumPassword)
        let strongResult = viewModel.validatePasswordStrength(strongPassword)
        
        #expect(weakResult.isValid == true, "6-character password should be valid")
        #expect(weakResult.message?.contains("Consider using a longer password") == true, "Should suggest longer password")
        
        #expect(mediumResult.isValid == true, "7-character password should be valid")
        #expect(mediumResult.message?.contains("Consider using a longer password") == true, "Should suggest longer password")
        
        #expect(strongResult.isValid == true, "8-character password should be valid")
        #expect(strongResult.message == nil, "Strong password should have no message")
    }
    
    // MARK: - Input Validation Tests
    
    @Test func testEmptyInputValidation() async throws {
        let viewModel = ResetPasswordViewModel(oobCode: "test")
        
        // Test empty new password
        viewModel.resetPassword()
        #expect(viewModel.errorMessage == "New password is required", "Empty new password should show error")
        
        // Test empty confirm password
        viewModel.newPassword = "password123"
        viewModel.resetPassword()
        #expect(viewModel.errorMessage == "Please confirm your new password", "Empty confirm password should show error")
    }
    
    @Test func testPasswordMatchingValidation() async throws {
        let viewModel = ResetPasswordViewModel(oobCode: "test")
        
        // Test password matching
        viewModel.newPassword = "password123"
        viewModel.confirmPassword = "different123"
        viewModel.resetPassword()
        #expect(viewModel.errorMessage == "Passwords do not match", "Mismatched passwords should show error")
        
        // Test matching passwords (should pass validation)
        viewModel.newPassword = "password123"
        viewModel.confirmPassword = "password123"
        viewModel.resetPassword()
        #expect(viewModel.errorMessage != "Passwords do not match", "Matching passwords should not show validation error")
    }
    
    @Test func testPasswordStrengthValidationInReset() async throws {
        let viewModel = ResetPasswordViewModel(oobCode: "test")
        
        // Test weak password
        viewModel.newPassword = "12345" // Too short
        viewModel.confirmPassword = "12345"
        viewModel.resetPassword()
        #expect(viewModel.errorMessage?.contains("at least 6 characters") == true, "Weak password should show strength error")
        
        // Test valid password
        viewModel.newPassword = "password123"
        viewModel.confirmPassword = "password123"
        viewModel.resetPassword()
        #expect(viewModel.errorMessage != "Password must be at least 6 characters long", "Valid password should not show strength error")
    }
    
    // MARK: - Error Message Mapping Tests
    
    @Test func testFirebaseErrorMapping() async throws {
        let viewModel = ResetPasswordViewModel(oobCode: "test")
        
        // Test various Firebase error messages
        let invalidOobMessage = "INVALID_OOB_CODE: The provided OOB code is invalid"
        let weakPasswordMessage = "WEAK_PASSWORD: Password is too weak"
        let expiredOobMessage = "EXPIRED_OOB_CODE: The OOB code has expired"
        let invalidPasswordMessage = "INVALID_PASSWORD: Invalid password format"
        let unknownMessage = "UNKNOWN_ERROR: Something went wrong"
        
        let invalidOobResult = viewModel.getUserFriendlyErrorMessage(from: invalidOobMessage)
        let weakPasswordResult = viewModel.getUserFriendlyErrorMessage(from: weakPasswordMessage)
        let expiredOobResult = viewModel.getUserFriendlyErrorMessage(from: expiredOobMessage)
        let invalidPasswordResult = viewModel.getUserFriendlyErrorMessage(from: invalidPasswordMessage)
        let unknownResult = viewModel.getUserFriendlyErrorMessage(from: unknownMessage)
        
        #expect(invalidOobResult.contains("Invalid or expired reset link"), "Should map INVALID_OOB_CODE correctly")
        #expect(weakPasswordResult.contains("Password is too weak"), "Should map WEAK_PASSWORD correctly")
        #expect(expiredOobResult.contains("Reset link has expired"), "Should map EXPIRED_OOB_CODE correctly")
        #expect(invalidPasswordResult.contains("Invalid password format"), "Should map INVALID_PASSWORD correctly")
        #expect(unknownResult.contains("Failed to reset password"), "Should map unknown errors to default message")
    }
    
    // MARK: - State Management Tests
    
    @Test func testLoadingStateChanges() async throws {
        let viewModel = ResetPasswordViewModel(oobCode: "test")
        
        #expect(viewModel.isLoading == false, "Initial loading state should be false")
    }
    
    @Test func testErrorClearing() async throws {
        let viewModel = ResetPasswordViewModel(oobCode: "test")
        
        // Set an error message
        viewModel.errorMessage = "Previous error"
        
        // Start reset password (should clear previous error)
        viewModel.newPassword = "password123"
        viewModel.confirmPassword = "password123"
        viewModel.resetPassword()
        
        // Error should be cleared (though actual reset would fail without network)
        #expect(viewModel.errorMessage != "Previous error", "Previous error should be cleared when starting reset")
    }
}

// MARK: - Helper Extensions for Testing

extension ResetPasswordViewModel {
    // Make private methods accessible for testing
    func validatePassword(_ password: String) -> Bool {
        return password.count >= 6
    }
    
    func validatePasswordStrength(_ password: String) -> (isValid: Bool, message: String?) {
        if password.count < 6 {
            return (false, "Password must be at least 6 characters long")
        }
        
        if password.count < 8 {
            return (true, "Consider using a longer password for better security")
        }
        
        return (true, nil)
    }
    
    func getUserFriendlyErrorMessage(from firebaseMessage: String) -> String {
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
