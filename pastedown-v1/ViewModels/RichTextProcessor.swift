import Foundation
import SwiftUI
import UIKit

@MainActor
class RichTextProcessor: ObservableObject {
    private let imageAnalyzer: ImageAnalyzer
    private let settings: SettingsStore
    
    init(imageAnalyzer: ImageAnalyzer, settings: SettingsStore) {
        self.imageAnalyzer = imageAnalyzer
        self.settings = settings
    }
    
    func processAttributedStringWithImages(_ attributedString: NSAttributedString) async -> String {
        var markdown = ""
        
        // First, collect all images and their positions
        var imageOperations: [(range: NSRange, image: UIImage)] = []
        
        attributedString.enumerateAttributes(in: NSRange(location: 0, length: attributedString.length), options: []) { attrs, range, _ in
            if let attachment = attrs[.attachment] as? NSTextAttachment,
               let image = attachment.image {
                imageOperations.append((range: range, image: image))
            }
        }
        
        // Generate alt text for all images while preserving order
        var altTexts: [String] = []
        if !imageOperations.isEmpty {
            altTexts = await withTaskGroup(of: (Int, String).self) { group in
                for (index, operation) in imageOperations.enumerated() {
                    group.addTask {
                        let altText = await self.imageAnalyzer.generateAltText(for: operation.image)
                        return (index, altText)
                    }
                }
                
                var results: [(Int, String)] = []
                for await result in group {
                    results.append(result)
                }
                
                // Sort by index to maintain order
                results.sort { $0.0 < $1.0 }
                return results.map { $0.1 }
            }
        }
        
        // Process line by line to handle mixed attributes correctly
        var imageIndex = 0
        print("================ Start cutting text ==================")  
        print("attributedString: [\(attributedString)]")
        
        // Split into lines while preserving attributed string structure
        let fullText = attributedString.string
        let lines = fullText.components(separatedBy: .newlines)
        var currentLocation = 0
        
        // Table detection: look for consecutive table rows
        var tableRows: [String] = []
        var inTable = false
        
        for (lineIndex, line) in lines.enumerated() {
            if line.isEmpty {
                // End of table if we were in one
                if inTable {
                    markdown += processCompleteTable(tableRows)
                    tableRows.removeAll()
                    inTable = false
                }
                
                if lineIndex < lines.count - 1 {
                    markdown += "\n"
                    currentLocation += 1 // account for newline character
                }
                continue
            }
            
            var lineMarkdown = ""
            let lineRange = NSRange(location: currentLocation, length: line.count)
            print("Processing line: [\(line)] at range: \(lineRange)")
            
            // Check if this line contains table data
            var isTableRow = false
            var hasTabCharacters = line.contains("\t")
            
            // First pass: check if this line should have list formatting or table formatting
            var listPrefix = ""
            var hasListFormatting = false
            
            attributedString.enumerateAttributes(in: lineRange, options: []) { attrs, range, _ in
                if !hasListFormatting && !isTableRow {
                    let substring = attributedString.attributedSubstring(from: range).string
                    
                    // Check for table formatting first
                    if let paragraphStyle = attrs[.paragraphStyle] as? NSParagraphStyle {
                        if !paragraphStyle.tabStops.isEmpty || hasTabCharacters {
                            isTableRow = true
                        }
                    }
                    
                    // Check for list formatting if not a table
                    if !isTableRow {
                        let potentialListResult = MarkdownUtilities.handleListItems(substring, attributes: attrs)
                        if potentialListResult != substring && !potentialListResult.isEmpty {
                            // Extract just the list prefix
                            if let prefixMatch = potentialListResult.range(of: #"^(\s*(?:-\s*\[[x ]\]|\*|\+|-|\d+\.|[a-zA-Z]\.)\s+)"#, options: .regularExpression) {
                                listPrefix = String(potentialListResult[prefixMatch])
                                hasListFormatting = true
                            }
                        }
                    }
                }
            }
            
            // Handle table rows
            if isTableRow {
                // Process the table row
                attributedString.enumerateAttributes(in: lineRange, options: []) { attrs, range, _ in
                    let substring = attributedString.attributedSubstring(from: range).string
                    
                    // Apply formatting but skip list handling for tables
                    var formattedText = substring
                    formattedText = MarkdownUtilities.handleLinks(formattedText, attributes: attrs)
                    formattedText = MarkdownUtilities.handleTables(formattedText, attributes: attrs)
                    formattedText = MarkdownUtilities.applyTextFormatting(formattedText, attributes: attrs)
                    
                    lineMarkdown += formattedText
                }
                
                // Add to table rows collection
                tableRows.append(lineMarkdown)
                inTable = true
                
                // If this is the last line or next line is not a table, process the complete table
                if lineIndex == lines.count - 1 || 
                   (lineIndex < lines.count - 1 && !isNextLineTable(lines[lineIndex + 1], attributedString: attributedString, nextLocation: currentLocation + line.count + 1)) {
                    markdown += processCompleteTable(tableRows)
                    tableRows.removeAll()
                    inTable = false
                }
            } else {
                // End table if we were in one
                if inTable {
                    markdown += processCompleteTable(tableRows)
                    tableRows.removeAll()
                    inTable = false
                }
                
                // Process regular line (non-table)
                // Second pass: process each attribute range for formatting
                attributedString.enumerateAttributes(in: lineRange, options: []) { attrs, range, _ in
                    if let attachment = attrs[.attachment] as? NSTextAttachment {
                        // Handle image attachment
                        if let image = attachment.image {
                            let altText = imageIndex < altTexts.count ? altTexts[imageIndex] : "image"
                            let imageMarkdown = MarkdownUtilities.generateImageMarkdownWithBase64(image: image, altText: altText, settings: settings)
                            lineMarkdown += imageMarkdown
                            imageIndex += 1
                        } else {
                            // Fallback for attachments without images
                            lineMarkdown += "<!-- ![attachment] -->"
                        }
                    } else {
                        // Handle regular text with formatting
                        let substring = attributedString.attributedSubstring(from: range).string
                        print("Substring: [\(substring)]")
                        
                        // Apply formatting but skip list handling since we handle it at line level
                        var formattedText = substring
                        formattedText = MarkdownUtilities.handleLinks(formattedText, attributes: attrs)
                        formattedText = MarkdownUtilities.applyTextFormatting(formattedText, attributes: attrs)
                        
                        lineMarkdown += formattedText
                    }
                }
                
                // Apply list prefix to the entire line if needed
                if hasListFormatting && !lineMarkdown.isEmpty {
                    lineMarkdown = listPrefix + lineMarkdown
                }
                
                // Check for headings at line level
                if !hasListFormatting {
                    // Get attributes from the first character of the line for heading detection
                    if lineRange.length > 0 {
                        let firstCharRange = NSRange(location: lineRange.location, length: 1)
                        attributedString.enumerateAttributes(in: firstCharRange, options: []) { attrs, _, _ in
                            let headingResult = MarkdownUtilities.convertHeadings(lineMarkdown, attributes: attrs)
                            if headingResult != lineMarkdown {
                                lineMarkdown = headingResult
                            }
                        }
                    }
                }
                
                markdown += lineMarkdown
                
                // Add newline after each line except the last one
                if lineIndex < lines.count - 1 {
                    markdown += "\n"
                }
                
                currentLocation += line.count + 1 // +1 for newline character
            }
        }
        
        // Process any remaining table rows at the end
        if inTable {
            markdown += processCompleteTable(tableRows)
        }
        
        return markdown
    }
    
