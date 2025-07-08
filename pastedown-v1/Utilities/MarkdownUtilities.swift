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
    
    // MARK: - Debug Utilities
    static func debugPrintText(_ text: String, context: String = "") {
        let visibleText = text
            .replacingOccurrences(of: "\n", with: "\\n")
            .replacingOccurrences(of: "\t", with: "\\t")
            .replacingOccurrences(of: " ", with: "·")
        
        print("🔍 [\(context)] Processing text: \"\(visibleText)\"")
        print("🔍 [\(context)] Original length: \(text.count)")
        print("🔍 [\(context)] Starts with: \(text.prefix(3).debugDescription)")
        print("🔍 [\(context)] Ends with: \(text.suffix(3).debugDescription)")
        print("🔍 [\(context)] ---")
    }
    
    // MARK: - Text Conversion
    static func convertTextWithAttributes(_ text: String, attributes: [NSAttributedString.Key: Any]) -> String {
        // Debug: Print the text being processed
        debugPrintText(text, context: "convertTextWithAttributes")
        
        var result = text
        
        result = handleListItems(result, attributes: attributes)
        
        // Handle headings based on font size (return early to avoid other formatting)
        let headingResult = convertHeadings(result, attributes: attributes)
        if headingResult != result {
            return headingResult // Return early for headings to avoid double formatting
        }
        
        // Handle links (do this before other formatting to preserve the link text)
        if let url = attributes[.link] as? URL {
            result = "[\(text)](\(url.absoluteString))"
            return result // Return early for links to avoid double formatting
        }
        
        // Handle combined text formatting
        result = applyTextFormatting(result, attributes: attributes)
        
        return result
    }
    
    // MARK: - Helper Functions for Text Conversion
    private static func handleListItems(_ text: String, attributes: [NSAttributedString.Key: Any]) -> String {
        var result = text
        
        // Handle list items first (before other formatting) using paragraph style
        if let paragraphStyle = attributes[.paragraphStyle] as? NSParagraphStyle {
            if !paragraphStyle.textLists.isEmpty {
                // if the text is not a list, add a list prefix
                if !result.trimmingCharacters(in: .whitespaces).hasPrefix("*") {
                    result = "* \(result)"
                }
            }
        }
        return result
    }

    private static func convertHeadings(_ text: String, attributes: [NSAttributedString.Key: Any]) -> String {
        guard let font = attributes[.font] as? UIFont else { return text }
        
        let fontSize = font.pointSize
        
        // Only treat as heading if it's a substantial font size increase
        if fontSize >= 25 {
            return "# \(text)"
        } else if fontSize >= 20 {
            return "## \(text)"
        }
        
        return text
    }

    private static func applyTextFormatting(_ text: String, attributes: [NSAttributedString.Key: Any]) -> String {
        // Debug: Print the text before formatting
        // debugPrintText(text, context: "applyTextFormatting-input")

        var result = text //.trimmingCharacters(in: .whitespacesAndNewlines)
        var formattingStack: [String] = []
        var closingStack: [String] = []
        
        // Check for font-based formatting
        if let font = attributes[.font] as? UIFont {
            let traits = font.fontDescriptor.symbolicTraits
            
            // Bold
            if traits.contains(.traitBold) {
                formattingStack.append("**")
                closingStack.insert("**", at: 0)
            }
            
            // Italic
            if traits.contains(.traitItalic) {
                formattingStack.append("*")
                closingStack.insert("*", at: 0)
            }
        }
        
        // Underline
        if let underlineStyle = attributes[.underlineStyle] as? NSNumber,
           underlineStyle.intValue != 0 {
            formattingStack.append("<u>")
            closingStack.insert("</u>", at: 0)
        }
        
        // Strikethrough
        if let strikethroughStyle = attributes[.strikethroughStyle] as? NSNumber,
           strikethroughStyle.intValue != 0 {
            formattingStack.append("~~")
            closingStack.insert("~~", at: 0)
        }
        
        // Apply all formatting
        let openingTags = formattingStack.joined()
        let closingTags = closingStack.joined()
        
        if !openingTags.isEmpty {
            result = "\(openingTags)\(result)\(closingTags)"
        }
        
        // Debug: Print the text after formatting
        // debugPrintText(result, context: "applyTextFormatting-output")
        
        return result
    }
    
    // MARK: - Image Conversion
    static func generateImageMarkdownWithBase64(image: UIImage, altText: String, settings: SettingsStore) -> String {
        switch settings.imageHandling {
        case .ignore:
            return "<!-- Image ignored -->"
        case .saveLocal:
            if let imageData = image.pngData() {
                let base64 = imageData.base64EncodedString()
                return "![image](data:image/png;base64,\(base64))"
            } else {
                return "![\(altText)](./images/image.png)"
            }
        case .saveCustom:
            if let imageData = image.pngData() {
                let base64 = imageData.base64EncodedString()
                return "![image](data:image/png;base64,\(base64))"
            } else {
                return "![\(altText)](.//\(settings.customImageFolder)/image.png)"
            }
        }
    }
    
    static func generateImageMarkdown(altText: String, settings: SettingsStore) -> String {
        switch settings.imageHandling {
        case .ignore:
            return "<!-- Image ignored -->"
        case .saveLocal:
            return "![\(altText)](./images/image.png)"
        case .saveCustom:
            return "![\(altText)](.//\(settings.customImageFolder)/image.png)"
        }
    }
    
    // MARK: - Front Matter Generation
    static func generateFrontMatter(settings: SettingsStore) -> String {
        guard !settings.frontMatterFields.isEmpty else { return "" }
        
        var frontMatter = "---\n"
        
        for field in settings.frontMatterFields {
            let processedValue = processFieldValue(field)
            
            switch field.type {
            case .string:
                frontMatter += "\(field.name): \"\(processedValue)\"\n"
            case .number:
                frontMatter += "\(field.name): \(processedValue)\n"
            case .boolean:
                frontMatter += "\(field.name): \(processedValue.lowercased() == "true" ? "true" : "false")\n"
            case .date, .datetime:
                frontMatter += "\(field.name): \"\(processedValue)\"\n"
            case .list:
                let items = processedValue.components(separatedBy: ",").map { $0.trimmingCharacters(in: .whitespaces) }
                frontMatter += "\(field.name): [\(items.map { "\"\($0)\"" }.joined(separator: ", "))]\n"
            case .tag:
                let items = processedValue.components(separatedBy: ",").map { $0.trimmingCharacters(in: .whitespaces) }
                frontMatter += "\(field.name):\n"
                for item in items {
                    frontMatter += "  - \"\(item)\"\n"
                }
            case .multiline:
                frontMatter += "\(field.name): >-\n"
                let lines = processedValue.components(separatedBy: .newlines)
                for line in lines {
                    frontMatter += "  \(line)\n"
                }
            case .uuid:
                frontMatter += "\(field.name): \"\(UUID().uuidString)\"\n"
            case .current_date:
                frontMatter += "\(field.name): \"\(processFieldValue(field))\"\n"
            case .current_datetime:
                frontMatter += "\(field.name): \"\(processFieldValue(field))\"\n"
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
} 
