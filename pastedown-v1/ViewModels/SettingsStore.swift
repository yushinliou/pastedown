//
//  SettingsStore.swift
//  pastedown-v1
//
//  Created by 劉羽芯 on 2025/6/30.
//

import SwiftUI

// MARK: - LLM Provider
enum LLMProvider: String, CaseIterable, Identifiable, Codable {
    case openai = "openai"
    case anthropic = "anthropic"
    case custom = "custom"
    
    var id: String { rawValue }
    
    var displayName: String {
        switch self {
        case .openai:
            return "OpenAI (GPT-4o)"
        case .anthropic:
            return "Anthropic (Claude)"
        case .custom:
            return "Custom API"
        }
    }
    
    var apiEndpoint: String {
        switch self {
        case .openai:
            return "https://api.openai.com/v1/chat/completions"
        case .anthropic:
            return "https://api.anthropic.com/v1/messages"
        case .custom:
            return "" // User-provided
        }
    }
    
    var supportedModels: [String] {
        switch self {
        case .openai:
            return ["gpt-4o", "gpt-4o-mini", "gpt-4-turbo"]
        case .anthropic:
            return ["claude-3-5-sonnet-20240620", "claude-3-haiku-20240307"]
        case .custom:
            return []
        }
    }
    
    var defaultModel: String {
        switch self {
        case .openai:
            return "gpt-4o"
        case .anthropic:
            return "claude-3-5-sonnet-20240620"
        case .custom:
            return ""
        }
    }
}

// MARK: - Settings Store
class SettingsStore: ObservableObject {
    @Published var frontMatterFields: [FrontMatterField] = []
    @Published var enableFrontMatter: Bool = true
    @Published var savedTemplates: [FrontMatterTemplate] = []
    @Published var templates: [Template] = []
    @Published var currentTemplateID: UUID?
    @Published var imageHandling: ImageHandling = .ignore
    @Published var imageFolderPath: String = "./images"
    @Published var enableAutoAlt: Bool = true
    @Published var altTextTemplate: AltTextTemplate = .imageOf
    @Published var apiKey: String = ""
    @Published var useExternalAPI: Bool = false
    @Published var llmProvider: LLMProvider = .openai
    @Published var customPrompt: String = ""
    @Published var outputFilenameFormat: String = "note_{date}_{clipboard_preview}"
    
    init() {
        loadSettings()
        ensureDefaultTemplate()
    }
    
    private func loadSettings() {
        if let data = UserDefaults.standard.data(forKey: "frontMatterFields"),
           let fields = try? JSONDecoder().decode([FrontMatterField].self, from: data) {
            frontMatterFields = fields
        }

        if let templatesData = UserDefaults.standard.data(forKey: "frontMatterTemplates"),
           let templates = try? JSONDecoder().decode([FrontMatterTemplate].self, from: templatesData) {
            savedTemplates = templates
        }

        if let templatesData = UserDefaults.standard.data(forKey: "templates"),
           let templates = try? JSONDecoder().decode([Template].self, from: templatesData) {
            self.templates = templates
        }

        if let templateIDString = UserDefaults.standard.string(forKey: "currentTemplateID"),
           let templateID = UUID(uuidString: templateIDString) {
            currentTemplateID = templateID
        }
        
        if let imageHandlingRaw = UserDefaults.standard.string(forKey: "imageHandling"),
           let handling = ImageHandling(rawValue: imageHandlingRaw) {
            imageHandling = handling
        }
        
        imageFolderPath = UserDefaults.standard.string(forKey: "imageFolderPath") ?? "./images"
        enableFrontMatter = UserDefaults.standard.object(forKey: "enableFrontMatter") != nil ? UserDefaults.standard.bool(forKey: "enableFrontMatter") : true
        enableAutoAlt = UserDefaults.standard.bool(forKey: "enableAutoAlt")
        
        if let templateRaw = UserDefaults.standard.string(forKey: "altTextTemplate"),
           let template = AltTextTemplate(rawValue: templateRaw) {
            altTextTemplate = template
        }
        
        apiKey = UserDefaults.standard.string(forKey: "apiKey") ?? ""
        useExternalAPI = UserDefaults.standard.bool(forKey: "useExternalAPI")
        
        if let providerRaw = UserDefaults.standard.string(forKey: "llmProvider"),
           let provider = LLMProvider(rawValue: providerRaw) {
            llmProvider = provider
        }
        
        customPrompt = UserDefaults.standard.string(forKey: "customPrompt") ?? ""
        outputFilenameFormat = UserDefaults.standard.string(forKey: "outputFilenameFormat") ?? "note_{date}_{clipboard_preview}"
    }
    
