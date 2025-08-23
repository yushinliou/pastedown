//
//  ImageUtilities.swift
//  pastedown-v1
//
//  Created by Claude Code on 2025/8/23.
//

import Foundation
import SwiftUI
import UIKit

struct ImageUtilities {
    
    // MARK: - Image Extraction from NSTextAttachment
    
    /// Extracts UIImage from NSTextAttachment using multiple fallback methods
    static func extractImage(from attachment: NSTextAttachment) -> UIImage? {
        // Method 1: Direct image property (most common)
        if let image = attachment.image {
            return image
        }
        
        // Method 2: Try to get image from contents
        if let contents = attachment.contents {
            return UIImage(data: contents)
        }
        
        // Method 3: Try fileWrapper if available
        if let fileWrapper = attachment.fileWrapper,
           let data = fileWrapper.regularFileContents {
            return UIImage(data: data)
        }
        
        return nil
    }
    
    // MARK: - Image Processing Tasks
    
    struct ImageTask {
        let image: UIImage
        let index: Int
    }
    
    struct ImageResult {
        let index: Int
        let altText: String
        let markdown: String
    }
    
    /// Processes a batch of images and generates markdown with alt text
    static func processImages(_ imageTasks: [ImageTask], imageAnalyzer: ImageAnalyzer, settings: SettingsStore) async -> [ImageResult] {
        return await withTaskGroup(of: ImageResult.self) { group in
            // Add tasks for each image
            for task in imageTasks {
                group.addTask {
                    let altText = await imageAnalyzer.generateAltText(for: task.image)
                    let markdown = generateImageMarkdown(image: task.image, altText: altText, settings: settings)
                    return ImageResult(index: task.index, altText: altText, markdown: markdown)
                }
            }
            
            // Collect results
            var results: [ImageResult] = []
            for await result in group {
                results.append(result)
            }
            
            // Sort by index to maintain order
            results.sort { $0.index < $1.index }
            return results
        }
    }
    
    // MARK: - Image Markdown Generation
    
    /// Generates markdown for an image with various handling options
    static func generateImageMarkdown(image: UIImage, altText: String, settings: SettingsStore) -> String {
        switch settings.imageHandling {
        case .ignore:
            return "<!-- Image ignored -->"
        case .saveLocal:
            if let imageData = image.pngData() {
                let base64 = imageData.base64EncodedString()
                return "![image](data:image/png;base64,\(base64))"
            } else {
                return "![\(altText)](./images/image.png)"
            }
        case .saveCustom:
            if let imageData = image.pngData() {
                let base64 = imageData.base64EncodedString()
                return "![image](data:image/png;base64,\(base64))"
            } else {
                return "![\(altText)](.//\(settings.customImageFolder)/image.png)"
            }
        }
    }
    
    /// Generates markdown when image extraction fails but attachment exists
    static func generateFallbackImageMarkdown(altText: String, settings: SettingsStore) -> String {
        switch settings.imageHandling {
        case .ignore:
            return "<!-- Image ignored -->"
        case .saveLocal:
            return "![\(altText)](<image>)"
        case .saveCustom:
            return "![\(altText)](<image>)"
        }
    }
    
    /// Generates markdown for non-image attachments
    static func generateAttachmentMarkdown() -> String {
        return "<!-- ![attachment] -->"
    }
}