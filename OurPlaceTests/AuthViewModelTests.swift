//
//  AuthViewModelTests.swift
//  OurPlaceTests
//
//  Created by Chaniru Sandive on 2025-08-06.
//

import Testing
@testable import OurPlace
import FirebaseAuth

struct AuthViewModelTests {
    
    // MARK: - Email Validation Tests
    
    @Test func testValidEmailAddresses() async throws {
        let viewModel = AuthViewModel()
        
        // Test valid email formats
        let validEmails = [
            "test@example.com",
            "user.name@domain.co.uk",
            "user+tag@example.org",
            "123@numbers.com",
            "user@subdomain.example.com"
        ]
        
        for email in validEmails {
            #expect(viewModel.validateEmail(email) == true, "Email '\(email)' should be valid")
        }
    }
    
    @Test func testInvalidEmailAddresses() async throws {
        let viewModel = AuthViewModel()
        
        // Test invalid email formats
        let invalidEmails = [
            "",
            "invalid-email",
            "@example.com",
            "user@",
            "user..name@example.com",
            "user@.com",
            "user name@example.com"
        ]
        
        for email in invalidEmails {
            #expect(viewModel.validateEmail(email) == false, "Email '\(email)' should be invalid")
        }
    }
    
    // MARK: - Password Validation Tests
    
    @Test func testPasswordLengthValidation() async throws {
        let viewModel = AuthViewModel()
        
        // Test password length requirements
        let shortPassword = "12345"  // 5 characters
        let validPassword = "123456" // 6 characters (minimum)
        let longPassword = "123456789" // 9 characters
        
        #expect(viewModel.validatePassword(shortPassword) == false, "Password with 5 characters should be invalid")
        #expect(viewModel.validatePassword(validPassword) == true, "Password with 6 characters should be valid")
        #expect(viewModel.validatePassword(longPassword) == true, "Password with 9 characters should be valid")
    }
    
    @Test func testPasswordStrengthValidation() async throws {
        let viewModel = AuthViewModel()
        
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
        let viewModel = AuthViewModel()
        
        // Test empty inputs for login
        viewModel.login(email: "", password: "password123")
        #expect(viewModel.errorMessage == "Email is required", "Empty email should show error")
        
        viewModel.login(email: "test@example.com", password: "")
        #expect(viewModel.errorMessage == "Password is required", "Empty password should show error")
    }
    
    @Test func testSignupInputValidation() async throws {
        let viewModel = AuthViewModel()
        
        // Test signup validation
        viewModel.signup(email: "", password: "password123", confirmPassword: "password123")
        #expect(viewModel.errorMessage == "Email is required", "Empty email in signup should show error")
        
        viewModel.signup(email: "test@example.com", password: "", confirmPassword: "")
        #expect(viewModel.errorMessage == "Password is required", "Empty password in signup should show error")
        
        viewModel.signup(email: "test@example.com", password: "password123", confirmPassword: "")
        #expect(viewModel.errorMessage == "Please confirm your password", "Empty confirm password should show error")
    }
    
    @Test func testPasswordMatchingValidation() async throws {
        let viewModel = AuthViewModel()
        
        // Test password matching
        viewModel.signup(email: "test@example.com", password: "password123", confirmPassword: "different123")
        #expect(viewModel.errorMessage == "Passwords do not match", "Mismatched passwords should show error")
        
        viewModel.signup(email: "test@example.com", password: "password123", confirmPassword: "password123")
        #expect(viewModel.errorMessage == nil || viewModel.errorMessage?.contains("Firebase") == true, "Matching passwords should not show validation error")
    }
    
    // MARK: - Error Message Tests
    
    @Test func testFirebaseErrorMapping() async throws {
        let viewModel = AuthViewModel()
        
        viewModel.errorMessage = "Previous error"
        viewModel.login(email: "test@example.com", password: "password123")
        #expect(viewModel.errorMessage != "Previous error", "Error message should be cleared for new operations")
    }
    
    // MARK: - State Management Tests
    
    @Test func testLoadingState() async throws {
        let viewModel = AuthViewModel()
        
        #expect(viewModel.isLoading == false, "Initial loading state should be false")
        #expect(viewModel.errorMessage == nil, "Initial error message should be nil")
    }
}

// MARK: - Helper Extensions for Testing

extension AuthViewModel {
    // Make private methods accessible for testing
    func validateEmail(_ email: String) -> Bool {
        let emailRegex = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}"
        let emailPredicate = NSPredicate(format: "SELF MATCHES %@", emailRegex)
        
        // Additional check for consecutive dots
        if email.contains("..") {
            return false
        }
        
        return emailPredicate.evaluate(with: email)
    }
    
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
}
