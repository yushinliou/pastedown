//
//  ListUtilities.swift
//  pastedown-v1
//
//  Created by AI Assistant on 2025/7/16.
//

import SwiftUI
import Foundation

// MARK: - List Context and State Management
struct ListContext {
    var numberedListCounter: Int = 1
    var lastWasNumberedList: Bool = false
    var lastWasUnorderedList: Bool = false
    var currentIndentLevel: Int = 0
    var listNestingLevels: [Int: Int] = [:] // Track counters for each nesting level
    
    mutating func resetIfNeeded(for newIndentLevel: Int, isNumberedList: Bool) {
        if newIndentLevel != currentIndentLevel {
            currentIndentLevel = newIndentLevel
            if isNumberedList {
                // Reset counter for new nesting level if needed
                if listNestingLevels[newIndentLevel] == nil {
                    listNestingLevels[newIndentLevel] = 1
                }
            }
        }
    }
    
    mutating func incrementNumberedCounter(for indentLevel: Int) {
        listNestingLevels[indentLevel] = (listNestingLevels[indentLevel] ?? 0) + 1
    }
    
    func getNumberedCounter(for indentLevel: Int) -> Int {
        return listNestingLevels[indentLevel] ?? 1
    }
}

// MARK: - List Processor
class ListProcessor {
    private var context = ListContext()
    
    // Reset the processor state
    func reset() {
        context = ListContext()
    }
    
    // helper function to determine if a line is a list item
    private func isListItem(_ text: String, attributes: [NSAttributedString.Key: Any]) -> Bool {
        let unorderedListPattern = #"^\t([^\t])\t\t([^\t])\t(.*)$"#
        let emptyListPattern = #"^\t[-•*]\t"#
        let orderedListPattern = #"^\t(\d+)\.\t(.*)$"#
        
        // Check if attribute contain "NSTextList" in paragraph style
        if let paragraphStyle = attributes[.paragraphStyle] as? NSParagraphStyle {
            return paragraphStyle.textLists.count > 0
        }
        // if find pattern in prefix, it is a list item
        if let regex = try? NSRegularExpression(pattern: unorderedListPattern, options: []),
           regex.firstMatch(in: text, options: [], range: NSRange(text.startIndex..<text.endIndex, in: text)) != nil {
            return true
        } else if let regex = try? NSRegularExpression(pattern: orderedListPattern, options: []),
                  regex.firstMatch(in: text, options: [], range: NSRange(text.startIndex..<text.endIndex, in: text)) != nil {
            
            return true
        } else if let regex = try? NSRegularExpression(pattern: emptyListPattern, options: []),
                  regex.firstMatch(in: text, options: [], range: NSRange(text.startIndex..<text.endIndex, in: text)) != nil {
            
            return true
        }
        return false
    }

    // Main list processing function
    func processListItem(_ text: String, attributes: [NSAttributedString.Key: Any], plainTextReference: String? = nil) -> String {
        // return if text is not a list item
        if !isListItem(text, attributes: attributes) {
            return text
        }
        // Handle special empty cases
        if text == "\t•\t" {
            return ""
        }
        if text == "\t⁃\t" {
            return "  - "
        }
        
        var result = text.trimmingCharacters(in: .whitespacesAndNewlines)
        // if there is already a prefix, we don't need to add one, use pattern to match number prefix
        if result.hasPrefix("* ") || result.hasPrefix("- ") || result.hasPrefix("- [ ]") || result.hasPrefix("- [x]") || result.hasPrefix("1. ") ||
           result.hasPrefix("a. ") || result.hasPrefix("A. ") || result.hasPrefix("i. ") || result.hasPrefix("I. ") {
            return result // Already has a prefix, return as is
        }
        
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
        
        // Check paragraph style first
        if let paragraphStyle = attributes[.paragraphStyle] as? NSParagraphStyle {
            if paragraphStyle.textLists.count > 0 {
                indentLevel = paragraphStyle.textLists.count
                context.resetIfNeeded(for: indentLevel, isNumberedList: false)
                
                if let textList = paragraphStyle.textLists.last,
                   let format = textList.value(forKey: "markerFormat") as? String {
                    switch format {
                    case "{disc}": prefix = "*"
                    case "{hyphen}": prefix = "-"
                    case "{circle}":
                        // Check plain text reference for actual checkbox state
                        prefix = getCheckboxState(from: plainTextReference) ? "- [x]" : "- [ ]" // if getcheckboxState returns true, use checked box
                    case "{check}":
                        // Check plain text reference for actual checkbox state
                        prefix = getCheckboxState(from: plainTextReference) ? "- [x]" : "- [ ]"
                    case "{decimal}.": 
                        prefix = "1." // Use lazy numbering - all items use "1."
                        context.lastWasNumberedList = true
                    case "{loweralpha}.": prefix = "a."
                    case "{upperalpha}.": prefix = "A."
                    case "{lowerroman}.": prefix = "i."
                    case "{upperroman}.": prefix = "I."
                    default: prefix = "-"
                    }
                }
            } else {
                // Handle special patterns when no textLists are present
                let processedResult = handleSpecialListPatterns(text: text, symbolMap: symbolMap, plainTextReference: plainTextReference)
                if let (specialPrefix, specialResult, specialIndent, isNumbered, isUnordered) = processedResult {
                    prefix = specialPrefix
                    result = specialResult
                    indentLevel = specialIndent
                    foundSpecialNumberFormat = isNumbered
                    foundSpecialUnorderedFormat = isUnordered
                    
                    if isNumbered {
                        context.resetIfNeeded(for: indentLevel, isNumberedList: true)
                        context.lastWasNumberedList = true
                    }
                }
            }
        }
        
        // Skip empty results unless it's a special unordered format
        if result.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && !foundSpecialUnorderedFormat {
            return ""
        }
        
        // Apply prefix and indentation
        if let prefix = prefix {
            let indent = String(repeating: "    ", count: max(indentLevel - 1, 0))
            result = "\(indent)\(prefix) \(result)"
        }
        
        return result
    }
    
