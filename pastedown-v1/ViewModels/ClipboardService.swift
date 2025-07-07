import Foundation
import SwiftUI
import UIKit

@MainActor
class ClipboardService: ObservableObject {
    private let imageAnalyzer: ImageAnalyzer
    private let settings: SettingsStore
    private let richTextProcessor: RichTextProcessor
    
    init(imageAnalyzer: ImageAnalyzer, settings: SettingsStore, richTextProcessor: RichTextProcessor) {
        self.imageAnalyzer = imageAnalyzer
        self.settings = settings
        self.richTextProcessor = richTextProcessor
    }
    
    func processClipboard() async -> Result<String, ClipboardError> {
        let pasteboard = UIPasteboard.general
        
        guard pasteboard.hasStrings || pasteboard.hasImages else {
            return .failure(.emptyClipboard)
        }
        
        var markdown = ""
        
        // Try to get rich text data from pasteboard
        var attributedString: NSAttributedString?
        
        // Try RTFD first (Rich Text Format with attachments)
        if let rtfdData = pasteboard.data(forPasteboardType: "com.apple.flat-rtfd") {
            attributedString = try? NSAttributedString(data: rtfdData, options: [.documentType: NSAttributedString.DocumentType.rtfd], documentAttributes: nil)
        }
        // Try RTF next
        else if let rtfData = pasteboard.data(forPasteboardType: "public.rtf") {
            attributedString = try? NSAttributedString(data: rtfData, options: [.documentType: NSAttributedString.DocumentType.rtf], documentAttributes: nil)
        }
        // Try HTML
        else if let htmlData = pasteboard.data(forPasteboardType: "public.html") {
            attributedString = try? NSAttributedString(data: htmlData, options: [.documentType: NSAttributedString.DocumentType.html], documentAttributes: nil)
        }
        
        if let attributedString = attributedString {
            // Add front matter if configured
            if !settings.frontMatterFields.isEmpty {
                let frontMatter = MarkdownUtilities.generateFrontMatter(settings: settings)
                markdown = frontMatter + "\n"
            }
            
            // Process attributed string with inline images
            markdown += await richTextProcessor.processAttributedStringWithImages(attributedString)
        } else if let plainText = pasteboard.string {
            // Add front matter if configured
            if !settings.frontMatterFields.isEmpty {
                let frontMatter = MarkdownUtilities.generateFrontMatter(settings: settings)
                markdown = frontMatter + "\n" + plainText
            } else {
                markdown = plainText
            }
            
            // Handle standalone images if any
            if let image = pasteboard.image {
                let altText = await imageAnalyzer.generateAltText(for: image)
                let imageMarkdown = MarkdownUtilities.generateImageMarkdown(altText: altText, settings: settings)
                markdown += "\n\n" + imageMarkdown
            }
        }
        
        return .success(markdown)
    }
}

enum ClipboardError: Error, LocalizedError {
    case emptyClipboard
    case processingError(String)
    
    var errorDescription: String? {
        switch self {
        case .emptyClipboard:
            return "Clipboard is empty"
        case .processingError(let message):
            return "Processing error: \(message)"
        }
    }
} 