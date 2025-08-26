import Foundation
import SwiftUI
import UIKit
import UniformTypeIdentifiers

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
        let result = await processClipboardWithFiles()
        switch result {
        case .success(let processingResult):
            return .success(processingResult.markdown)
        case .failure(let error):
            return .failure(error)
        }
    }
    
    func processClipboardWithFiles() async -> Result<ImageUtilities.ProcessingResult, ClipboardError> {
        let pasteboard = UIPasteboard.general
        
        guard pasteboard.hasStrings || pasteboard.hasImages else {
            return .failure(.emptyClipboard)
        }
        
        var markdown = ""
        
        // Try to get rich text data from pasteboard and extract raw RTF
        var attributedString: NSAttributedString?
        var rawRTFString: String?
        var plainTextReference: String?
        
        // Always try to get plain text for checkbox state validation
        plainTextReference = pasteboard.string
        
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
            // Generate filename based on content preview
            let contentPreview = attributedString.string.prefix(100).trimmingCharacters(in: .whitespacesAndNewlines)
            let contentPreviewString = String(contentPreview)
            
            // Process attributed string with inline images using new RTF-based table detection
            let processingResult = await richTextProcessor.processAttributedStringWithFileSaving(attributedString, rawRTF: rawRTFString, plainTextReference: plainTextReference, contentPreview: contentPreviewString)
            return .success(processingResult)
            
        } else if let plainText = pasteboard.string {
            // Handle plain text with front matter
            var markdown = ""
            if !settings.frontMatterFields.isEmpty {
                let frontMatter = MarkdownUtilities.generateFrontMatter(settings: settings)
                markdown = frontMatter + "\n" + plainText
            } else {
                markdown = plainText
            }
            
            // Create simple result for plain text
            let contentPreview = String(plainText.prefix(100)).trimmingCharacters(in: .whitespacesAndNewlines)
            let simpleResult = ImageUtilities.createFinalOutput(markdown: markdown, imageResults: [], settings: settings, contentPreview: contentPreview)
            return .success(simpleResult)
        }
        
        return .failure(.emptyClipboard)
    }
    
    // MARK: - RTF Extraction Helper
    private func extractRTFFromRTFD(_ rtfdData: Data) -> String? {
        // try to extract RTF from RTFD 
        guard let rtfdFileWrapper = FileWrapper(serializedRepresentation: rtfdData),
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