    func saveSettings() {
        // Save to UserDefaults (for backwards compatibility)
        if let data = try? JSONEncoder().encode(frontMatterFields) {
            UserDefaults.standard.set(data, forKey: "frontMatterFields")
        }

        if let templatesData = try? JSONEncoder().encode(savedTemplates) {
            UserDefaults.standard.set(templatesData, forKey: "frontMatterTemplates")
        }

        if let templatesData = try? JSONEncoder().encode(templates) {
            UserDefaults.standard.set(templatesData, forKey: "templates")
        }

        if let currentTemplateID = currentTemplateID {
            UserDefaults.standard.set(currentTemplateID.uuidString, forKey: "currentTemplateID")
        } else {
            UserDefaults.standard.removeObject(forKey: "currentTemplateID")
        }
        
        UserDefaults.standard.set(imageHandling.rawValue, forKey: "imageHandling")
        UserDefaults.standard.set(imageFolderPath, forKey: "imageFolderPath")
        UserDefaults.standard.set(enableFrontMatter, forKey: "enableFrontMatter")
        UserDefaults.standard.set(enableAutoAlt, forKey: "enableAutoAlt")
        UserDefaults.standard.set(altTextTemplate.rawValue, forKey: "altTextTemplate")
        UserDefaults.standard.set(apiKey, forKey: "apiKey")
        UserDefaults.standard.set(useExternalAPI, forKey: "useExternalAPI")
        UserDefaults.standard.set(llmProvider.rawValue, forKey: "llmProvider")
        UserDefaults.standard.set(customPrompt, forKey: "customPrompt")
        UserDefaults.standard.set(outputFilenameFormat, forKey: "outputFilenameFormat")
        
        // Also save to shared container for Share Extension
        saveToSharedContainer()
    }
    
    private func saveToSharedContainer() {
        guard let sharedContainer = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: "group.Yu-shin.pastedown") else {
            print("Could not access shared container")
            return
        }
        
        let settingsURL = sharedContainer.appendingPathComponent("SharedSettings.plist")
        
        var plist: [String: Any] = [:]
        
        // Serialize front matter fields
        if let frontMatterData = try? JSONEncoder().encode(frontMatterFields) {
            plist["frontMatterFields"] = frontMatterData
        }

        // Serialize saved templates
        if let templatesData = try? JSONEncoder().encode(savedTemplates) {
            plist["frontMatterTemplates"] = templatesData
        }

        // Serialize new templates
        if let templatesData = try? JSONEncoder().encode(templates) {
            plist["templates"] = templatesData
        }

        if let currentTemplateID = currentTemplateID {
            plist["currentTemplateID"] = currentTemplateID.uuidString
        }
        
        plist["imageHandling"] = imageHandling.rawValue
        plist["imageFolderPath"] = imageFolderPath
        plist["enableAutoAlt"] = enableAutoAlt
        plist["altTextTemplate"] = altTextTemplate.rawValue
        plist["apiKey"] = apiKey
        plist["useExternalAPI"] = useExternalAPI
        plist["llmProvider"] = llmProvider.rawValue
        plist["customPrompt"] = customPrompt
        plist["outputFilenameFormat"] = outputFilenameFormat
        
