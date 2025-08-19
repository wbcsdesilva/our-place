//
//  CoreDataManager.swift
//  OurPlace
//
//  Created by Chaniru Sandive on 2025-08-19.
//

import CoreData
import Foundation
import SwiftUI

class CoreDataManager: ObservableObject {
    static let shared = CoreDataManager()
    
    lazy var persistentContainer: NSPersistentContainer = {
        let container = NSPersistentContainer(name: "OurPlaceModel")
        container.loadPersistentStores { _, error in
            if let error = error {
                fatalError("Core Data failed to load: \(error.localizedDescription)")
            }
        }
        return container
    }()
    
    var context: NSManagedObjectContext {
        persistentContainer.viewContext
    }
    
    func save() {
        if context.hasChanges {
            do {
                try context.save()
            } catch {
                print("Failed to save Core Data context: \(error)")
            }
        }
    }
    
    private init() {
        // Load default categories if none exist
        loadDefaultCategoriesIfNeeded()
    }
    
    private func loadDefaultCategoriesIfNeeded() {
        let request: NSFetchRequest<CategoryEntity> = CategoryEntity.fetchRequest()
        
        do {
            let count = try context.count(for: request)
            if count == 0 {
                createDefaultCategories()
            }
        } catch {
            print("Failed to count categories: \(error)")
        }
    }
    
    private func createDefaultCategories() {
        let defaultCategories: [(String, String, Color)] = [
            ("🍕", "Snacks", .orange),
            ("🍽️", "Restaurant", .red),
            ("☕", "Cafe", .brown),
            ("🏪", "Shop", .blue),
            ("🏥", "Medical", .green),
            ("⛽", "Gas Station", .gray),
            ("🏦", "Bank", .purple),
            ("🎬", "Entertainment", .pink),
            ("🏨", "Hotel", .teal),
            ("🚗", "Parking", .yellow)
        ]
        
        for (symbol, name, color) in defaultCategories {
            _ = CategoryEntity(context: context, name: name, symbol: symbol, color: color)
        }
        
        save()
    }
}