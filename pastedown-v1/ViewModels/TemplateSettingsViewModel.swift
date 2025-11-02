//
//  TemplateSettingsViewModel.swift
//  pastedown-v1
//
//  Created by extracting logic from TemplateSettingsView
//

import SwiftUI

@MainActor
class TemplateSettingsViewModel: ObservableObject {
    // Settings reference
    let settings: SettingsStore
    let template: Template?
    let isEditing: Bool

    // Template configuration
    @Published var templateName: String = ""
    @Published var outputFilenameFormat: String = ""
    @Published var imageHandling: ImageHandling = .ignore
    @Published var imageFolderPath: String = ""
    @Published var enableAutoAlt: Bool = true
    @Published var altTextTemplate: AltTextTemplate = .imageOf
    @Published var useExternalAPI: Bool = false
    @Published var apiKey: String = ""
    @Published var llmProvider: LLMProvider = .openai
    @Published var customPrompt: String = ""
    @Published var fixedAltText: String = "alt"
    @Published var frontMatterFields: [FrontMatterField] = []
    @Published var enableFrontMatter: Bool = true
    @Published var isEditingFields = false

    // Alert handling
    @Published var showingAlert = false
    @Published var alertMessage = ""

    // Cached settings for preview generation
    @Published var cachedSettings = SettingsStore()

    init(settings: SettingsStore, template: Template? = nil) {
        self.settings = settings
        self.template = template
        self.isEditing = template != nil
    }

    // MARK: - Data Loading

    func loadTemplateData() {
        if let template = template {
            templateName = template.name
            outputFilenameFormat = template.outputFilenameFormat
            imageHandling = template.imageHandling
            imageFolderPath = template.imageFolderPath
            enableAutoAlt = template.enableAutoAlt
            altTextTemplate = template.altTextTemplate
            useExternalAPI = template.useExternalAPI
            apiKey = template.apiKey
            llmProvider = template.llmProvider
            customPrompt = template.customPrompt
            fixedAltText = template.fixedAltText
            frontMatterFields = template.frontMatterFields
            enableFrontMatter = template.enableFrontMatter
        } else {
            templateName = generateUniqueTemplateName()
            outputFilenameFormat = settings.outputFilenameFormat
            imageHandling = settings.imageHandling
            imageFolderPath = settings.imageFolderPath
            enableAutoAlt = settings.enableAutoAlt
            altTextTemplate = settings.altTextTemplate
            useExternalAPI = settings.useExternalAPI
            apiKey = settings.apiKey
            llmProvider = settings.llmProvider
            customPrompt = settings.customPrompt
            fixedAltText = settings.fixedAltText
            frontMatterFields = settings.frontMatterFields
            enableFrontMatter = settings.enableFrontMatter
        }
    }

    // MARK: - Validation

    func canSave() -> Bool {
        let trimmedName = templateName.trimmingCharacters(in: .whitespacesAndNewlines)

        // Check if template name is empty for new templates
        if !isEditing && trimmedName.isEmpty {
            return false
        }

        // Check for duplicate names when creating new template
        if !isEditing && !settings.isTemplateNameValid(trimmedName) {
            return false
        }

        // Check for duplicate names when editing template name
        if isEditing, let existingTemplate = template,
           existingTemplate.name != "default" && trimmedName != existingTemplate.name {
            if !settings.isTemplateNameValid(trimmedName) {
                return false
            }
        }

        // Validate API key if using external API
        if useExternalAPI && !isValidAPIKey() {
            return false
        }

        return isValidOutputFilename() && isValidImagePath()
    }

    func isValidTemplateName() -> Bool {
        let trimmedName = templateName.trimmingCharacters(in: .whitespacesAndNewlines)

        // Empty name is invalid for new templates
        if !isEditing && trimmedName.isEmpty {
            return false
        }

        // Check for duplicate names when creating new template
        if !isEditing {
            return settings.isTemplateNameValid(trimmedName)
        }

        // For editing, only validate if name changed and not default template
        if let existingTemplate = template {
            if existingTemplate.name == "default" || trimmedName == existingTemplate.name {
                return true
            }
            return settings.isTemplateNameValid(trimmedName)
        }

        return true
    }

    func getTemplateNameError() -> String? {
        let trimmedName = templateName.trimmingCharacters(in: .whitespacesAndNewlines)

        // Empty name error
        if !isEditing && trimmedName.isEmpty {
            return "Please enter a template name"
        }

        // Duplicate name error for new template
        if !isEditing && !settings.isTemplateNameValid(trimmedName) {
            return "A template with this name already exists"
        }

        // Duplicate name error when editing
        if isEditing, let existingTemplate = template {
            if existingTemplate.name != "default" && trimmedName != existingTemplate.name {
                if !settings.isTemplateNameValid(trimmedName) {
                    return "A template with this name already exists"
                }
            }
        }

        return nil
    }

    func isValidOutputFilename() -> Bool {
        let filename = outputFilenameFormat.trimmingCharacters(in: .whitespacesAndNewlines)

        if filename.isEmpty {
            return false
        }

        let invalidChars = CharacterSet(charactersIn: "<>:\"/|?*")
        if filename.rangeOfCharacter(from: invalidChars) != nil {
            return false
        }

        return true
    }

