//
//  CategoryEntity.swift
//  OurPlace
//
//  Created by Chaniru Sandive on 2025-08-19.
//

import Foundation
import CoreData
import SwiftUI

// MARK: - CategoryEntity Core Data Class

@objc(CategoryEntity)
public class CategoryEntity: NSManagedObject {
    
    // MARK: - Core Data Properties
    @NSManaged public var id: UUID
    @NSManaged public var name: String
    @NSManaged public var symbol: String
    @NSManaged public var red: Double
    @NSManaged public var green: Double
    @NSManaged public var blue: Double
    @NSManaged public var alpha: Double
    @NSManaged public var createdAt: Date
    
    // MARK: - Computed Properties
    
    /// SwiftUI Color computed from RGB components
    var color: Color {
        get {
            return Color(.sRGB, red: red, green: green, blue: blue, opacity: alpha)
        }
        set {
            let uiColor = UIColor(newValue)
            var r: CGFloat = 0
            var g: CGFloat = 0
            var b: CGFloat = 0
            var a: CGFloat = 0
            
            uiColor.getRed(&r, green: &g, blue: &b, alpha: &a)
            
            red = Double(r)
            green = Double(g)
            blue = Double(b)
            alpha = Double(a)
        }
    }
    
    /// Display text for dropdowns and lists
    var displayText: String {
        return "\(symbol) \(name)"
    }
    
    // MARK: - Convenience Initializer
    
    convenience init(context: NSManagedObjectContext, name: String, symbol: String, color: Color) {
        self.init(context: context)
        self.id = UUID()
        self.name = name
        self.symbol = symbol
        self.color = color // Uses the computed property setter
        self.createdAt = Date()
    }
    
    // MARK: - Fetch Methods
    
    @nonobjc public class func fetchRequest() -> NSFetchRequest<CategoryEntity> {
        return NSFetchRequest<CategoryEntity>(entityName: "CategoryEntity")
    }
    
    static func fetchAllCategories(context: NSManagedObjectContext) -> [CategoryEntity] {
        let request: NSFetchRequest<CategoryEntity> = CategoryEntity.fetchRequest()
        request.sortDescriptors = [NSSortDescriptor(keyPath: \CategoryEntity.createdAt, ascending: true)]
        
        do {
            return try context.fetch(request)
        } catch {
            print("Failed to fetch categories: \(error)")
            return []
        }
    }
}
