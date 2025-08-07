//
//  PasswordStrengthView.swift
//  OurPlace
//
//  Created by Chaniru Sandive on 2025-08-06.
//

import SwiftUI

struct PasswordStrengthView: View {
    let password: String
    
    private var strengthLevel: PasswordStrength {
        if password.isEmpty {
            return .none
        } else if password.count < 6 {
            return .weak
        } else if password.count < 8 {
            return .medium
        } else {
            return .strong
        }
    }
    
    private var strengthColor: Color {
        switch strengthLevel {
        case .none:
            return .gray
        case .weak:
            return .red
        case .medium:
            return .orange
        case .strong:
            return .green
        }
    }
    
    private var strengthText: String {
        switch strengthLevel {
        case .none:
            return ""
        case .weak:
            return "Weak"
        case .medium:
            return "Medium"
        case .strong:
            return "Strong"
        }
    }
    
    var body: some View {
        if !password.isEmpty {
            HStack {
                Text("Password strength:")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Text(strengthText)
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundColor(strengthColor)
                
                Spacer()
            }
            .padding(.horizontal, 20)
        }
    }
}

enum PasswordStrength {
    case none
    case weak
    case medium
    case strong
}

#Preview {
    VStack {
        PasswordStrengthView(password: "")
        PasswordStrengthView(password: "123")
        PasswordStrengthView(password: "123456")
        PasswordStrengthView(password: "12345678")
    }
    .padding()
}
