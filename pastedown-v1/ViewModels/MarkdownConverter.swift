//
//  MarkdownConverter.swift
//  pastedown-v1
//
//  Created by 劉羽芯 on 2025/7/7.
//
 import SwiftUI

// MARK: - Markdown Converter
class MarkdownConverter: ObservableObject {
    private let settings: SettingsStore
    
    init(settings: SettingsStore) {
        self.settings = settings
    }
    
    func convertToMarkdown(from attributedString: NSAttributedString) async -> String {
        var markdown = ""
        
        // Add Front Matter if configured
        if !settings.frontMatterFields.isEmpty {
            markdown += generateFrontMatter()
            markdown += "\n"
        }
        
        // Convert attributed string to markdown
        let range = NSRange(location: 0, length: attributedString.length)
        var currentIndex = 0
        
        attributedString.enumerateAttributes(in: range, options: []) { attributes, range, _ in
            let substring = attributedString.attributedSubstring(from: range).string
            let convertedText = self.convertTextWithAttributes(substring, attributes: attributes)
            markdown += convertedText
            currentIndex = range.location + range.length
        }
        
        return markdown
    }
    
    private func generateFrontMatter() -> String {
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
                let dateFormatter = DateFormatter()
                dateFormatter.dateFormat = "yyyy-MM-dd"
                let currentDate = dateFormatter.string(from: Date())
                frontMatter += "\(field.name): \"\(currentDate)\"\n"
            case .current_datetime:
                let dateFormatter = DateFormatter()
                dateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
                let currentDateTime = dateFormatter.string(from: Date())
                frontMatter += "\(field.name): \"\(currentDateTime)\"\n"
            }

        }
        
        frontMatter += "---"
        return frontMatter
    }
    
    private func processFieldValue(_ field: FrontMatterField) -> String {
        var value = field.value
        
        // Process template variables
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
    
    private func convertTextWithAttributes(_ text: String, attributes: [NSAttributedString.Key: Any]) -> String {
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
    
    func generateFilename(title: String = "", clipboardPreview: String = "") -> String {
        var filename = settings.outputFilenameFormat
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        let currentDate = dateFormatter.string(from: Date())
        
        let timeFormatter = DateFormatter()
        timeFormatter.dateFormat = "HH-mm-ss"
        let currentTime = timeFormatter.string(from: Date())
        
        filename = filename.replacingOccurrences(of: "{title}", with: title.isEmpty ? "untitled" : title)
        filename = filename.replacingOccurrences(of: "{date}", with: currentDate)
        filename = filename.replacingOccurrences(of: "{time}", with: currentTime)
        filename = filename.replacingOccurrences(of: "{uuid}", with: UUID().uuidString.prefix(8).lowercased())
        filename = filename.replacingOccurrences(of: "{clipboard_preview}", with: clipboardPreview.prefix(20).description)
        
        // Handle index - for simplicity, using timestamp
        let index = Int(Date().timeIntervalSince1970) % 10000
        filename = filename.replacingOccurrences(of: "{index}", with: String(index))
        
        return filename
    }
}
