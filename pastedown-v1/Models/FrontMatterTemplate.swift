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

// MARK: - Complete Template Model for All Settings
struct Template: Identifiable, Codable {
    var id = UUID()
    var name: String
    var createdDate: Date
    var lastUsedDate: Date?

    // All settings that can be saved in a template
    var frontMatterFields: [FrontMatterField]
    var enableFrontMatter: Bool
    var imageHandling: ImageHandling
    var imageFolderPath: String
    var enableAutoAlt: Bool
    var altTextTemplate: AltTextTemplate
    var apiKey: String
    var useExternalAPI: Bool
    var llmProvider: LLMProvider
    var customPrompt: String
    var fixedAltText: String
    var outputFilenameFormat: String

    init(name: String, settingsStore: SettingsStore) {
        self.name = name
        self.createdDate = Date()
        self.lastUsedDate = nil

        // Copy all settings from the settings store
        self.frontMatterFields = settingsStore.frontMatterFields
        self.enableFrontMatter = settingsStore.enableFrontMatter
        self.imageHandling = settingsStore.imageHandling
        self.imageFolderPath = settingsStore.imageFolderPath
        self.enableAutoAlt = settingsStore.enableAutoAlt
        self.altTextTemplate = settingsStore.altTextTemplate
        self.apiKey = settingsStore.apiKey
        self.useExternalAPI = settingsStore.useExternalAPI
        self.llmProvider = settingsStore.llmProvider
        self.customPrompt = settingsStore.customPrompt
        self.fixedAltText = settingsStore.fixedAltText
        self.outputFilenameFormat = settingsStore.outputFilenameFormat
    }

    // Helper computed properties
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
    func duplicate(withName newName: String) -> Template {
        var newTemplate = Template(name: newName, settingsStore: SettingsStore())
        newTemplate.frontMatterFields = self.frontMatterFields.map { field in
            var newField = field
            newField.id = UUID()
            return newField
        }
        newTemplate.enableFrontMatter = self.enableFrontMatter
        newTemplate.imageHandling = self.imageHandling
        newTemplate.imageFolderPath = self.imageFolderPath
        newTemplate.enableAutoAlt = self.enableAutoAlt
        newTemplate.altTextTemplate = self.altTextTemplate
        newTemplate.apiKey = self.apiKey
        newTemplate.useExternalAPI = self.useExternalAPI
        newTemplate.llmProvider = self.llmProvider
        newTemplate.customPrompt = self.customPrompt
        newTemplate.fixedAltText = self.fixedAltText
        newTemplate.outputFilenameFormat = self.outputFilenameFormat
        return newTemplate
    }

    // Validation
    var isValid: Bool {
        return !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    // Apply this template to a settings store
    func applyTo(settingsStore: SettingsStore) {
        settingsStore.frontMatterFields = self.frontMatterFields.map { field in
            var newField = field
            newField.id = UUID()
            return newField
        }
        settingsStore.enableFrontMatter = self.enableFrontMatter
        settingsStore.imageHandling = self.imageHandling
        settingsStore.imageFolderPath = self.imageFolderPath
        settingsStore.enableAutoAlt = self.enableAutoAlt
        settingsStore.altTextTemplate = self.altTextTemplate
        settingsStore.apiKey = self.apiKey
        settingsStore.useExternalAPI = self.useExternalAPI
        settingsStore.llmProvider = self.llmProvider
        settingsStore.customPrompt = self.customPrompt
        settingsStore.fixedAltText = self.fixedAltText
        settingsStore.outputFilenameFormat = self.outputFilenameFormat

        settingsStore.saveSettings()
    }
}