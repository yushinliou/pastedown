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
    
    func processAttributedStringWithImages(_ attributedString: NSAttributedString, rawRTF: String? = nil, plainTextReference: String? = nil) async -> String {
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
        
        // Add front matter if configured
        if !settings.frontMatterFields.isEmpty {
            let frontMatter = MarkdownUtilities.generateFrontMatter(settings: settings)
            markdown = frontMatter + "\n"
        }
        
        // NEW: Use placeholder-based table detection with raw RTF
        let tableDetectionResult = TableUtilities.detectTablesWithDirectInsertion(in: attributedString, rawRTF: rawRTF)
        let detectedTables = tableDetectionResult.tables
        let attributedStringWithTables = tableDetectionResult.attributedStringWithTables

        // Reset the list processor for new content
        ListUtilities.resetProcessor()
        
        // Process the attributed string with tables already converted to markdown
        markdown += await processContentLineByLine(attributedStringWithTables, imageAltTexts: altTexts, plainTextReference: plainTextReference)

        return markdown
    }
    
    // MARK: - Helper Methods
    private func processContentLineByLine(_ attributedString: NSAttributedString, imageAltTexts: [String], plainTextReference: String? = nil) async -> String {
        var markdown = ""
        var imageIndex = 0
        
        let fullText = attributedString.string
        let nsString = fullText as NSString
        let lines = fullText.components(separatedBy: .newlines)
        var currentLocation = 0
        
        // Split plain text reference into lines for line-by-line comparison
        let plainTextLines = plainTextReference?.components(separatedBy: .newlines) ?? []
        
        for (lineIndex, line) in lines.enumerated() {
            if line.isEmpty {
                if lineIndex < lines.count - 1 {
                    markdown += "\n"
                    currentLocation += 1
                }
                continue
            }
            
            var lineMarkdown = ""
            let lineRange = nsString.range(of: line, options: [], range: NSRange(location: currentLocation, length: nsString.length - currentLocation))
            
            // Process each attribute range for formatting
            attributedString.enumerateAttributes(in: lineRange, options: []) { attrs, range, _ in
                if let attachment = attrs[.attachment] as? NSTextAttachment {
                    // Handle image attachment
                    if let image = attachment.image {
                        let altText = imageIndex < imageAltTexts.count ? imageAltTexts[imageIndex] : "image"
                        let imageMarkdown = MarkdownUtilities.generateImageMarkdownWithBase64(image: image, altText: altText, settings: settings)
                        lineMarkdown += imageMarkdown
                        imageIndex += 1
                    } else {
                        lineMarkdown += "<!-- ![attachment] -->"
                    }
                } else if let paragraphStyle = attrs[.paragraphStyle] as? NSParagraphStyle, // skip table block
                          paragraphStyle.description.contains("NSTextTableBlock") {
                    // Handle table block
                    lineMarkdown += ""
                }
                else { // Handle regular text and list items with formatting
                    let substring = attributedString.attributedSubstring(from: range).string
                    var formattedText = substring
                    
                    // Apply only formatting (links, bold, etc.) but NOT list processing here
                    formattedText = MarkdownUtilities.convertTextWithAttributesNoList(formattedText, attributes: attrs)
                    
                    lineMarkdown += formattedText
                }
            }
            
            // Process list items once per line (after all formatting has been applied)
            if lineRange.length > 0 {
                let firstCharRange = NSRange(location: lineRange.location, length: 1)
                attributedString.enumerateAttributes(in: firstCharRange, options: []) { attrs, _, _ in
                    // Get line-specific plain text for this line
                    let lineSpecificPlainText = lineIndex < plainTextLines.count ? plainTextLines[lineIndex] : nil
                    
                    // Apply list processing once per line
                    // let listProcessedText = MarkdownUtilities.handleListItems(lineMarkdown, attributes: attrs, plainTextReference: lineSpecificPlainText)
                    let listProcessedText = ListUtilities.processListItem(lineMarkdown, attributes: attrs, plainTextReference: lineSpecificPlainText)
                    if listProcessedText != lineMarkdown {
                        lineMarkdown = listProcessedText
                    }
                    
                    // Check for headings at line level
                    let headingResult = MarkdownUtilities.convertHeadings(lineMarkdown, attributes: attrs)
                    if headingResult != lineMarkdown {
                        lineMarkdown = headingResult
                    }
                }
            }
            
            markdown += lineMarkdown
            
            if lineIndex < lines.count - 1 {
                markdown += "\n"
            }          
            currentLocation = lineRange.location + lineRange.length + 1
        }
        
        return markdown
    }
} 