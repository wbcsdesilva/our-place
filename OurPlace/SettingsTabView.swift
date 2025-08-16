//
//  SettingsTabView.swift
//  OurPlace
//
//  Created by Chaniru Sandive on 2025-01-XX.
//

import SwiftUI

struct SettingsTabView: View {
    var body: some View {
        VStack {
            Text("Settings Screen")
                .font(.largeTitle)
                .fontWeight(.bold)
        }
    }
}

#Preview {
    SettingsTabView()
        .environmentObject(AuthViewModel())
}
