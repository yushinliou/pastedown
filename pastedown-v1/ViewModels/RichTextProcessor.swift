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
    
    func processAttributedStringWithImages(_ attributedString: NSAttributedString, rawRTF: String? = nil) async -> String {
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
        let tableDetectionResult = TableUtilities.detectTablesWithPlaceholders(in: attributedString, rawRTF: rawRTF)
        let detectedTables = tableDetectionResult.tables
        let attributedStringWithPlaceholders = tableDetectionResult.attributedStringWithPlaceholders
        
        if !detectedTables.isEmpty {
            print("Found \(detectedTables.count) tables using RTF-based detection")
        }
        else {
            print("No tables found")
        }
        // Process the attributed string with placeholders (this will include placeholders in the markdown)
        markdown += await processContentLineByLine(attributedStringWithPlaceholders, imageAltTexts: altTexts)
        print("================================================")
        print("[processContentLineByLine markdown]\(markdown)")
        print("================================================")
        // Replace placeholders with actual table markdown
        markdown = TableUtilities.replacePlaceholdersWithMarkdown(markdown, tables: detectedTables)
        print("================================================")
        print("[replacePlaceholdersWithMarkdown markdown]\(markdown)")
        print("================================================")
        
        return markdown
    }
    
    private func processContentLineByLine(_ attributedString: NSAttributedString, imageAltTexts: [String]) async -> String {
        var markdown = ""
        var imageIndex = 0
        
        let fullText = attributedString.string
        let lines = fullText.components(separatedBy: .newlines)
        var currentLocation = 0
        
        for (lineIndex, line) in lines.enumerated() {
            if line.isEmpty {
                if lineIndex < lines.count - 1 {
                    markdown += "\n"
                    print("[handle empty line]")
                    currentLocation += 1
                }
                continue
            }
            
            var lineMarkdown = ""
            let lineRange = NSRange(location: currentLocation, length: line.count)
            
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
                } else if let paragraphStyle = attrs[.paragraphStyle] as? NSParagraphStyle,
                          paragraphStyle.description.contains("NSTextTableBlock") {
                    // Handle table block
                    lineMarkdown += "" // skip table block
                    print("[handle table block lineMarkdown]\(lineMarkdown)")
                }
                else {
                    // Handle regular text with formatting
                    let substring = attributedString.attributedSubstring(from: range).string
                    
                    var formattedText = substring
                    formattedText = MarkdownUtilities.handleLinks(formattedText, attributes: attrs)
                    formattedText = MarkdownUtilities.handleListItems(formattedText, attributes: attrs)
                    formattedText = MarkdownUtilities.applyTextFormatting(formattedText, attributes: attrs)
                    
                    lineMarkdown += formattedText
                    print("[handle regular text lineMarkdown]\(lineMarkdown)")
                }
            }
            
            // Check for headings at line level
            if lineRange.length > 0 {
                let firstCharRange = NSRange(location: lineRange.location, length: 1)
                attributedString.enumerateAttributes(in: firstCharRange, options: []) { attrs, _, _ in
                    let headingResult = MarkdownUtilities.convertHeadings(lineMarkdown, attributes: attrs)
                    if headingResult != lineMarkdown {
                        lineMarkdown = headingResult
                    }
                }
            }
            
            markdown += lineMarkdown
            
            if lineIndex < lines.count - 1 {
                markdown += "\n"
                print("[handle new line]")
            }
            
            currentLocation += line.count + 1
        }
        
        return markdown
    }
} 