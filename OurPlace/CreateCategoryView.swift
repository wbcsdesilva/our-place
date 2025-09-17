//
//  CreateCategoryView.swift
//  OurPlace
//
//  Created by Chaniru Sandive on 2025-08-18.
//

import SwiftUI
import CoreData

struct CreateCategoryView: View {
    @StateObject private var viewModel = CreateCategoryViewModel()
    @Environment(\.dismiss) private var dismiss
    
    // Callback to notify when category is created
    let onCategoryCreated: ((NSManagedObjectID) -> Void)?

    init(onCategoryCreated: ((NSManagedObjectID) -> Void)? = nil) {
        self.onCategoryCreated = onCategoryCreated
    }
    
    var body: some View {
        VStack {
            ScrollView {
                VStack(spacing: 24) {
                    VStack(spacing: 16) {
                        // Category Name Field
                        CategoryNameField(text: $viewModel.categoryName)

                        // Category Symbol Field
                        VStack(alignment: .leading, spacing: 8) {
                            CategorySymbolFieldWithLabel(
                                text: $viewModel.categorySymbol,
                                showError: $viewModel.showEmojiError,
                                onTextChange: viewModel.validateSymbol
                            )

                            if viewModel.showEmojiError {
                                Text("Please enter exactly one character")
                                    .font(.caption)
                                    .foregroundColor(.red)
                                    .padding(.leading, 16)
                            }
                        }

                        // Color Picker Section
                        ColorPickerSection(
                            selectedColor: $viewModel.selectedColor
                        )

                        // Error Message
                        if let errorMessage = viewModel.errorMessage {
                            Text(errorMessage)
                                .font(.caption)
                                .foregroundColor(.red)
                                .padding(.horizontal, 16)
                        }
                    }

                    // Preview Section
                    PreviewSection(
                        name: viewModel.categoryName,
                        symbol: viewModel.categorySymbol,
                        color: viewModel.selectedColor
                    )
                }
                .padding(.horizontal, 20)
                .padding(.top, 16)
            }

            // Create Button - Fixed at bottom
            VStack {
                Divider()

                CustomButton(
                    title: "Create",
                    action: {
                        if let createdCategory = viewModel.createCategory() {
                            onCategoryCreated?(createdCategory.objectID)
                            dismiss()
                        }
                    },
                    isLoading: viewModel.isLoading,
                    backgroundColor: .blue
                )
                .disabled(!viewModel.isFormValid || viewModel.isLoading)
                .opacity(viewModel.isFormValid && !viewModel.isLoading ? 1.0 : 0.6)
                .padding(.horizontal, 20)
                .padding(.bottom, 34) // Safe area padding
            }
            .background(Color(.systemBackground))
        }
        .navigationTitle("Create category")
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden()
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button("Cancel") {
                    dismiss()
                }
                .foregroundColor(.blue)
            }
        }
    }
}

// MARK: - Category Name Field

struct CategoryNameField: View {
    @Binding var text: String
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "tag")
                .foregroundColor(.secondary)
                .font(.system(size: 14))
            
            VStack(alignment: .leading, spacing: 2) {
                Text("Category name")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                TextField("Enter category name", text: $text)
                    .font(.body)
                    .fontWeight(.medium)
                    .foregroundColor(.primary)
            }
            
            Spacer()
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(.regularMaterial)
        .cornerRadius(12)
    }
}

// MARK: - Category Symbol Field

struct CategorySymbolFieldWithLabel: View {
    @Binding var text: String
    @Binding var showError: Bool
    let onTextChange: (String) -> Void
    @FocusState private var isFocused: Bool
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "cube")
                .foregroundColor(.secondary)
                .font(.system(size: 14))
            
            VStack(alignment: .leading, spacing: 2) {
                Text("Category symbol")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                TextField("Enter a symbol or emoji", text: $text)
                    .font(.body)
                    .fontWeight(.medium)
                    .foregroundColor(.primary)
                    .focused($isFocused)
                    .onChange(of: text) { oldValue, newValue in
                        // Limit to 1 character only
                        if newValue.count > 1 {
                            text = String(newValue.prefix(1))
                        }
                        
                        // Call the validation callback
                        onTextChange(text)
                    }
            }
            
            Spacer()
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(.regularMaterial)
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(showError ? Color.red : Color.clear, lineWidth: 1)
        )
    }
}

// MARK: - Color Picker Section

struct ColorPickerSection: View {
    @Binding var selectedColor: Color
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "paintbrush")
                .foregroundColor(.secondary)
                .font(.system(size: 14))
            
            VStack(alignment: .leading, spacing: 2) {
                Text("Category color")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                HStack {
                    ColorPicker("", selection: $selectedColor)
                        .labelsHidden()
                    
                    Spacer()
                }
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(.regularMaterial)
        .cornerRadius(12)
    }
}

// MARK: - Preview Section

struct PreviewSection: View {
    let name: String
    let symbol: String
    let color: Color
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Preview:")
                .font(.headline)
                .foregroundColor(.primary)
            
            if !name.isEmpty || !symbol.isEmpty {
                HStack {
                    Text("\(symbol) \(name)")
                        .font(.subheadline)
                        .foregroundColor(.primary)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 6)
                        .background(color)
                        .cornerRadius(6)
                    
                    Spacer()
                }
            } else {
                Text("Enter a name and symbol to see preview")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .italic()
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(.regularMaterial)
        .cornerRadius(12)
    }
}

#Preview {
    CreateCategoryView()
}