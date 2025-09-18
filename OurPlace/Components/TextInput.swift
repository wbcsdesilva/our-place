//
//  TextInput.swift
//  OurPlace
//
//  Created by Chaniru Sandive on 2025-09-18.
//

import SwiftUI

// MARK: - Text Input Component
struct TextInput: View {
    let title: String?
    let placeholder: String
    @Binding var text: String
    var keyboardType: UIKeyboardType = .default
    var autocapitalization: TextInputAutocapitalization = .sentences
    var isSecure: Bool = false
    var icon: String? = nil

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            if let title = title {
                Text(title)
                    .font(.headline)
                    .foregroundColor(.primary)
            }

            HStack(spacing: 12) {
                if let icon = icon {
                    Image(systemName: icon)
                        .foregroundColor(.secondary)
                        .font(.system(size: 16, weight: .medium))
                        .frame(width: 20)
                }

                Group {
                    if isSecure {
                        SecureField(placeholder, text: $text)
                    } else {
                        TextField(placeholder, text: $text)
                    }
                }
                .keyboardType(keyboardType)
                .textInputAutocapitalization(autocapitalization)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
            .background(.regularMaterial)
            .cornerRadius(12)
        }
    }
}

// MARK: - Text Area Input Component
struct TextAreaInput: View {
    let title: String?
    let placeholder: String
    @Binding var text: String
    var minHeight: CGFloat = 120

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            if let title = title {
                Text(title)
                    .font(.headline)
                    .foregroundColor(.primary)
            }

            TextEditor(text: $text)
                .font(.body)
                .padding(16)
                .scrollContentBackground(.hidden)
                .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 12))
                .frame(minHeight: minHeight)
                .overlay(
                    // Custom placeholder for TextEditor
                    Group {
                        if text.isEmpty {
                            Text(placeholder)
                                .foregroundColor(.secondary)
                                .font(.body)
                                .padding(.horizontal, 20)
                                .padding(.vertical, 20)
                                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
                                .allowsHitTesting(false)
                        }
                    }
                )
        }
    }
}

// MARK: - Styling Modifiers
extension View {
    func textInputStyle() -> some View {
        self
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
            .background(.regularMaterial)
            .cornerRadius(12)
    }

    func roundedBorderStyle() -> some View {
        self
            .textFieldStyle(.roundedBorder)
    }

    func plainTextStyle() -> some View {
        self
            .textFieldStyle(.plain)
    }
}

// MARK: - Preview
#Preview {
    ScrollView {
        VStack(spacing: 24) {
            // Regular text input with title
            TextInput(
                title: "Route Name",
                placeholder: "Enter route name",
                text: .constant("")
            )

            // Text input with icon
            TextInput(
                title: "Email",
                placeholder: "Enter your email",
                text: .constant(""),
                keyboardType: .emailAddress,
                autocapitalization: .never,
                icon: "envelope"
            )

            // Secure text input
            TextInput(
                title: "Password",
                placeholder: "Enter password",
                text: .constant(""),
                isSecure: true,
                icon: "lock"
            )

            // Text area input
            TextAreaInput(
                title: "Description",
                placeholder: "Enter detailed description here...",
                text: .constant("")
            )

            // Native TextField with custom styling
            VStack(alignment: .leading, spacing: 8) {
                Text("Custom Styled TextField")
                    .font(.headline)
                    .foregroundColor(.primary)

                TextField("Using modifier", text: .constant(""))
                    .textInputStyle()
            }
        }
        .padding()
    }
    .background(Color(.systemBackground))
}