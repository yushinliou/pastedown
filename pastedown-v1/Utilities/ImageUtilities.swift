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
    static func processImages(_ imageTasks: [ImageTask], imageAnalyzer: ImageAnalyzer, contentPreview: String, globalImageIndex: Int, settings: SettingsStore) async -> ([ImageResult], Int) {
        var currentGlobalIndex = globalImageIndex
        let results = await withTaskGroup(of: ImageResult.self) { group in
            // Add tasks for each image
            for task in imageTasks {
                let imageIndex = currentGlobalIndex + task.index + 1
                group.addTask {
                    let altText = await imageAnalyzer.generateAltText(for: task.image)
                    let markdown = generateImageMarkdown(image: task.image, altText: altText, imageIndex: imageIndex, contentPreview: contentPreview, settings: settings)
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
        
        currentGlobalIndex += imageTasks.count
        return (results, currentGlobalIndex)
    }
    
    // MARK: - Image Markdown Generation
    
    /// Generates markdown for an image with various handling options
    static func generateImageMarkdown(image: UIImage, altText: String, imageIndex: Int, contentPreview: String, settings: SettingsStore) -> String {
        switch settings.imageHandling {
        case .ignore:
            return "<!-- Image ignored -->"
        case .base64:
            if let imageData = image.pngData() {
                let base64 = imageData.base64EncodedString()
                return "![image](data:image/png;base64,\(base64))"
            } else {
                return "![\(altText)](<image>)"
            }
        case .saveToFolder:
            let imagePath = settings.processImageFolderPath(imageIndex: imageIndex, contentPreview: contentPreview)
            return "![\(altText)](\(imagePath))"
        }
    }
    
    /// Generates markdown when image extraction fails but attachment exists
    static func generateFallbackImageMarkdown(altText: String, settings: SettingsStore) -> String {
        switch settings.imageHandling {
        case .ignore:
            return "<!-- Image ignored -->"
        case .base64:
            return "![\(altText)](<image>)"
        case .saveToFolder:
            return "![\(altText)](<image>)"
        }
    }
    
    /// Generates markdown for non-image attachments
    static func generateAttachmentMarkdown() -> String {
        return "<!-- ![attachment] -->"
    }
}