    private func processCompleteTable(_ rows: [String]) -> String {
        var markdown = ""
        if rows.isEmpty {
            return markdown
        }
        
        // Process each row to extract column data
        var tableData: [[String]] = []
        
        for row in rows {
            // Extract columns from markdown table row format: "| col1 | col2 | col3 |"
            if row.contains("|") {
                let columns = row.split(separator: "|")
                    .map { $0.trimmingCharacters(in: .whitespaces) }
                    .filter { !$0.isEmpty } // Remove empty cells from leading/trailing |
                
                if !columns.isEmpty {
                    tableData.append(columns)
                }
            }
        }
        
        if tableData.isEmpty {
            return rows.joined(separator: "\n") + "\n"
        }
        
        // Find the maximum number of columns
        let maxColumns = tableData.map { $0.count }.max() ?? 0
        
        // Normalize all rows to have the same number of columns
        for i in 0..<tableData.count {
            while tableData[i].count < maxColumns {
                tableData[i].append("")
            }
        }
        
        // Add header row (first row)
        if !tableData.isEmpty {
            markdown += "| " + tableData[0].joined(separator: " | ") + " |\n"
            
            // Add separator row
            markdown += "|" + String(repeating: "---|", count: maxColumns) + "\n"
            
            // Add data rows (skip first row which we used as header)
            for i in 1..<tableData.count {
                markdown += "| " + tableData[i].joined(separator: " | ") + " |\n"
            }
        }
        
        return markdown
    }
    
    private func isNextLineTable(_ nextLine: String, attributedString: NSAttributedString, nextLocation: Int) -> Bool {
        let nextLineRange = NSRange(location: nextLocation, length: nextLine.count)
        var isTableRow = false
        attributedString.enumerateAttributes(in: nextLineRange, options: []) { attrs, _, _ in
            if let paragraphStyle = attrs[.paragraphStyle] as? NSParagraphStyle {
                if !paragraphStyle.tabStops.isEmpty || nextLine.contains("\t") {
                    isTableRow = true
                }
            }
        }
        return isTableRow
    }
} 