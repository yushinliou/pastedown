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
        
        // Now enumerate again and build the markdown
        var imageIndex = 0
        attributedString.enumerateAttributes(in: NSRange(location: 0, length: attributedString.length), options: []) { attrs, range, _ in
            if let attachment = attrs[.attachment] as? NSTextAttachment {
                // Handle image attachment
                if let image = attachment.image {
                    let altText = imageIndex < altTexts.count ? altTexts[imageIndex] : "image"
                    let imageMarkdown = MarkdownUtilities.generateImageMarkdownWithBase64(image: image, altText: altText, settings: settings)
                    markdown += imageMarkdown
                    imageIndex += 1
                } else {
                    // Fallback for attachments without images
                    markdown += "<!-- ![attachment] -->"
                }
            } else {
                // Handle regular text with formatting
                let substring = attributedString.attributedSubstring(from: range).string
                let formattedText = MarkdownUtilities.convertTextWithAttributes(substring, attributes: attrs)
                markdown += formattedText
            }
        }
        
        return markdown
    }
} 