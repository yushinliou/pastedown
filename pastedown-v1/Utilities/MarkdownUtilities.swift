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
        // debugPrintText(text, context: "convertTextWithAttributes")
        
        var result = text
        
        // First, handle list items (this processes the structure)
        result = handleListItems(result, attributes: attributes)
        
        // Apply text formatting (bold, italic, underline, strikethrough) to the content
        result = applyTextFormatting(result, attributes: attributes)
        
        // Handle links - wrap the formatted text with link syntax
        if let url = attributes[.link] as? URL {
            // Extract list prefix if present
            let listPrefix = extractListPrefix(from: result)
            
            // Extract the content from any existing formatting to use as link text
            let linkText = extractContentFromFormatting(result)
            
            // Create the link
            var link = "[\(linkText)](\(url.absoluteString))"
            
            // Re-apply text formatting to the link if there was any (excluding list formatting)
            let textWithoutListPrefix = String(result.dropFirst(listPrefix.count))
            if textWithoutListPrefix != linkText {
                // Apply formatting around the link
                link = applyTextFormattingToLink(link, attributes: attributes)
            }
            
            // Combine list prefix with the formatted link
            result = listPrefix + link
        }
        
        // Handle headings - add heading markers while preserving formatting
        let headingResult = convertHeadings(result, attributes: attributes)
        if headingResult != result {
            return headingResult // Headings with their formatting preserved
        }
        
        return result
    }
    
    // Helper function to extract content from formatting markers
    private static func extractContentFromFormatting(_ text: String) -> String {
        var content = text
        
        // Remove markdown formatting to get clean text for link display
        content = content.replacingOccurrences(of: "**", with: "")
        content = content.replacingOccurrences(of: "*", with: "")
        content = content.replacingOccurrences(of: "<u>", with: "")
        content = content.replacingOccurrences(of: "</u>", with: "")
        content = content.replacingOccurrences(of: "~~", with: "")
        
        // Remove list formatting markers and indentation
        // Pattern to match: any amount of spaces, followed by list marker, followed by space
        let listPatterns = [
            #"^\s*-\s*\[[x ]\]\s*"#, // "  - [ ] " or "  - [x] "
            #"^\s*\*\s+"#,      // "  * "
            #"^\s*-\s+"#,       // "  - "
            #"^\s*\+\s+"#,      // "  + "
            #"^\s*\d+\.\s+"#,   // "  1. "
            #"^\s*[a-zA-Z]\.\s+"#  // "  a. " or "  A. "
        ]
        
        for pattern in listPatterns {
            if let regex = try? NSRegularExpression(pattern: pattern) {
                content = regex.stringByReplacingMatches(in: content, options: [], range: NSRange(content.startIndex..<content.endIndex, in: content), withTemplate: "")
            }
        }
        
        return content.trimmingCharacters(in: .whitespacesAndNewlines)
    }
    
    // Helper function to apply formatting to text (excluding link formatting)
    private static func applyFormattingToText(_ text: String, attributes: [NSAttributedString.Key: Any], excludeLink: Bool = false) -> String {
        // This preserves the original formatting application logic
        return applyTextFormatting(text, attributes: attributes)
    }
    
    // Helper function to extract list prefix (indentation + marker)
    private static func extractListPrefix(from text: String) -> String {
        let listPatterns = [
            #"^(\s*-\s*\[[x ]\]\s*)"#, // "  - [ ] " or "  - [x] "
            #"^(\s*\*\s+)"#,      // "  * "
            #"^(\s*-\s+)"#,       // "  - "
            #"^(\s*\+\s+)"#,      // "  + "
            #"^(\s*\d+\.\s+)"#,   // "  1. "
            #"^(\s*[a-zA-Z]\.\s+)"#  // "  a. " or "  A. "
        ]
        
        for pattern in listPatterns {
            if let regex = try? NSRegularExpression(pattern: pattern),
               let match = regex.firstMatch(in: text, options: [], range: NSRange(text.startIndex..<text.endIndex, in: text)),
               let range = Range(match.range(at: 1), in: text) {
                return String(text[range])
            }
        }
        
        return ""
    }
    
    // Helper function to apply text formatting around a link
    private static func applyTextFormattingToLink(_ link: String, attributes: [NSAttributedString.Key: Any]) -> String {
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
        
        // Apply all formatting around the link
        let openingTags = formattingStack.joined()
        let closingTags = closingStack.joined()
        
        if !openingTags.isEmpty {
            return "\(openingTags)\(link)\(closingTags)"
        }
        
        return link
    }
            