    func isValidImagePath() -> Bool {
        if imageHandling != .saveToFolder {
            return true
        }

        let path = imageFolderPath.trimmingCharacters(in: .whitespacesAndNewlines)

        if path.isEmpty {
            return true
        }

        if path.contains("\0") || path.contains("NULL") {
            return false
        }

        let invalidChars = CharacterSet(charactersIn: ":\"|?*")
        if path.rangeOfCharacter(from: invalidChars) != nil {
            return false
        }

        return true
    }

    func isValidAPIKey() -> Bool {
        if useExternalAPI {
            return !apiKey.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        }
        return true
    }

    // MARK: - Save Template

    func saveTemplate(onDismiss: @escaping () -> Void) {
        let trimmedName = templateName.trimmingCharacters(in: .whitespacesAndNewlines)

        if !isEditing {
            if trimmedName.isEmpty {
                alertMessage = "Please enter a template name"
                showingAlert = true
                return
            }

            if !settings.isTemplateNameValid(trimmedName) {
                alertMessage = "Template name already exists"
                showingAlert = true
                return
            }
        }

        // Create or update template with current form values
        if isEditing, let existingTemplate = template {
            var updatedTemplate = existingTemplate

            // Update name if it's not the default template and name has changed
            if existingTemplate.name != "default" && trimmedName != existingTemplate.name {
                if !settings.isTemplateNameValid(trimmedName) {
                    alertMessage = "Template name already exists"
                    showingAlert = true
                    return
                }
                updatedTemplate.name = trimmedName
            }

            updatedTemplate.outputFilenameFormat = outputFilenameFormat
            updatedTemplate.imageHandling = imageHandling
            updatedTemplate.imageFolderPath = imageFolderPath
            updatedTemplate.enableAutoAlt = enableAutoAlt
            updatedTemplate.altTextTemplate = altTextTemplate
            updatedTemplate.useExternalAPI = useExternalAPI
            updatedTemplate.apiKey = apiKey
            updatedTemplate.llmProvider = llmProvider
            updatedTemplate.customPrompt = customPrompt
            updatedTemplate.fixedAltText = fixedAltText
            updatedTemplate.frontMatterFields = frontMatterFields
            updatedTemplate.enableFrontMatter = enableFrontMatter

            if let index = settings.templates.firstIndex(where: { $0.id == existingTemplate.id }) {
                settings.templates[index] = updatedTemplate
                // Apply the updated template to current settings if it's the active template
                if settings.currentTemplateID == existingTemplate.id {
                    settings.applyTemplate(updatedTemplate)
                } else {
                    settings.saveSettings()
                }
                onDismiss()
            }
        } else {
            // Create new template
            var newTemplate = Template(name: trimmedName, settingsStore: settings)
            newTemplate.outputFilenameFormat = outputFilenameFormat
            newTemplate.imageHandling = imageHandling
            newTemplate.imageFolderPath = imageFolderPath
            newTemplate.enableAutoAlt = enableAutoAlt
            newTemplate.altTextTemplate = altTextTemplate
            newTemplate.useExternalAPI = useExternalAPI
            newTemplate.apiKey = apiKey
            newTemplate.llmProvider = llmProvider
            newTemplate.customPrompt = customPrompt
            newTemplate.fixedAltText = fixedAltText
            newTemplate.frontMatterFields = frontMatterFields
            newTemplate.enableFrontMatter = enableFrontMatter

            settings.templates.append(newTemplate)
            // Automatically apply the new template as the current template
            settings.applyTemplate(newTemplate)
            onDismiss()
        }
    }

    // MARK: - Preview Generation

    func generateFilenamePreview() -> String {
        // Create a temporary settings store with the current values
        let tempSettings = SettingsStore()
        tempSettings.outputFilenameFormat = outputFilenameFormat
        tempSettings.frontMatterFields = frontMatterFields

        return tempSettings.generateFinalOutputFilename(contentPreview: "example preview")
    }

    func generateImagePathPreview() -> String {
        // Create a temporary settings store with the current values
        let tempSettings = SettingsStore()
        tempSettings.imageFolderPath = imageFolderPath

        let processedPath = tempSettings.processImageFolderPath(
            imageIndex: 1,
            contentPreview: "example-preview",
            fileExtension: "png"
        )

        return "![\(enableAutoAlt ? altTextTemplate.displayName : "alt")](\(processedPath))"
    }

    func generateImageHandlingPreview() -> String {
        switch imageHandling {
        case .ignore:
            return "<!-- Image ignored -->"
        case .base64:
            return "![alt text](data:image/png;base64,iVBAANSUhA...)" 
        case .saveToFolder:
            return "![alt](/path/to/image.png)"
        }
    }

    // MARK: - Front Matter Management

    func moveFields(from source: IndexSet, to destination: Int) {
        frontMatterFields.move(fromOffsets: source, toOffset: destination)
    }

    func deleteFields(offsets: IndexSet) {
        frontMatterFields.remove(atOffsets: offsets)
    }

    func updateCachedSettings() {
        cachedSettings.frontMatterFields = frontMatterFields
    }

    // MARK: - Helper Methods

    private func generateUniqueTemplateName() -> String {
        var baseName = ""
        var counter = 1

        // If "New Template" is available, use it
        if settings.isTemplateNameValid(baseName) {
            return baseName
        }

        // Otherwise, find "New Template 2", "New Template 3", etc.
        while !settings.isTemplateNameValid("\(baseName) \(counter)") {
            counter += 1
        }

        return "\(baseName) \(counter)"
    }
}
