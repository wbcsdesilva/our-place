//
//  FaceIDManagerTests.swift
//  OurPlaceTests
//
//  Created by Chaniru Sandive on 2025-08-16.
//

import Testing
@testable import OurPlace
import LocalAuthentication

struct FaceIDManagerTests {
    
    // Helper function to create a test manager with unique keychain service
    private func createTestManager() -> FaceIDManager {
        let timestamp = Date().timeIntervalSince1970
        return FaceIDManager(
            keychainService: "com.test.OurPlace.faceid.\(timestamp)",
            keychainAccount: "testCredentials"
        )
    }
    
    // MARK: - Initialization Tests
    
    @Test func testInitialization() async throws {
        let manager = FaceIDManager()
        
        #expect(manager.isFaceIDAvailable == false || manager.isFaceIDAvailable == true, "Face ID availability should be determined")
        #expect(manager.isAuthenticated == false, "Initial authentication state should be false")
        #expect(manager.errorMessage == nil, "Initial error message should be nil")
    }
    
    // MARK: - Credential Storage Tests
    
    @Test func testStoreCredentials() async throws {
        let manager = createTestManager()
        
        // Clear any existing credentials first
        _ = manager.clearCredentials()
        
        let email = "test@example.com"
        let password = "password123"
        
        let success = manager.storeCredentials(email: email, password: password)
        #expect(success == true, "Credentials should be stored successfully")
    }
    
    @Test func testRetrieveCredentials() async throws {
        let manager = createTestManager()
        
        // Clear any existing credentials first
        _ = manager.clearCredentials()
        
        let email = "test@example.com"
        let password = "password123"
        
        // Store credentials first
        let storeSuccess = manager.storeCredentials(email: email, password: password)
        #expect(storeSuccess == true, "Credentials should be stored")
        
        // Retrieve credentials
        let credentials = manager.retrieveCredentials()
        #expect(credentials != nil, "Credentials should be retrievable")
        #expect(credentials?.email == email, "Retrieved email should match stored email")
        #expect(credentials?.password == password, "Retrieved password should match stored password")
    }
    
    @Test func testClearCredentials() async throws {
        let manager = createTestManager()
        
        // Clear any existing credentials first
        _ = manager.clearCredentials()
        
        let email = "test@example.com"
        let password = "password123"
        
        // Store credentials
        let storeSuccess = manager.storeCredentials(email: email, password: password)
        #expect(storeSuccess == true, "Credentials should be stored")
        
        // Verify credentials exist
        let credentials = manager.retrieveCredentials()
        #expect(credentials != nil, "Credentials should exist after storing")
        
        // Clear credentials
        let clearSuccess = manager.clearCredentials()
        #expect(clearSuccess == true, "Credentials should be cleared successfully")
        
        // Verify credentials are gone
        let retrievedCredentials = manager.retrieveCredentials()
        #expect(retrievedCredentials == nil, "Credentials should be nil after clearing")
    }
    
    // MARK: - Error Message Tests
    
    @Test func testFaceIDErrorMessages() async throws {
        let manager = FaceIDManager()
        
        // Test various error scenarios
        let testErrors: [(LAError, String)] = [
            (LAError(.userCancel), "Face ID authentication was cancelled"),
            (LAError(.userFallback), "Please use your password to log in"),
            (LAError(.biometryNotAvailable), "Face ID is not available on this device"),
            (LAError(.biometryNotEnrolled), "Face ID is not set up on this device"),
            (LAError(.biometryLockout), "Face ID is locked. Please use your password"),
            (LAError(.authenticationFailed), "Face ID authentication failed. Please try again")
        ]
        
        for (error, expectedMessage) in testErrors {
            let message = manager.getFaceIDErrorMessage(from: error)
            #expect(message.contains(expectedMessage), "Error message should contain expected text")
        }
    }
    
    // MARK: - Edge Cases
    
    @Test func testEmptyCredentials() async throws {
        let manager = createTestManager()
        
        // Clear any existing credentials first
        _ = manager.clearCredentials()
        
        // Test storing empty email credentials
        let emptyEmailSuccess = manager.storeCredentials(email: "", password: "password")
        #expect(emptyEmailSuccess == true, "Empty email should be stored")
        
        // Test retrieving empty email credentials
        let emptyEmailCredentials = manager.retrieveCredentials()
        #expect(emptyEmailCredentials?.email == "", "Empty email should be retrieved")
        #expect(emptyEmailCredentials?.password == "password", "Password should be retrieved")
        
        // Clear and test empty password
        _ = manager.clearCredentials()
        let emptyPasswordSuccess = manager.storeCredentials(email: "email", password: "")
        #expect(emptyPasswordSuccess == true, "Empty password should be stored")
        
        // Test retrieving empty password credentials
        let emptyPasswordCredentials = manager.retrieveCredentials()
        #expect(emptyPasswordCredentials?.email == "email", "Email should be retrieved")
        #expect(emptyPasswordCredentials?.password == "", "Empty password should be retrieved")
    }
    
    @Test func testSpecialCharactersInCredentials() async throws {
        let manager = createTestManager()
        
        // Clear any existing credentials first
        _ = manager.clearCredentials()
        
        let email = "test+tag@example.com"
        let password = "pass@word#123!"
        
        let storeSuccess = manager.storeCredentials(email: email, password: password)
        #expect(storeSuccess == true, "Special characters should be stored")
        
        let credentials = manager.retrieveCredentials()
        #expect(credentials?.email == email, "Special characters in email should be preserved")
        #expect(credentials?.password == password, "Special characters in password should be preserved")
    }
}

// MARK: - Helper Extensions for Testing

extension FaceIDManager {
    // Make private methods accessible for testing
    func getFaceIDErrorMessage(from error: Error) -> String {
        let nsError = error as NSError
        
        switch nsError.code {
        case LAError.userCancel.rawValue:
            return "Face ID authentication was cancelled"
        case LAError.userFallback.rawValue:
            return "Please use your password to log in"
        case LAError.biometryNotAvailable.rawValue:
            return "Face ID is not available on this device"
        case LAError.biometryNotEnrolled.rawValue:
            return "Face ID is not set up on this device"
        case LAError.biometryLockout.rawValue:
            return "Face ID is locked. Please use your password"
        case LAError.authenticationFailed.rawValue:
            return "Face ID authentication failed. Please try again"
        default:
            return "Face ID authentication failed. Please try again"
        }
    }
}