private static func handleListItems(_ text: String, attributes: [NSAttributedString.Key: Any]) -> String {
    // special case happend one single number list and dashed list
    if text == "\t•\t" {
        return ""
    }
    if text == "\t⁃\t" {
        return "  - "
    }
    // normal case
    var result = text.trimmingCharacters(in: .whitespacesAndNewlines)
    var prefix: String? = nil
    var indentLevel = 0
    var foundSpecialUnorderedFormat = false
    var foundSpecialNumberFormat = false

    let symbolMap = [
        "•": "*",
        "⁃": "-",
        "◦": "- [ ]",
        "✓": "- [x]",
        "1.": "1.",
        "a.": "a.",
        "A.": "A.",
        "i.": "i.",
        "I.": "I."
    ]
    // check paragraph style
    if let paragraphStyle = attributes[.paragraphStyle] as? NSParagraphStyle {
        
        if paragraphStyle.textLists.count > 0 {
            indentLevel = paragraphStyle.textLists.count

            if let textList = paragraphStyle.textLists.last,
               let format = textList.value(forKey: "markerFormat") as? String {
                print("[FORMAT]: \(format)")
                switch format {
                case "{disc}": prefix = "*"
                case "{hyphen}": prefix = "-"
                case "{circle}": prefix = "- [ ]"
                case "{check}": prefix = "- [x]"
                case "{decimal}.": prefix = "1."
                case "{loweralpha}.": prefix = "a."
                case "{upperalpha}.": prefix = "A."
                case "{lowerroman}.": prefix = "i."
                case "{upperroman}.": prefix = "I."
                default: prefix = "-"
                }
            }
        } else { // special case, happen when there is no extra element after list, we need to handle last line it manually
            // 📌 unordered list pattern: \t•\t\t•\tTEXT
            let unorderListPattern = #"^\t([^\t])\t\t([^\t])\t(.*)$"#
            if let regex = try? NSRegularExpression(pattern: unorderListPattern),
               let match = regex.firstMatch(in: text, options: [], range: NSRange(text.startIndex..<text.endIndex, in: text)),
               let symbolRange = Range(match.range(at: 2), in: text),
               let contentRange = Range(match.range(at: 3), in: text) {
                let symbol = symbolMap[String(text[symbolRange])] ?? "*"
                prefix = symbol
                result = String(text[contentRange]).trimmingCharacters(in: .whitespacesAndNewlines)
                indentLevel = 1
                foundSpecialUnorderedFormat = true
                print("[FOUND SPECIAL UNORDERED FORMAT]: \(symbol)")
            } else {
                // 📌 number pattern: \t42.\tTEXT
                let orderedListPattern = #"^\t(\d+)\.\t(.*)$"#
                if let regex = try? NSRegularExpression(pattern: orderedListPattern),
                   let match = regex.firstMatch(in: text, options: [], range: NSRange(text.startIndex..<text.endIndex, in: text)),
                   let numberRange = Range(match.range(at: 1), in: text),
                   let contentRange = Range(match.range(at: 2), in: text) {
                    let number = String(text[numberRange])
                    prefix = "\(number)."
                    result = String(text[contentRange]).trimmingCharacters(in: .whitespacesAndNewlines)
                    indentLevel = 1
                    foundSpecialNumberFormat = true
                    print("[FOUND SPECIAL NUMBER FORMAT]: \(prefix!)")
                }
            }
        }
    }
    if result.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && !foundSpecialUnorderedFormat{
        return ""
    }

    if let prefix = prefix {
        let indent = String(repeating: "  ", count: indentLevel)
        result = "\(indent)\(prefix) \(result)"
    }
    return result
}
    
    private static func convertHeadings(_ text: String, attributes: [NSAttributedString.Key: Any]) -> String {
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
