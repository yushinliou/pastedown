//
//  FrontMatterTemplate.swift
//  pastedown-v1
//
//  Created by Claude Code on 2025/9/15.
//

import SwiftUI

// MARK: - Front Matter Template Model
struct FrontMatterTemplate: Identifiable, Codable {
    var id = UUID()
    var name: String
    var fields: [FrontMatterField]
    var createdDate: Date
    var lastUsedDate: Date?

    init(name: String, fields: [FrontMatterField]) {
        self.name = name
        self.fields = fields
        self.createdDate = Date()
        self.lastUsedDate = nil
    }

    // Helper computed properties
    var fieldCount: Int {
        return fields.count
    }

    var fieldNames: [String] {
        return fields.map { $0.name }
    }

    var formattedCreatedDate: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return formatter.string(from: createdDate)
    }

    var formattedLastUsedDate: String? {
        guard let lastUsedDate = lastUsedDate else { return nil }
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return formatter.string(from: lastUsedDate)
    }

    // Update last used date
    mutating func markAsUsed() {
        self.lastUsedDate = Date()
    }

    // Create a copy with new name (for duplication)
    func duplicate(withName newName: String) -> FrontMatterTemplate {
        var newTemplate = FrontMatterTemplate(name: newName, fields: self.fields)
        // Create new IDs for fields to avoid conflicts
        newTemplate.fields = self.fields.map { field in
            var newField = field
            newField.id = UUID()
            return newField
        }
        return newTemplate
    }

    // Validation
    var isValid: Bool {
        return !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && !fields.isEmpty
    }
}