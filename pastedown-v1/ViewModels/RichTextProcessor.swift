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
    
    func processAttributedStringWithImages(_ attributedString: NSAttributedString, rawRTF: String? = nil, plainTextReference: String? = nil, contentPreview: String? = nil) async -> String {
        print("processAttributedStringWithImages")
        var markdown = ""
        
        // Add front matter if configured
        if !settings.frontMatterFields.isEmpty {
            let frontMatter = MarkdownUtilities.generateFrontMatter(settings: settings)
            markdown = frontMatter + "\n"
        }
        
        // NEW: Use placeholder-based table detection with raw RTF
        let tableDetectionResult = TableUtilities.detectTablesWithDirectInsertion(in: attributedString, rawRTF: rawRTF)
        print("Detected tables:", tableDetectionResult.tables)
        let detectedTables = tableDetectionResult.tables
        let attributedStringWithTables = tableDetectionResult.attributedStringWithTables

        // Reset the list processor for new content
        ListUtilities.resetProcessor()
        
        // Process the attributed string with tables already converted to markdown
        markdown += await processContentLineByLine(attributedStringWithTables, plainTextReference: plainTextReference, contentPreview: contentPreview)

        return markdown
    }
    
    func processAttributedStringWithFileSaving(_ attributedString: NSAttributedString, rawRTF: String? = nil, plainTextReference: String? = nil, contentPreview: String? = nil) async -> ImageUtilities.ProcessingResult {
        print("processAttributedStringWithFileSaving")
        var markdown = ""
        var allImageResults: [ImageUtilities.ImageResult] = []
        print("add font matter")
        // Add front matter if configured
        if !settings.frontMatterFields.isEmpty {
            let frontMatter = MarkdownUtilities.generateFrontMatter(settings: settings)
            markdown = frontMatter + "\n"
        }
        print("attribute string:", attributedString)
        print("detect tables")
        // NEW: Use placeholder-based table detection with raw RTF
        let tableDetectionResult = TableUtilities.detectTablesWithDirectInsertion(in: attributedString, rawRTF: rawRTF)
        print("Raw RTF:", rawRTF ?? "nil")
        // print("Detected tables:", tableDetectionResult.tables)
        let detectedTables = tableDetectionResult.tables
        let attributedStringWithTables = tableDetectionResult.attributedStringWithTables

        // Reset the list processor for new content
        ListUtilities.resetProcessor()
        
        // Process the attributed string with tables already converted to markdown
        let (contentMarkdown, imageResults) = await processContentLineByLineWithImages(attributedStringWithTables, plainTextReference: plainTextReference, contentPreview: contentPreview)
        markdown += contentMarkdown
        allImageResults.append(contentsOf: imageResults)
        
        // Create final output with files
        return ImageUtilities.createFinalOutput(markdown: markdown, imageResults: allImageResults, settings: settings, contentPreview: contentPreview ?? "")
    }
    
    // MARK: - Helper Methods
    private func processContentLineByLine(_ attributedString: NSAttributedString, plainTextReference: String? = nil, contentPreview: String? = nil) async -> String {
        print("Processing content line by line...")
        var markdown = ""
        var globalImageIndex = 0
        
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
            
            // Collect image tasks for this line
            var imageTasks: [ImageUtilities.ImageTask] = []
            var imageTaskIndex = 0
            
            // First pass: collect image tasks
            attributedString.enumerateAttributes(in: lineRange, options: []) { attrs, range, _ in
                if let attachment = attrs[.attachment] as? NSTextAttachment {
                    if let (image, format) = ImageUtilities.extractImageWithFormat(from: attachment) {
                        imageTasks.append(ImageUtilities.ImageTask(image: image, index: imageTaskIndex, originalFormat: format, attachment: attachment))
                        imageTaskIndex += 1
                    }
                }
            }
            
            // Process images for this line
            let finalContentPreview = contentPreview ?? "untitled"
            let (imageResults, updatedGlobalIndex) = await ImageUtilities.processImages(imageTasks, imageAnalyzer: imageAnalyzer, contentPreview: finalContentPreview, globalImageIndex: globalImageIndex, settings: settings)
            globalImageIndex = updatedGlobalIndex
            var currentImageIndex = 0
            
            // Second pass: process attributes with image results
            attributedString.enumerateAttributes(in: lineRange, options: []) { attrs, range, _ in
                if let attachment = attrs[.attachment] as? NSTextAttachment {
                    print("Attachment:", attachment)
                    // Handle image attachment
                    if let _ = ImageUtilities.extractImageWithFormat(from: attachment) {
                        // Use processed image result
                        if currentImageIndex < imageResults.count {
                            lineMarkdown += imageResults[currentImageIndex].markdown
                            currentImageIndex += 1
                        } else {
                            // Fallback if something went wrong
                            lineMarkdown += ImageUtilities.generateFallbackImageMarkdown(altText: "image", settings: settings)
                        }
                    } else {
                        // Non-image attachment or failed image extraction
                        lineMarkdown += ImageUtilities.generateAttachmentMarkdown()
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
    
    private func processContentLineByLineWithImages(_ attributedString: NSAttributedString, plainTextReference: String? = nil, contentPreview: String? = nil) async -> (String, [ImageUtilities.ImageResult]) {
        print("Processing content line by line with image handling...")
        var markdown = ""
        var globalImageIndex = 0
        var allImageResults: [ImageUtilities.ImageResult] = []
        
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
            
            // Collect image tasks for this line
            var imageTasks: [ImageUtilities.ImageTask] = []
            var imageTaskIndex = 0
            
            // First pass: collect image tasks
            attributedString.enumerateAttributes(in: lineRange, options: []) { attrs, range, _ in
                if let attachment = attrs[.attachment] as? NSTextAttachment {
                    if let (image, format) = ImageUtilities.extractImageWithFormat(from: attachment) {
                        imageTasks.append(ImageUtilities.ImageTask(image: image, index: imageTaskIndex, originalFormat: format, attachment: attachment))
                        imageTaskIndex += 1
                    }
                }
            }
            
            // Process images for this line
            let finalContentPreview = contentPreview ?? "untitled"
            let (imageResults, updatedGlobalIndex) = await ImageUtilities.processImages(imageTasks, imageAnalyzer: imageAnalyzer, contentPreview: finalContentPreview, globalImageIndex: globalImageIndex, settings: settings)
            globalImageIndex = updatedGlobalIndex
            allImageResults.append(contentsOf: imageResults)
            var currentImageIndex = 0
            
            // Second pass: process attributes with image results
            attributedString.enumerateAttributes(in: lineRange, options: []) { attrs, range, _ in
                if let attachment = attrs[.attachment] as? NSTextAttachment {
                    print("Attachment:", attachment)
                    // Handle image attachment
                    if let _ = ImageUtilities.extractImageWithFormat(from: attachment) {
                        // Use processed image result
                        if currentImageIndex < imageResults.count {
                            lineMarkdown += imageResults[currentImageIndex].markdown
                            currentImageIndex += 1
                        } else {
                            // Fallback if something went wrong
                            lineMarkdown += ImageUtilities.generateFallbackImageMarkdown(altText: "image", settings: settings)
                        }
                    } else {
                        // Non-image attachment or failed image extraction
                        lineMarkdown += ImageUtilities.generateAttachmentMarkdown()
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
        
        return (markdown, allImageResults)
    }
} 