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
        
        // Try to get rich text data from pasteboard and extract raw RTF
        var attributedString: NSAttributedString?
        var rawRTFString: String?
        
        // Try RTFD first (Rich Text Format with attachments)
        if let rtfdData = pasteboard.data(forPasteboardType: "com.apple.flat-rtfd") {
            attributedString = try? NSAttributedString(data: rtfdData, options: [.documentType: NSAttributedString.DocumentType.rtfd], documentAttributes: nil)
            // Extract RTF string from RTFD
            rawRTFString = extractRTFFromRTFD(rtfdData)
        }
        // Try RTF next
        else if let rtfData = pasteboard.data(forPasteboardType: "public.rtf") {
            attributedString = try? NSAttributedString(data: rtfData, options: [.documentType: NSAttributedString.DocumentType.rtf], documentAttributes: nil)
            // Extract RTF string directly
            rawRTFString = String(data: rtfData, encoding: .ascii) ?? String(data: rtfData, encoding: .utf8)
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
            
            // Process attributed string with inline images using new RTF-based table detection
            markdown += await richTextProcessor.processAttributedStringWithImages(attributedString, rawRTF: rawRTFString)
            
            // Handle standalone images if any
            if let image = pasteboard.image {
                print("Handle standalone images if any")
                let altText = await imageAnalyzer.generateAltText(for: image)
                let imageMarkdown = MarkdownUtilities.generateImageMarkdown(altText: altText, settings: settings)
                markdown += "\n\n" + imageMarkdown
            }
        } else if let plainText = pasteboard.string {
            // Add front matter if configured
            if !settings.frontMatterFields.isEmpty {
                let frontMatter = MarkdownUtilities.generateFrontMatter(settings: settings)
                markdown = frontMatter + "\n" + plainText
            } else {
                markdown = plainText
            }
        }
        
        return .success(markdown)
    }
    
    // MARK: - RTF Extraction Helper
    private func extractRTFFromRTFD(_ rtfdData: Data) -> String? {
        // try to extract RTF from RTFD 
        guard let rtfdFileWrapper = try? FileWrapper(serializedRepresentation: rtfdData),
            let fileWrappers = rtfdFileWrapper.fileWrappers else {
            return nil
        }
        // try to find TXT.rtf
        var rtfFileWrapper = fileWrappers["TXT.rtf"]
        // if not found, try to find any .rtf file
        if rtfFileWrapper == nil {
            rtfFileWrapper = fileWrappers.first { key, _ in
                key.lowercased().hasSuffix(".rtf")
            }?.value
        }
        // if not found, return nil
        guard let rtfData = rtfFileWrapper?.regularFileContents else {
            return nil
        }
        // try to decode to original RTF string
        let rtfString = String(data: rtfData, encoding: .ascii)
            ?? String(data: rtfData, encoding: .utf8)
        if let rtfString = rtfString {
        }
        return rtfString
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