    // MARK: - Helper Methods
    
    private func getCheckboxState(from plainTextReference: String?) -> Bool {
        guard let plainText = plainTextReference else { return false }
        
        // Look for checkbox indicators in plain text
        // Apple Notes uses different characters for checked/unchecked in plain text
        let checkedPatterns = ["☑", "✓", "✔", "[x]", "[X]"]
        let uncheckedPatterns = ["☐", "◻", "[]", "[ ]", "◦"]
        
        // First check for checked patterns at the beginning of the line
        let trimmedText = plainText.trimmingCharacters(in: .whitespacesAndNewlines)
        
        // Check for checked state first
        for pattern in checkedPatterns {
            if trimmedText.hasPrefix(pattern) || trimmedText.contains(" \(pattern) ") || trimmedText.contains("\t\(pattern)\t") {
                return true
            }
        }
        
        // Check for unchecked state
        for pattern in uncheckedPatterns {
            if trimmedText.hasPrefix(pattern) || trimmedText.contains(" \(pattern) ") || trimmedText.contains("\t\(pattern)\t") {
                return false
            }
        }
        
        return false // Default to unchecked if unclear
    }
    
    private func handleSpecialListPatterns(text: String, symbolMap: [String: String], plainTextReference: String?) -> (String, String, Int, Bool, Bool)? {
        // Handle unordered list pattern: \t•\t\t•\tTEXT
        let unorderedListPattern = #"^\t([^\t])\t\t([^\t])\t(.*)$"#
        
        if let regex = try? NSRegularExpression(pattern: unorderedListPattern),
           let match = regex.firstMatch(in: text, options: [], range: NSRange(text.startIndex..<text.endIndex, in: text)),
           let symbolRange = Range(match.range(at: 2), in: text),
           let contentRange = Range(match.range(at: 3), in: text) {
            
            let symbol = String(text[symbolRange])
            var prefix = symbolMap[symbol] ?? "*"
            
            // Special handling for checkboxes - check the line-specific plain text
            if symbol == "◦" || symbol == "✓" {
                prefix = getCheckboxState(from: plainTextReference) ? "- [x]" : "- [ ]"
            }
            
            let content = String(text[contentRange]).trimmingCharacters(in: .whitespacesAndNewlines)
            return (prefix, content, 1, false, true)
        }
        
        // Handle numbered list pattern: \t42.\tTEXT
        let orderedListPattern = #"^\t(\d+)\.\t(.*)$"#
        if let regex = try? NSRegularExpression(pattern: orderedListPattern),
           let match = regex.firstMatch(in: text, options: [], range: NSRange(text.startIndex..<text.endIndex, in: text)),
           let numberRange = Range(match.range(at: 1), in: text),
           let contentRange = Range(match.range(at: 2), in: text) {
            
            // Use lazy numbering - all items use "1."
            let prefix = "1."
            
            let content = String(text[contentRange]).trimmingCharacters(in: .whitespacesAndNewlines)
            return (prefix, content, 1, true, false)
        }
        
        return nil
    }
}

// MARK: - Static Utility Functions
struct ListUtilities {
    static let processor = ListProcessor()
    
    // Main entry point for list processing
    static func processListItem(_ text: String, attributes: [NSAttributedString.Key: Any], plainTextReference: String? = nil) -> String {
        return processor.processListItem(text, attributes: attributes, plainTextReference: plainTextReference)
    }
    
    // Reset the processor state (useful for new documents)
    static func resetProcessor() {
        processor.reset()
    }
    
    // Get prefix number from text (kept for backward compatibility)
    static func getPrefixNumber(_ text: String) -> String? {
        let numberPattern = #"^(\d+)\.[\t\s]"#
        if let regex = try? NSRegularExpression(pattern: numberPattern, options: []) {
            let range = NSRange(text.startIndex..<text.endIndex, in: text)
            if let match = regex.firstMatch(in: text, options: [], range: range) {
                if let numberRange = Range(match.range(at: 1), in: text) {
                    return String(text[numberRange])
                }
            }
        }
        return "1" // Default to "1" if no number prefix found
    }
}