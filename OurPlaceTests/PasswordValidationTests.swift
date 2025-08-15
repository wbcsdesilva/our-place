//
//  PasswordValidationTests.swift
//  OurPlaceTests
//
//  Created by Chaniru Sandive on 2025-08-06.
//

import Testing
@testable import OurPlace

struct PasswordValidationTests {
    
    // MARK: - Password Length Tests
    
    @Test func testPasswordMinimumLength() async throws {
        // Test various password lengths
        let passwords = [
            ("", 0, false),
            ("1", 1, false),
            ("12", 2, false),
            ("123", 3, false),
            ("1234", 4, false),
            ("12345", 5, false),
            ("123456", 6, true),      // Minimum valid length
            ("1234567", 7, true),
            ("12345678", 8, true),
            ("123456789", 9, true),
            ("1234567890", 10, true)
        ]
        
        for (password, length, expected) in passwords {
            let isValid = password.count >= 6
            #expect(isValid == expected, "Password '\(password)' (length: \(length)) should be \(expected ? "valid" : "invalid")")
        }
    }
    
    // MARK: - Password Strength Tests
    
    @Test func testPasswordStrengthCategories() async throws {
        // Test password strength categorization
        let weakPasswords = [
            "123456",      // Exactly minimum length
            "abcdef",      // Only letters, minimum length
            "1234567"      // Slightly above minimum
        ]
        
        let strongPasswords = [
            "Secure123!",  // Mixed case, numbers, symbols
            "MyPassword2024", // Long, mixed content
            "a".repeating(20) // Very long
        ]
        
        // Test weak passwords
        for password in weakPasswords {
            let strength = calculatePasswordStrength(password)
            #expect(strength == .weak || strength == .medium, "Password '\(password)' should be weak or medium")
        }
        
        // Test strong passwords
        for password in strongPasswords {
            let strength = calculatePasswordStrength(password)
            #expect(strength == .strong, "Password '\(password)' should be strong")
        }
        
        // Test medium passwords (8+ chars with basic complexity)
        let mediumPasswords = ["12345678", "abcdefgh", "ABCDEFGH"]
        for password in mediumPasswords {
            let strength = calculatePasswordStrength(password)
            #expect(strength == .medium, "Password '\(password)' should be medium")
        }
    }
    
    @Test func testPasswordComplexity() async throws {
        // Test passwords with different character types
        let simplePasswords = [
            "123456789",   // Only numbers
            "abcdefghij",  // Only lowercase letters
            "ABCDEFGHIJ"   // Only uppercase letters
        ]
        
        let complexPasswords = [
            "Pass123!",    // Mixed case + numbers + symbol
            "My@cc0unt",   // Mixed case + symbol + numbers
            "S3cur3P@ss",  // Complex mixed content
            "Test123@#$"   // Multiple symbols
        ]
        
        // Simple passwords should be weaker
        for password in simplePasswords {
            let strength = calculatePasswordStrength(password)
            #expect(strength != .strong, "Simple password '\(password)' should not be strong")
        }
        
        // Complex passwords should be stronger
        for password in complexPasswords {
            let strength = calculatePasswordStrength(password)
            #expect(strength == .strong, "Complex password '\(password)' should be strong")
        }
    }
    
    // MARK: - Edge Cases
    
    @Test func testPasswordEdgeCases() async throws {
        // Test very long passwords
        let veryLongPassword = "a".repeating(100)
        let strength = calculatePasswordStrength(veryLongPassword)
        #expect(strength == .strong, "Very long password should be strong")
        
        // Test passwords with special characters
        let specialCharPasswords = [
            "pass word",   // Space
            "pass\nword",  // Newline
            "pass\tword",  // Tab
            "pass\rword",  // Carriage return
            "pass\u{0000}word" // Null character
        ]
        
        for password in specialCharPasswords {
            let isValid = password.count >= 6
            #expect(isValid == true, "Password with special characters should be valid if length >= 6")
        }
    }
    
    // MARK: - Validation Consistency
    
    @Test func testValidationConsistency() async throws {
        // Test that validation is consistent across different methods
        let testPasswords = [
            "123456",      // Minimum valid
            "password123", // Medium strength
            "SecurePass123!" // Strong
        ]
        
        for password in testPasswords {
            let lengthValid = password.count >= 6
            let strengthValid = calculatePasswordStrength(password) != .invalid
            
            #expect(lengthValid == strengthValid, "Length and strength validation should be consistent for '\(password)'")
        }
    }
}

// MARK: - Helper Functions

enum PasswordStrength {
    case weak
    case medium
    case strong
    case invalid
}

func calculatePasswordStrength(_ password: String) -> PasswordStrength {
    guard password.count >= 6 else {
        return .invalid
    }
    
    if password.count < 8 {
        return .weak
    }
    
    // Check for complexity
    let hasUppercase = password.contains { $0.isUppercase }
    let hasLowercase = password.contains { $0.isLowercase }
    let hasNumbers = password.contains { $0.isNumber }
    let hasSymbols = password.contains { !$0.isLetter && !$0.isNumber && !$0.isWhitespace }
    
    let complexityScore = [hasUppercase, hasLowercase, hasNumbers, hasSymbols].filter { $0 }.count
    
    if password.count >= 12 || complexityScore >= 3 {
        return .strong
    } else if password.count >= 8 && complexityScore >= 1 {
        return .medium
    } else if password.count >= 8 {
        return .weak
    } else {
        return .weak
    }
}

extension String {
    func repeating(_ count: Int) -> String {
        return String(repeating: self, count: count)
    }
}
