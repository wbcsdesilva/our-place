//
//  CreateCategoryViewModel.swift
//  OurPlace
//
//  Created by Chaniru Sandive on 2025-08-19.
//

import SwiftUI
import CoreData

class CreateCategoryViewModel: ObservableObject {
    @Published var categoryName = ""
    @Published var categorySymbol = ""
    @Published var selectedColor: Color = .blue
    @Published var showEmojiError = false
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    private let coreDataManager = CoreDataManager.shared
    
    var isFormValid: Bool {
        !categoryName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        isValidSymbol(categorySymbol)
    }
    
    func createCategory() -> CategoryEntity? {
        guard isFormValid else { return nil }
        
        isLoading = true
        errorMessage = nil
        
        let category = CategoryEntity(
            context: coreDataManager.context,
            name: categoryName.trimmingCharacters(in: .whitespacesAndNewlines),
            symbol: categorySymbol.trimmingCharacters(in: .whitespacesAndNewlines),
            color: selectedColor
        )
        
        coreDataManager.save()
        
        // Reset form
        resetForm()
        
        isLoading = false
        return category
    }
    
    func validateSymbol(_ text: String) {
        showEmojiError = !isValidSymbol(text)
    }
    
    private func isValidSymbol(_ text: String) -> Bool {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return false }
        return trimmed.count == 1
    }
    
    private func resetForm() {
        categoryName = ""
        categorySymbol = ""
        selectedColor = .blue
        showEmojiError = false
        errorMessage = nil
    }
}
