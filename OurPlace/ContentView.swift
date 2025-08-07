//
//  ContentView.swift
//  OurPlace
//
//  Created by Chaniru Sandive on 2025-08-06.
//

import SwiftUI

struct ContentView: View {
    @StateObject private var authVM = AuthViewModel()
    
    var body: some View {
        AuthWrapperView()
            .environmentObject(authVM)
    }
}

#Preview {
    ContentView()
}
