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
    
    // MARK: - Text Conversion
    static func convertTextWithAttributes(_ text: String, attributes: [NSAttributedString.Key: Any]) -> String {
        var result = text
        
        // Handle font styles
        if let font = attributes[.font] as? UIFont {
            if font.fontDescriptor.symbolicTraits.contains(.traitBold) {
                result = "**\(result)**"
            }
            if font.fontDescriptor.symbolicTraits.contains(.traitItalic) {
                result = "*\(result)*"
            }
        }
        
        // Handle strikethrough
        if attributes[.strikethroughStyle] != nil {
            result = "~~\(result)~~"
        }
        
        // Handle links
        if let url = attributes[.link] as? URL {
            result = "[\(text)](\(url.absoluteString))"
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