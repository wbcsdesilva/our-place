//
//  FaceIDManager.swift
//  OurPlace
//
//  Created by Chaniru Sandive on 2025-01-XX.
//

import Foundation
import LocalAuthentication
import Security

class FaceIDManager: ObservableObject {
    @Published var isFaceIDAvailable = false
    @Published var isAuthenticated = false
    @Published var errorMessage: String?
    
    private let context = LAContext()
    private let keychainService: String
    private let keychainAccount: String
    
    init(keychainService: String = "com.ioscw016.OurPlace.faceid", keychainAccount: String = "userCredentials") {
        self.keychainService = keychainService
        self.keychainAccount = keychainAccount
        checkFaceIDAvailability()
    }
    
    // MARK: - Face ID Availability
    
    private func checkFaceIDAvailability() {
        // Create a fresh context for availability checking to avoid stale state
        let freshContext = LAContext()
        var error: NSError?
        
        let canEvaluateBiometrics = freshContext.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error)
        let biometryType = freshContext.biometryType
        
        let isAvailable = canEvaluateBiometrics && biometryType == .faceID
        
        DispatchQueue.main.async {
            self.isFaceIDAvailable = isAvailable
        }
    }
    
    func refreshAvailability() {
        checkFaceIDAvailability()
    }
    
    func resetAuthenticationState() {
        DispatchQueue.main.async {
            self.isAuthenticated = false
            self.errorMessage = nil
        }
        checkFaceIDAvailability()
    }
    
    // MARK: - Face ID Authentication
    
    func authenticateWithFaceID() async -> Bool {
        // Check availability on main thread
        let isAvailable = await MainActor.run { self.isFaceIDAvailable }
        
        guard isAvailable else {
            await MainActor.run {
                self.errorMessage = "Face ID is not available on this device"
            }
            return false
        }
        
        // Use a fresh context for each authentication attempt
        let context = LAContext()
        let reason = "Log in to OurPlace"
        
        do {
            let success = try await context.evaluatePolicy(
                .deviceOwnerAuthenticationWithBiometrics,
                localizedReason: reason
            )
            
            await MainActor.run {
                self.isAuthenticated = success
                if success {
                    self.errorMessage = nil
                } else {
                    self.errorMessage = "Face ID authentication failed"
                }
            }
            
            return success
        } catch {
            let errorMessage = getFaceIDErrorMessage(from: error)
            await MainActor.run {
                self.isAuthenticated = false
                self.errorMessage = errorMessage
            }
            return false
        }
    }
    
    // MARK: - Credential Storage
    
    func storeCredentials(email: String, password: String) -> Bool {
        let credentials = ["email": email, "password": password]
        
        guard let data = try? JSONSerialization.data(withJSONObject: credentials) else {
            return false
        }
        
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: keychainService,
            kSecAttrAccount as String: keychainAccount,
            kSecValueData as String: data,
            kSecAttrAccessible as String: kSecAttrAccessibleWhenUnlockedThisDeviceOnly
        ]
        
        SecItemDelete(query as CFDictionary)
        
        let status = SecItemAdd(query as CFDictionary, nil)
        return status == errSecSuccess
    }
    
    func retrieveCredentials() -> (email: String, password: String)? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: keychainService,
            kSecAttrAccount as String: keychainAccount,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]
        
        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        
        guard status == errSecSuccess,
              let data = result as? Data else {
            return nil
        }
        
        guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: String],
              let email = json["email"],
              let password = json["password"] else {
            return nil
        }
        
        return (email, password)
    }
    
    func clearCredentials() -> Bool {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: keychainService,
            kSecAttrAccount as String: keychainAccount
        ]
        
        let status = SecItemDelete(query as CFDictionary)
        return status == errSecSuccess || status == errSecItemNotFound
    }
    
    // MARK: - Error Handling
    
    private func getFaceIDErrorMessage(from error: Error) -> String {
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
