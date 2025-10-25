//
//  MarkdownUtilities.swift
//  pastedown-v1
//
//  Created by 劉羽芯 on 2025/6/30.
//

import SwiftUI
import Foundation

// MARK: - Markdown Utilities
struct MarkdownUtilities {

    // MARK: - Main Logic Text Conversion
    static func convertTextWithAttributes(_ text: String, attributes: [NSAttributedString.Key: Any], plainTextReference: String? = nil) -> String {
        // Debug: Print the text being processed
        // debugPrintText(text, context: "convertTextWithAttributes")
        
        var result = text
        
        // 1. Add URL (if any, remember to preserve format)
        result = handleLinks(result, attributes: attributes)
        
        // 2. Handle text formatting (bold, italic, underline, strikethrough)
        result = applyTextFormatting(result, attributes: attributes)
        
        // 3. Handle list items (this processes the structure)
        result = handleListItems(result, attributes: attributes, plainTextReference: plainTextReference)
        
        // 4. Handle headings - add heading markers while preserving formatting
        let headingResult = convertHeadings(result, attributes: attributes)
        if headingResult != result {
            return headingResult // Headings with their formatting preserved
        }
        return result
    }
    
    // MARK: - Text Conversion without List Processing (for attribute ranges)
    static func convertTextWithAttributesNoList(_ text: String, attributes: [NSAttributedString.Key: Any]) -> String {
        var result = text
        // boldlink should be [**boldlink**](url), so handle formatting first
        // 1. Handle text formatting (bold, italic, underline, strikethrough)
        result = applyTextFormatting(result, attributes: attributes)

        // 2. Add URL (if any, remember to preserve format)
        result = handleLinks(result, attributes: attributes)
        
        return result
    }
    
    // MARK: - List Handling (Delegated to ListUtilities)
    static func handleListItems(_ text: String, attributes: [NSAttributedString.Key: Any], plainTextReference: String? = nil) -> String {
        return ListUtilities.processListItem(text, attributes: attributes, plainTextReference: plainTextReference)
    }

    // MARK: - Link Handling
    static func handleLinks(_ text: String, attributes: [NSAttributedString.Key: Any]) -> String {
        guard let url = attributes[.link] as? URL else {
            return text
        }
        
        // Since formatting hasn't been applied yet, we can simply wrap the text in link syntax
        // The formatting will be applied later and will wrap around the entire link
        // Use a more gentle trim that preserves emoji boundaries
        let linkText = text.trimmingCharacters(in: .whitespacesAndNewlines)
        return "[\(linkText)](\(url.absoluteString))"
    }
        
    static func convertHeadings(_ text: String, attributes: [NSAttributedString.Key: Any]) -> String {
        guard let font = attributes[.font] as? UIFont else { return text }
        
        let fontSize = font.pointSize
        
        // Only treat as heading if it's a substantial font size increase
        // Preserve any existing formatting in the heading text
        if fontSize >= 25 {
            return "# \(text)"
        } else if fontSize >= 20 {
            return "## \(text)"
        }
        
        return text
    }

    static func applyTextFormatting(_ text: String, attributes: [NSAttributedString.Key: Any]) -> String {
        // Debug: Print the text before formatting
        // debugPrintText(text, context: "applyTextFormatting-input")

        // Don't trim whitespace to preserve emoji sequences and formatting
        var result = text
        var formattingStack: [String] = []
        var closingStack: [String] = []
        
        // Check for font-based formatting
        if let font = attributes[.font] as? UIFont {
            let traits = font.fontDescriptor.symbolicTraits
        
        // order matters: underline, strikethrough, italic, bold
        // Strikethrough

        if let strikethroughStyle = attributes[.strikethroughStyle] as? NSNumber,
           strikethroughStyle.intValue != 0 {
            formattingStack.append("~~")
            closingStack.insert("~~", at: 0)
            
        }
        // Italic
        if traits.contains(.traitItalic) {
                formattingStack.append("*")
                closingStack.insert("*", at: 0)
             
            }

        // Bold
        if traits.contains(.traitBold) {
                formattingStack.append("**")
                closingStack.insert("**", at: 0)
                
            }
        }

        if let underlineStyle = attributes[.underlineStyle] as? NSNumber,
           underlineStyle.intValue != 0 {
            formattingStack.append("<u>")
            closingStack.insert("</u>", at: 0)
         
        }

        if let highlightStyle = attributes[NSAttributedString.Key.textHighlightStyle] {
            formattingStack.append("==")
            closingStack.insert("==", at: 0)
        }

        // Apply all formatting
        let openingTags = formattingStack.joined()
        let closingTags = closingStack.joined()
        
        if !openingTags.isEmpty {
            result = "\(openingTags)\(result)\(closingTags)"
        }
        
        return result
    }
    
