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
        
        // Debug: Check what's actually in the pasteboard
        print("=== Pasteboard Debug ===")
        print("hasStrings: \(pasteboard.hasStrings)")
        print("hasImages: \(pasteboard.hasImages)")
        print("types: \(pasteboard.types)")
        print("=======================")
        
        guard pasteboard.hasStrings || pasteboard.hasImages || pasteboard.contains(pasteboardTypes: ["public.png", "public.jpeg"]) else {
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
            print("Extracted raw RTF string from com.apple.flat-rtfd")
        }
        // Try RTF next
        else if let rtfData = pasteboard.data(forPasteboardType: "public.rtf") {
            attributedString = try? NSAttributedString(data: rtfData, options: [.documentType: NSAttributedString.DocumentType.rtf], documentAttributes: nil)
            // Extract RTF string directly
            rawRTFString = String(data: rtfData, encoding: .ascii) ?? String(data: rtfData, encoding: .utf8)
            print("Extracted raw RTF string from public.rtf")
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
            print("give rawRTF sting:", rawRTFString ?? "nil")
            print("------------------------------")
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

        } else if pasteboard.hasImages {
            // Handle image-only content
            return await processImageOnlyClipboard()
        }

        return .failure(.emptyClipboard)
    }
    
    private func extractRTFFromRTFD(_ rtfdData: Data) -> String? {
        guard let rtfdFileWrapper = FileWrapper(serializedRepresentation: rtfdData),
            let fileWrappers = rtfdFileWrapper.fileWrappers else {
            return nil
        }
        
        var rtfFileWrapper = fileWrappers["TXT.rtf"]
        
        if rtfFileWrapper == nil {
            rtfFileWrapper = fileWrappers.first { key, _ in
                key.lowercased().hasSuffix(".rtf")
            }?.value
        }
        
        guard let rtfData = rtfFileWrapper?.regularFileContents else {
            return nil
        }
        
        // try multiple encodings to decode RTF data
        let encodings: [(String.Encoding, String)] = [
            (.ascii, "ASCII"),
            (.utf8, "UTF-8"),
            (.windowsCP1252, "Windows-1252"),
            (.macOSRoman, "Mac OS Roman"),
            (.isoLatin1, "ISO Latin 1")
        ]
        
        for (encoding, name) in encodings {
            // Use lossy conversion to allow un-decodable characters to be replaced
            let decoded = String(data: rtfData, encoding: encoding)
            
            if let decoded = decoded, !decoded.isEmpty {
                print("✅ Decoded RTF with \(name): \(decoded.count) characters")
                
                // Basic validation: check for RTF header
                if decoded.hasPrefix("{\\rtf") || decoded.contains("{\\rtf") {
                    print("✅ Valid RTF format detected")
                    return decoded
                } else {
                    print("⚠️ Decoded but doesn't look like valid RTF")
                }
            }
        }
        
        print("❌ Failed to decode RTF with any encoding")
        return nil
    }


    // MARK: - Image-Only Processing
    private func processImageOnlyClipboard() async -> Result<ImageUtilities.ProcessingResult, ClipboardError> {
        let pasteboard = UIPasteboard.general
        var images: [UIImage] = []
        
        // Try to get images from pasteboard
        if let pasteboardImages = pasteboard.images {
            images = pasteboardImages
        } else {
            // Try to get image data directly from pasteboard types
            for type in ["public.png", "public.jpeg", "public.tiff", "public.heif"] {
                if let imageData = pasteboard.data(forPasteboardType: type),
                   let image = UIImage(data: imageData) {
                    images.append(image)
                }
            }
        }
        
        guard !images.isEmpty else {
            return .failure(.emptyClipboard)
        }
        
        // Create attributed string with image attachments
        let mutableAttributedString = NSMutableAttributedString()
        
        for (index, image) in images.enumerated() {
            // Create text attachment for the image
            let attachment = NSTextAttachment()
            attachment.image = image
            
            // Create attributed string with the attachment
            let attachmentString = NSAttributedString(attachment: attachment)
            mutableAttributedString.append(attachmentString)
            
            // Add newline between multiple images
            if index < images.count - 1 {
                mutableAttributedString.append(NSAttributedString(string: "\n"))
            }
        }
        
        // Process using existing logic
        let contentPreview = "clipboard-images"
        print("give nil rawRTF")
        let processingResult = await richTextProcessor.processAttributedStringWithFileSaving(mutableAttributedString, rawRTF: nil, plainTextReference: nil, contentPreview: contentPreview)
        return .success(processingResult)
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
