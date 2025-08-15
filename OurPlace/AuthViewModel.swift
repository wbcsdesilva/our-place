//
//  AuthViewModel.swift
//  OurPlace
//
//  Created by Chaniru Sandive on 2025-08-06.
//

import SwiftUI
import FirebaseAuth
import Firebase

class AuthViewModel: ObservableObject {
    @Published var user: User?
    @Published var errorMessage: String?
    @Published var isLoading = false
    
    private var authStateListener: AuthStateDidChangeListenerHandle?
    
    init() {
        setupAuthStateListener()
        testFirebaseConnection()
    }
    
    deinit {
        if let listener = authStateListener {
            Auth.auth().removeStateDidChangeListener(listener)
        }
    }
    
    private func setupAuthStateListener() {
        authStateListener = Auth.auth().addStateDidChangeListener { [weak self] _, user in
            DispatchQueue.main.async {
                self?.user = user
            }
        }
    }
    
    private func testFirebaseConnection() {
        if Auth.auth().app != nil {
            print("Firebase Auth is properly configured")
        } else {
            print("Firebase Auth configuration issue")
        }
    }
    
    // MARK: - Validation Methods
    
    private func validateEmail(_ email: String) -> Bool {
        let emailRegex = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}"
        let emailPredicate = NSPredicate(format: "SELF MATCHES %@", emailRegex)
        
        // Additional check for consecutive dots
        if email.contains("..") {
            return false
        }
        
        return emailPredicate.evaluate(with: email)
    }
    
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
    
    // MARK: - Authentication Methods
    
    func login(email: String, password: String) {
        errorMessage = nil
        
        guard !email.isEmpty else {
            errorMessage = "Email is required"
            return
        }
        
        guard !password.isEmpty else {
            errorMessage = "Password is required"
            return
        }
        
        guard validateEmail(email) else {
            errorMessage = "Please enter a valid email address"
            return
        }
        
        guard validatePassword(password) else {
            errorMessage = "Password must be at least 6 characters long"
            return
        }
        
        isLoading = true
        
        Auth.auth().signIn(withEmail: email, password: password) { [weak self] result, error in
            DispatchQueue.main.async {
                self?.isLoading = false
                
                if let error = error {
                    self?.errorMessage = self?.getUserFriendlyErrorMessage(from: error)
                }
            }
        }
    }
    
    func signup(email: String, password: String, confirmPassword: String) {
        errorMessage = nil
        
        guard !email.isEmpty else {
            errorMessage = "Email is required"
            return
        }
        
        guard !password.isEmpty else {
            errorMessage = "Password is required"
            return
        }
        
        guard !confirmPassword.isEmpty else {
            errorMessage = "Please confirm your password"
            return
        }
        
        guard validateEmail(email) else {
            errorMessage = "Please enter a valid email address"
            return
        }
        
        let passwordValidation = validatePasswordStrength(password)
        guard passwordValidation.isValid else {
            errorMessage = passwordValidation.message
            return
        }
        
        guard password == confirmPassword else {
            errorMessage = "Passwords do not match"
            return
        }
        
        isLoading = true
        
        Auth.auth().createUser(withEmail: email, password: password) { [weak self] result, error in
            DispatchQueue.main.async {
                self?.isLoading = false
                
                if let error = error {
                    self?.errorMessage = self?.getUserFriendlyErrorMessage(from: error)
                }
            }
        }
    }
    
    func signOut() {
        do {
            try Auth.auth().signOut()
        } catch {
            errorMessage = "Failed to sign out. Please try again."
        }
    }
    
    // MARK: - Error Message Mapping
    
    private func getUserFriendlyErrorMessage(from error: Error) -> String {
        let nsError = error as NSError
        
        print("Firebase error code: \(nsError.code)")
        print("Firebase error domain: \(nsError.domain)")
        print("Firebase error description: \(nsError.localizedDescription)")
        
        switch nsError.code {
        case AuthErrorCode.invalidCredential.rawValue:
            return "Invalid email or password. Please try again."
        case AuthErrorCode.invalidEmail.rawValue:
            return "Please enter a valid email address."
        case AuthErrorCode.emailAlreadyInUse.rawValue:
            return "An account with this email already exists."
        case AuthErrorCode.weakPassword.rawValue:
            return "Password is too weak. Please choose a stronger password."
        case AuthErrorCode.networkError.rawValue:
            return "Network error. Please check your internet connection."
        case AuthErrorCode.tooManyRequests.rawValue:
            return "Too many failed attempts. Please try again later."
        case AuthErrorCode.userDisabled.rawValue:
            return "This account has been disabled. Please contact support."
        case AuthErrorCode.operationNotAllowed.rawValue:
            return "Email/password sign-in is not enabled for this app."
        default:
            return "An error occurred. Please try again."
        }
    }
} 