    // MARK: - Front Matter Generation
    static func generateFrontMatter(settings: SettingsStore) -> String {
        guard !settings.frontMatterFields.isEmpty else { return "" }
        
        var frontMatter = "---\n"
        
        for field in settings.frontMatterFields {
            let processedValue = processFieldValueWithContext(field, allFields: settings.frontMatterFields)
            
            switch field.type {
            case .string:
                frontMatter += "\(field.name): \"\(processedValue)\"\n"
            case .number:
                frontMatter += "\(field.name): \(processedValue)\n"
            case .boolean:
                frontMatter += "\(field.name): \(processedValue.lowercased() == "true" ? "true" : "false")\n"
            case .date, .datetime:
                frontMatter += "\(field.name): \(processedValue)\n"
            case .list:
                let items = parseArrayField(processedValue)
                frontMatter += "\(field.name): [\(items.map { "\"\($0)\"" }.joined(separator: ", "))]\n"
            case .tag:
                let items = parseArrayField(processedValue)
                frontMatter += "\(field.name):\n"
                for item in items {
                    frontMatter += "    - \"\(item)\"\n"
                }
            case .multiline:
                frontMatter += "\(field.name): >-\n"
                let lines = processedValue.components(separatedBy: .newlines)
                for line in lines {
                    frontMatter += "    \(line)\n"
                }
            case .current_date:
                let dateFormatter = DateFormatter()
                dateFormatter.dateFormat = "yyyy-MM-dd"
                let currentDate = dateFormatter.string(from: Date())
                frontMatter += "\(field.name): \(currentDate)\n"
            case .current_datetime:
                let dateTimeFormatter = DateFormatter()
                dateTimeFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss"
                let currentDateTime = dateTimeFormatter.string(from: Date())
                frontMatter += "\(field.name): \(currentDateTime)\n"
            }
        }
        
        frontMatter += "---"
        return frontMatter
    }
    
    static func processFieldValue(_ field: FrontMatterField) -> String {
        var value = field.value
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        let currentDate = dateFormatter.string(from: Date())
        
        let timeFormatter = DateFormatter()
        timeFormatter.dateFormat = "HH:mm:ss"
        let currentTime = timeFormatter.string(from: Date())
        
        value = value.replacingOccurrences(of: "{current_date}", with: currentDate)
        value = value.replacingOccurrences(of: "{current_time}", with: currentTime)
        
        return value
    }
    
    // Enhanced version that can resolve field references
    static func processFieldValueWithContext(_ field: FrontMatterField, allFields: [FrontMatterField]) -> String {
        var value = field.value
        
        // Process date/time variables
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        let currentDate = dateFormatter.string(from: Date())
        
        let timeFormatter = DateFormatter()
        timeFormatter.dateFormat = "HH:mm:ss"
        let currentTime = timeFormatter.string(from: Date())
        
        value = value.replacingOccurrences(of: "{current_date}", with: currentDate)
        value = value.replacingOccurrences(of: "{current_time}", with: currentTime)
        
        // Process field references like {title}, {author}, etc.
        for otherField in allFields {
            if otherField.id != field.id { // Don't reference self
                let placeholder = "{\(otherField.name)}"
                if value.contains(placeholder) {
                    let fieldValue = getFieldDisplayValue(otherField, allFields: allFields, processedFields: [field.id.uuidString])
                    value = value.replacingOccurrences(of: placeholder, with: fieldValue)
                }
            }
        }
        
        return value
    }
    
    // Get the display value of a field (recursively process variables but avoid circular references)
    private static func getFieldDisplayValue(_ field: FrontMatterField, allFields: [FrontMatterField]? = nil, processedFields: Set<String> = []) -> String {
        // Prevent circular references by tracking processed fields
        guard !processedFields.contains(field.id.uuidString) else {
            return field.value // Return raw value if circular reference detected
        }
        
        var newProcessedFields = processedFields
        newProcessedFields.insert(field.id.uuidString)
        
        switch field.type {
        case .current_date:
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "yyyy-MM-dd"
            return dateFormatter.string(from: Date())
        case .current_datetime:
            let dateTimeFormatter = DateFormatter()
            dateTimeFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss"
            return dateTimeFormatter.string(from: Date())
        case .tag:
            let items = parseArrayField(field.value)
            return items.joined(separator: ", ")
        case .list:
            let items = parseArrayField(field.value)
            return items.joined(separator: ", ")
        default:
            // If we have access to all fields, process variables recursively
            if let allFields = allFields {
                return processFieldValueRecursive(field, allFields: allFields, processedFields: newProcessedFields)
            } else {
                return field.value
            }
        }
    }
    
    // Process field value recursively with circular reference protection
    private static func processFieldValueRecursive(_ field: FrontMatterField, allFields: [FrontMatterField], processedFields: Set<String>) -> String {
        var value = field.value
        
        // Process date/time variables
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        let currentDate = dateFormatter.string(from: Date())
        
        let timeFormatter = DateFormatter()
        timeFormatter.dateFormat = "HH:mm:ss"
        let currentTime = timeFormatter.string(from: Date())
        
        value = value.replacingOccurrences(of: "{current_date}", with: currentDate)
        value = value.replacingOccurrences(of: "{current_time}", with: currentTime)
        
        // Process field references recursively
        for otherField in allFields {
            if otherField.id != field.id { // Don't reference self
                let placeholder = "{\(otherField.name)}"
                if value.contains(placeholder) {
                    let fieldValue = getFieldDisplayValue(otherField, allFields: allFields, processedFields: processedFields)
                    value = value.replacingOccurrences(of: placeholder, with: fieldValue)
                }
            }
        }
        
        return value
    }
    
    // MARK: - Array Field Parsing
    static func parseArrayField(_ value: String) -> [String] {
        // First try to parse as JSON array (new format from SmartFrontMatterFieldView)
        if let jsonData = value.data(using: .utf8),
           let items = try? JSONDecoder().decode([String].self, from: jsonData) {
            return items.filter { !$0.isEmpty }
        }
        
        // Fallback to comma-separated format (legacy/manual input)
        if !value.isEmpty {
            return value.components(separatedBy: ",")
                .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
                .filter { !$0.isEmpty }
        }
        
        return []
    }
} 