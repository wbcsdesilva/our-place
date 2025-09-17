//
//  OurPlaceApp.swift
//  OurPlace
//
//  Created by Chaniru Sandive on 2025-08-06.
//

import SwiftUI
import Firebase

@main
struct OurPlaceApp: App {
    @StateObject private var authVM = AuthViewModel()
    @StateObject private var router = AppRouter()
    @State private var resetPasswordOobCode: String?
    @State private var showResetPassword = false
    
    init() {
        // Configure Firebase
        FirebaseApp.configure()
        
        // Initialize Core Data
        _ = CoreDataManager.shared
        
        // Verify Firebase is properly configured
        if FirebaseApp.app() != nil {
            print("Firebase successfully configured")
        } else {
            print("Firebase configuration failed")
        }
    }
    
    var body: some Scene {
        WindowGroup {
            AuthWrapperView()
                .environmentObject(authVM)
                .environmentObject(router)
                .environment(\.managedObjectContext, CoreDataManager.shared.context)
                .fullScreenCover(isPresented: $showResetPassword) {
                    if let oobCode = resetPasswordOobCode {
                        NavigationStack {
                            ResetPasswordView(oobCode: oobCode)
                        }
                    }
                }
                .onOpenURL { url in
                    handlePasswordResetURL(url)
                }
        }
    }
    
    // MARK: - URL Handling
    
    private func handlePasswordResetURL(_ url: URL) {
        print("Received URL: \(url)")
        
        // Parse the URL to extract oobCode
        guard let components = URLComponents(url: url, resolvingAgainstBaseURL: false),
              let queryItems = components.queryItems else {
            print("Invalid URL format")
            return
        }
        
        // Look for oobCode parameter
        if let oobCodeItem = queryItems.first(where: { $0.name == "oobCode" }),
           let oobCode = oobCodeItem.value {
            print("Found oobCode: \(oobCode)")
            resetPasswordOobCode = oobCode
            showResetPassword = true
        } else {
            print("No oobCode found in URL")
        }
    }
}