        do {
            let data = try PropertyListSerialization.data(fromPropertyList: plist, format: .xml, options: 0)
            try data.write(to: settingsURL)
        } catch {
            print("Error saving settings to shared container: \(error)")
        }
    }

    // MARK: - Template Management
    func saveCurrentAsTemplate(name: String) -> Bool {
        guard !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
              !frontMatterFields.isEmpty else {
            return false
        }

        // Check for duplicate names
        if savedTemplates.contains(where: { $0.name == name }) {
            return false
        }

        let newTemplate = FrontMatterTemplate(name: name, fields: frontMatterFields)
        savedTemplates.append(newTemplate)
        saveSettings()
        return true
    }

    func applyTemplate(_ template: FrontMatterTemplate) {
        var updatedTemplate = template
        updatedTemplate.markAsUsed()

        // Update the template in the saved list
        if let index = savedTemplates.firstIndex(where: { $0.id == template.id }) {
            savedTemplates[index] = updatedTemplate
        }

        // Replace current fields with template fields (with new IDs to avoid conflicts)
        frontMatterFields = template.fields.map { field in
            var newField = field
            newField.id = UUID()
            return newField
        }

        saveSettings()
    }

    func deleteTemplate(_ template: FrontMatterTemplate) {
        savedTemplates.removeAll { $0.id == template.id }
        saveSettings()
    }

    func duplicateTemplate(_ template: FrontMatterTemplate, newName: String) -> Bool {
        guard !newName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            return false
        }

        // Check for duplicate names
        if savedTemplates.contains(where: { $0.name == newName }) {
            return false
        }

        let duplicatedTemplate = template.duplicate(withName: newName)
        savedTemplates.append(duplicatedTemplate)
        saveSettings()
        return true
    }

    func renameTemplate(_ template: FrontMatterTemplate, newName: String) -> Bool {
        guard !newName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            return false
        }

        // Check for duplicate names (excluding current template)
        if savedTemplates.contains(where: { $0.name == newName && $0.id != template.id }) {
            return false
        }

        if let index = savedTemplates.firstIndex(where: { $0.id == template.id }) {
            savedTemplates[index].name = newName
            saveSettings()
            return true
        }
        return false
    }

    func isTemplateNameAvailable(_ name: String) -> Bool {
        let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        return !trimmedName.isEmpty && !savedTemplates.contains(where: { $0.name == trimmedName })
    }

    // MARK: - New Template Management Methods
    private func ensureDefaultTemplate() {
        if templates.isEmpty {
            let defaultTemplate = Template(name: "default", settingsStore: self)
            templates.append(defaultTemplate)
            currentTemplateID = defaultTemplate.id
            saveSettings()
        }
    }

    func createTemplate(name: String) -> Bool {
        guard !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            return false
        }

        if templates.contains(where: { $0.name == name }) {
            return false
        }

        let newTemplate = Template(name: name, settingsStore: self)
        templates.append(newTemplate)
        saveSettings()
        return true
    }

    func applyTemplate(_ template: Template) {
        var updatedTemplate = template
        updatedTemplate.markAsUsed()

        if let index = templates.firstIndex(where: { $0.id == template.id }) {
            templates[index] = updatedTemplate
        }

        updatedTemplate.applyTo(settingsStore: self)
        currentTemplateID = template.id
    }

    func deleteTemplate(_ template: Template) {
        guard template.name != "default" else { return }

        templates.removeAll { $0.id == template.id }

        if currentTemplateID == template.id {
            currentTemplateID = templates.first(where: { $0.name == "default" })?.id
        }

        saveSettings()
    }

    func duplicateTemplate(_ template: Template, newName: String) -> Bool {
        guard !newName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            return false
        }

        if templates.contains(where: { $0.name == newName }) {
            return false
        }

        let duplicatedTemplate = template.duplicate(withName: newName)
        templates.append(duplicatedTemplate)
        saveSettings()
        return true
    }

    func renameTemplate(_ template: Template, newName: String) -> Bool {
        guard !newName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            return false
        }

        guard template.name != "default" else { return false }

        if templates.contains(where: { $0.name == newName && $0.id != template.id }) {
            return false
        }

        if let index = templates.firstIndex(where: { $0.id == template.id }) {
            templates[index].name = newName
            saveSettings()
            return true
        }
        return false
    }

    func isTemplateNameValid(_ name: String) -> Bool {
        let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        return !trimmedName.isEmpty && !templates.contains(where: { $0.name == trimmedName })
    }


    var currentTemplate: Template? {
        guard let currentTemplateID = currentTemplateID else { return nil }
        return templates.first(where: { $0.id == currentTemplateID })
    }

    // MARK: - Image Path Processing
    func processImageFolderPath(imageIndex: Int = 1, contentPreview: String = "", fileExtension: String = "png") -> String {
        var processedPath = imageFolderPath.trimmingCharacters(in: .whitespacesAndNewlines)
        
        let currentDate = Date()
        let formatter = DateFormatter()
        
        // Replace built-in variables with actual values
        formatter.dateFormat = "yyyy-MM-dd"
        processedPath = processedPath.replacingOccurrences(of: "{date}", with: formatter.string(from: currentDate))
        
        formatter.dateFormat = "yyyy-MM-dd_HH-mm-ss"
        processedPath = processedPath.replacingOccurrences(of: "{time}", with: formatter.string(from: currentDate))
        
        // Use clipboard preview (first 20 chars, cleaned)
        let clipboardPreview = contentPreview.isEmpty ? "clipboard" : String(contentPreview.prefix(20))
            .replacingOccurrences(of: " ", with: "-")
            .replacingOccurrences(of: "\n", with: "")
            .lowercased()
        processedPath = processedPath.replacingOccurrences(of: "{clipboard_preview}", with: clipboardPreview)
        
        // Process front matter field variables
        processedPath = processFrontMatterVariables(in: processedPath, sanitizeForPath: true)
        
        // Ensure path ends with / if it doesn't already
        if !processedPath.isEmpty && !processedPath.hasSuffix("/") {
            processedPath += "/"
        }
        
        // Generate image filename with proper extension (image1.jpg, image2.png, etc.) and append to path
        let imageFileName = "image\(imageIndex).\(fileExtension)"
        processedPath += imageFileName

        return processedPath
    }
    
    // MARK: - Path Validation
    func isValidImagePath() -> Bool {
        let path = imageFolderPath.trimmingCharacters(in: .whitespacesAndNewlines)

        // Allow empty paths - user may want to save to current directory
        if path.isEmpty {
            return true
        }

        // Check for NULL and /0 characters
        if path.contains("\0") || path.contains("NULL") {
            return false
        }
        
        // Check for invalid characters in file paths (removed < and > since user won't use placeholders)
        let invalidChars = CharacterSet(charactersIn: ":\"|?*")
        if path.rangeOfCharacter(from: invalidChars) != nil {
            return false
        }
        
        // Basic path format validation - should not end with a file extension
        let imageExtensions = [".png", ".jpg", ".jpeg", ".gif", ".tiff", ".tif", ".jp2", ".webp", ".heic", ".heif", ".exr"]
        for ext in imageExtensions {
            if path.hasSuffix(ext) {
                return false
            }
        }
        
        return true
    }
    
    // MARK: - Filename Processing
    func generateOutputFilename(contentPreview: String = "") -> String {
        var filename = outputFilenameFormat
        
        let currentDate = Date()
        let formatter = DateFormatter()
        
        // Replace built-in date variables
        formatter.dateFormat = "yyyy-MM-dd"
        filename = filename.replacingOccurrences(of: "{date}", with: formatter.string(from: currentDate))
        
        formatter.dateFormat = "yyyy-MM-dd_HH-mm-ss" 
        filename = filename.replacingOccurrences(of: "{time}", with: formatter.string(from: currentDate))
        
        // Use clipboard preview (first 20 chars, cleaned)
        let clipboardPreview = contentPreview.isEmpty ? "clipboard" : String(contentPreview.prefix(20))
            .replacingOccurrences(of: " ", with: "-")
            .replacingOccurrences(of: "\n", with: "")
            .lowercased()
        filename = filename.replacingOccurrences(of: "{clipboard_preview}", with: clipboardPreview)
        
        // Process front matter field variables
        filename = processFrontMatterVariables(in: filename, sanitizeForPath: true)
        
        return filename
    }
    
    // MARK: - Filename Validation
    func isValidOutputFilename() -> Bool {
        let filename = outputFilenameFormat.trimmingCharacters(in: .whitespacesAndNewlines)
        
        // Check if filename is empty
        if filename.isEmpty {
            return false
        }
        
        // Check for just a period or periods with spaces
        if filename == "." || filename == ".." {
            return false
        }
        
        // Check if filename would result in empty name (like '.md', ' .md', '\.md')
        let testGenerated = generateOutputFilename(contentPreview: "test")
        let testGeneratedTrimmed = testGenerated.trimmingCharacters(in: .whitespacesAndNewlines)
        
        // Check if generated filename is effectively empty or starts with just a dot
        if testGeneratedTrimmed.isEmpty || 
           testGeneratedTrimmed == "." || 
           testGeneratedTrimmed == ".." ||
           testGeneratedTrimmed.hasPrefix(".") && testGeneratedTrimmed.count <= 4 { // catches '.md', '\.md' etc.
            return false
        }
        
        // Check for invalid characters in filenames
        let invalidChars = CharacterSet(charactersIn: "<>:\"/|?*")
        if filename.rangeOfCharacter(from: invalidChars) != nil {
            return false
        }
        
        // Check for control characters
        if filename.rangeOfCharacter(from: CharacterSet.controlCharacters) != nil {
            return false
        }
        
        // Check if filename starts or ends with whitespace after variable substitution
        if testGenerated != testGeneratedTrimmed {
            return false
        }
        
        // Check for backslashes (escaped characters)
        if filename.contains("\\") {
            return false
        }
        
        return true
    }
    
    // MARK: - Final Filename Generation with .md Extension
    func generateFinalOutputFilename(contentPreview: String = "") -> String {
        var filename = generateOutputFilename(contentPreview: contentPreview)
        
        // Auto-append .md extension if not present
        if !filename.hasSuffix(".md") {
            filename += ".md"
        }
        
        return filename
    }
    
    // MARK: - Preview Generation
    func generateImagePathPreview() -> String {
        let clipboardPreview = getClipboardPreviewForDemo()
        let imagePath = processImageFolderPath(imageIndex: 1, contentPreview: clipboardPreview)
        return "![alt](\(imagePath))"
    }
    
    func generateImageHandlingPreview() -> String {
        switch imageHandling {
        case .ignore:
            return "<!-- Image ignored -->"
        case .base64:
            return "![alt](data:image/png;base64,yourbase64string)"
        case .saveToFolder:
            let clipboardPreview = getClipboardPreviewForDemo()
            let imagePath = processImageFolderPath(imageIndex: 1, contentPreview: clipboardPreview)
            return "![alt](\(imagePath))"
        }
    }
    
    func generateOutputFilenamePreview() -> String {
        let clipboardPreview = getClipboardPreviewForDemo()
        return generateFinalOutputFilename(contentPreview: clipboardPreview)
    }
    
    private func getClipboardPreviewForDemo() -> String {
        return "example preview"
    }
    
    // MARK: - Front Matter Variable Processing
    private func processFrontMatterVariables(in text: String, sanitizeForPath: Bool = false) -> String {
        var processedText = text
        
        // Process each front matter field variable
        for field in frontMatterFields {
            let placeholder = "{\(field.name)}"
            if processedText.contains(placeholder) {
                var fieldValue = getProcessedFieldValue(field)
                
                // Sanitize for file paths if needed
                if sanitizeForPath {
                    fieldValue = sanitizeForFilePath(fieldValue)
                }
                
                processedText = processedText.replacingOccurrences(of: placeholder, with: fieldValue)
            }
        }
        
        return processedText
    }
    
    private func getProcessedFieldValue(_ field: FrontMatterField) -> String {
        // Use the same logic as MarkdownUtilities for consistency
        switch field.type {
        case .current_date:
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "yyyy-MM-dd"
            return dateFormatter.string(from: Date())
        case .current_datetime:
            let dateTimeFormatter = DateFormatter()
            dateTimeFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss"
            return dateTimeFormatter.string(from: Date())
        case .tag, .list:
            // For paths, use comma-separated format instead of YAML
            let items = parseArrayField(field.value)
            return items.joined(separator: ", ")
        default:
            // Process any variables within this field's value
            var value = field.value
            
            // Process built-in date/time variables
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "yyyy-MM-dd"
            let currentDate = dateFormatter.string(from: Date())
            
            let timeFormatter = DateFormatter()
            timeFormatter.dateFormat = "HH:mm:ss"
            let currentTime = timeFormatter.string(from: Date())
            
            value = value.replacingOccurrences(of: "{current_date}", with: currentDate)
            value = value.replacingOccurrences(of: "{current_time}", with: currentTime)
            
            // For simplicity, avoid recursive field references in paths to prevent complexity
            // Could be enhanced later if needed
            
            return value
        }
    }
    
    private func parseArrayField(_ value: String) -> [String] {
        // First try to parse as JSON array (same logic as MarkdownUtilities)
        if let jsonData = value.data(using: .utf8),
           let items = try? JSONDecoder().decode([String].self, from: jsonData) {
            return items.filter { !$0.isEmpty }
        }
        
        // Fallback to comma-separated format
        if !value.isEmpty {
            return value.components(separatedBy: ",")
                .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
                .filter { !$0.isEmpty }
        }
        
        return []
    }
    
    private func sanitizeForFilePath(_ text: String) -> String {
        return text
            .replacingOccurrences(of: " ", with: "-")
            .replacingOccurrences(of: "\n", with: "-")
            .replacingOccurrences(of: "\t", with: "-")
            .replacingOccurrences(of: "/", with: "-")
            .replacingOccurrences(of: "\\", with: "-")
            .replacingOccurrences(of: ":", with: "-")
            .replacingOccurrences(of: "*", with: "-")
            .replacingOccurrences(of: "?", with: "-")
            .replacingOccurrences(of: "\"", with: "-")
            .replacingOccurrences(of: "<", with: "-")
            .replacingOccurrences(of: ">", with: "-")
            .replacingOccurrences(of: "|", with: "-")
            .lowercased()
    }
}
