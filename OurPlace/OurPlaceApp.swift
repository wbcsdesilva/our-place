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
    
    init() {
        // Configure Firebase
        FirebaseApp.configure()
        
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
        }
    }
}
