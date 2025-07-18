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
            print("[convertTextWithAttributes] [\(result)]")
            return headingResult // Headings with their formatting preserved
        }
        print("[convertTextWithAttributes] [\(result)]")
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

        // Skip list processing - this will be handled at the line level
        
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

        var result = text //.trimmingCharacters(in: .whitespacesAndNewlines)
        var formattingStack: [String] = []
        var closingStack: [String] = []
        var findUnderline = false
        var findStrikethrough = false
        var findItalic = false
        var findBold = false
        
        // Check for font-based formatting
        if let font = attributes[.font] as? UIFont {
            let traits = font.fontDescriptor.symbolicTraits
        
        // order matters: underline, strikethrough, italic, bold
        // Strikethrough
        if let strikethroughStyle = attributes[.strikethroughStyle] as? NSNumber,
           strikethroughStyle.intValue != 0 {
            formattingStack.append("~~")
            closingStack.insert("~~", at: 0)
            findStrikethrough = true
        }        
        // Italic
        if traits.contains(.traitItalic) {
                formattingStack.append("*")
                closingStack.insert("*", at: 0)
                findItalic = true
            }

            // Bold
            if traits.contains(.traitBold) {
                formattingStack.append("**")
                closingStack.insert("**", at: 0)
                findBold = true
            }
        }
        
        if let underlineStyle = attributes[.underlineStyle] as? NSNumber,
           underlineStyle.intValue != 0 {
            formattingStack.append("<u>")
            closingStack.insert("</u>", at: 0)
            findUnderline = true
        }
        // Apply all formatting
        let openingTags = formattingStack.joined()
        let closingTags = closingStack.joined()
        
        if !openingTags.isEmpty {
            result = "\(openingTags)\(result)\(closingTags)"
        }
        
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