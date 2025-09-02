//
//  SettingsStore.swift
//  pastedown-v1
//
//  Created by 劉羽芯 on 2025/6/30.
//

import SwiftUI

// MARK: - Settings Store
class SettingsStore: ObservableObject {
    @Published var frontMatterFields: [FrontMatterField] = []
    @Published var imageHandling: ImageHandling = .ignore
    @Published var imageFolderPath: String = "./images"
    @Published var enableAutoAlt: Bool = true
    @Published var altTextTemplate: AltTextTemplate = .imageOf
    @Published var apiKey: String = ""
    @Published var useExternalAPI: Bool = false
    @Published var outputFilenameFormat: String = "note_{date}_{clipboard_preview}"
    
    init() {
        loadSettings()
    }
    
    private func loadSettings() {
        if let data = UserDefaults.standard.data(forKey: "frontMatterFields"),
           let fields = try? JSONDecoder().decode([FrontMatterField].self, from: data) {
            frontMatterFields = fields
        }
        
        if let imageHandlingRaw = UserDefaults.standard.string(forKey: "imageHandling"),
           let handling = ImageHandling(rawValue: imageHandlingRaw) {
            imageHandling = handling
        }
        
        imageFolderPath = UserDefaults.standard.string(forKey: "imageFolderPath") ?? "./images"
        enableAutoAlt = UserDefaults.standard.bool(forKey: "enableAutoAlt")
        
        if let templateRaw = UserDefaults.standard.string(forKey: "altTextTemplate"),
           let template = AltTextTemplate(rawValue: templateRaw) {
            altTextTemplate = template
        }
        
        apiKey = UserDefaults.standard.string(forKey: "apiKey") ?? ""
        useExternalAPI = UserDefaults.standard.bool(forKey: "useExternalAPI")
        outputFilenameFormat = UserDefaults.standard.string(forKey: "outputFilenameFormat") ?? "note_{date}_{clipboard_preview}"
    }
    
    func saveSettings() {
        if let data = try? JSONEncoder().encode(frontMatterFields) {
            UserDefaults.standard.set(data, forKey: "frontMatterFields")
        }
        
        UserDefaults.standard.set(imageHandling.rawValue, forKey: "imageHandling")
        UserDefaults.standard.set(imageFolderPath, forKey: "imageFolderPath")
        UserDefaults.standard.set(enableAutoAlt, forKey: "enableAutoAlt")
        UserDefaults.standard.set(altTextTemplate.rawValue, forKey: "altTextTemplate")
        UserDefaults.standard.set(apiKey, forKey: "apiKey")
        UserDefaults.standard.set(useExternalAPI, forKey: "useExternalAPI")
        UserDefaults.standard.set(outputFilenameFormat, forKey: "outputFilenameFormat")
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
        
        // Check if path is empty
        if path.isEmpty {
            return false
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
