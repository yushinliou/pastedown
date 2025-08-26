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
    
    // MARK: - Image Format Detection and Conversion
    
    enum ImageFormat {
        case png
        case jpeg
        case jpeg2000
        case tiff
        case gif
        case webp
        case heif
        case exr
        case unknown
        
        var fileExtension: String {
            switch self {
            case .png: return "png"
            case .jpeg: return "jpg"
            case .jpeg2000: return "jp2"
            case .tiff: return "tiff"
            case .gif: return "gif"
            case .webp: return "webp"
            case .heif: return "heic"
            case .exr: return "exr"
            case .unknown: return "png" // fallback
            }
        }
        
        var mimeType: String {
            switch self {
            case .png: return "image/png"
            case .jpeg: return "image/jpeg"
            case .jpeg2000: return "image/jp2"
            case .tiff: return "image/tiff"
            case .gif: return "image/gif"
            case .webp: return "image/webp"
            case .heif: return "image/heif"
            case .exr: return "image/x-exr"
            case .unknown: return "image/png" // fallback
            }
        }
    }
    
    /// Detects image format from NSTextAttachment
    static func detectImageFormat(from attachment: NSTextAttachment) -> ImageFormat {
        // Try to get data from various sources
        var imageData: Data?
        
        if let contents = attachment.contents {
            imageData = contents
        } else if let fileWrapper = attachment.fileWrapper,
                  let data = fileWrapper.regularFileContents {
            imageData = data
        } else if let image = attachment.image,
                  let data = image.pngData() {
            imageData = data
        }
        
        guard let data = imageData else { return .unknown }
        
        return detectImageFormat(from: data)
    }
    
    /// Detects image format from image data by examining the header bytes
    static func detectImageFormat(from data: Data) -> ImageFormat {
        guard data.count >= 8 else { return .unknown }
        
        let bytes = data.prefix(12).map { $0 }
        
        // PNG: 89 50 4E 47 0D 0A 1A 0A
        if bytes.count >= 8 &&
           bytes[0] == 0x89 && bytes[1] == 0x50 && bytes[2] == 0x4E && bytes[3] == 0x47 &&
           bytes[4] == 0x0D && bytes[5] == 0x0A && bytes[6] == 0x1A && bytes[7] == 0x0A {
            return .png
        }
        
        // JPEG: FF D8 FF
        if bytes.count >= 3 && bytes[0] == 0xFF && bytes[1] == 0xD8 && bytes[2] == 0xFF {
            return .jpeg
        }
        
        // JPEG 2000: 00 00 00 0C 6A 50 20 20 (JP2 signature)
        if bytes.count >= 12 &&
           bytes[0] == 0x00 && bytes[1] == 0x00 && bytes[2] == 0x00 && bytes[3] == 0x0C &&
           bytes[4] == 0x6A && bytes[5] == 0x50 && bytes[6] == 0x20 && bytes[7] == 0x20 {
            return .jpeg2000
        }
        
        // TIFF (Little Endian): 49 49 2A 00
        if bytes.count >= 4 &&
           bytes[0] == 0x49 && bytes[1] == 0x49 && bytes[2] == 0x2A && bytes[3] == 0x00 {
            return .tiff
        }
        
        // TIFF (Big Endian): 4D 4D 00 2A
        if bytes.count >= 4 &&
           bytes[0] == 0x4D && bytes[1] == 0x4D && bytes[2] == 0x00 && bytes[3] == 0x2A {
            return .tiff
        }
        
        // GIF: 47 49 46 38 (GIF8)
        if bytes.count >= 4 &&
           bytes[0] == 0x47 && bytes[1] == 0x49 && bytes[2] == 0x46 && bytes[3] == 0x38 {
            return .gif
        }
        
        // WebP: 52 49 46 46 ... 57 45 42 50 (RIFF...WEBP)
        if bytes.count >= 12 &&
           bytes[0] == 0x52 && bytes[1] == 0x49 && bytes[2] == 0x46 && bytes[3] == 0x46 &&
           bytes[8] == 0x57 && bytes[9] == 0x45 && bytes[10] == 0x42 && bytes[11] == 0x50 {
            return .webp
        }
        
        // HEIF/HEIC: 00 00 00 [size] 66 74 79 70 68 65 69 63
        if bytes.count >= 12 &&
           bytes[0] == 0x00 && bytes[1] == 0x00 && bytes[2] == 0x00 &&
           bytes[4] == 0x66 && bytes[5] == 0x74 && bytes[6] == 0x79 && bytes[7] == 0x70 &&
           bytes[8] == 0x68 && bytes[9] == 0x65 && bytes[10] == 0x69 && bytes[11] == 0x63 {
            return .heif
        }
        
        // EXR (OpenEXR): 76 2F 31 01 (magic number)
        if bytes.count >= 4 &&
           bytes[0] == 0x76 && bytes[1] == 0x2F && bytes[2] == 0x31 && bytes[3] == 0x01 {
            return .exr
        }
        
        return .unknown
    }
    
    /// Converts UIImage to data in the optimal format, preserving original format when possible
    static func convertToOptimalFormat(image: UIImage, originalFormat: ImageFormat, forSaving: Bool = false) -> (data: Data, format: ImageFormat)? {
        print("🔄 Converting image to optimal format - Original: \(originalFormat), Image size: \(image.size), ForSaving: \(forSaving)")
        
        // Validate image first
        guard image.size.width > 0 && image.size.height > 0 else {
            print("❌ Invalid image dimensions: \(image.size)")
            return nil
        }
        
        // Ensure we have a valid CGImage
        guard image.cgImage != nil || image.ciImage != nil else {
            print("❌ No valid CGImage or CIImage found")
            return nil
        }
        
        if forSaving {
            // When saving to file, try to preserve original format
            switch originalFormat {
            case .jpeg, .jpeg2000:
                if let jpegData = image.jpegData(compressionQuality: 0.9) {
                    print("✅ Preserved JPEG format for saving - Size: \(jpegData.count) bytes")
                    return (jpegData, .jpeg)
                }
            case .png:
                if let pngData = image.pngData() {
                    print("✅ Preserved PNG format for saving - Size: \(pngData.count) bytes")
                    return (pngData, .png)
                }
            case .tiff:
                // For TIFF, convert to PNG since iOS doesn't have native TIFF writing
                if let pngData = image.pngData() {
                    print("✅ Converted TIFF to PNG for saving - Size: \(pngData.count) bytes")
                    return (pngData, .tiff) // Keep original format reference
                }
            case .gif, .webp, .heif, .exr:
                // For formats that iOS can't write natively, convert to PNG but keep format reference
                if let pngData = image.pngData() {
                    print("✅ Converted \(originalFormat) to PNG for saving - Size: \(pngData.count) bytes")
                    return (pngData, originalFormat) // Keep original format reference
                }
            case .unknown:
                if let pngData = image.pngData() {
                    print("✅ Converted unknown format to PNG for saving - Size: \(pngData.count) bytes")
                    return (pngData, .png)
                }
            }
        } else {
            // For base64 embedding, optimize for compatibility
            switch originalFormat {
            case .jpeg, .jpeg2000:
                // For JPEG formats, use JPEG compression to maintain quality and size
                if let jpegData = image.jpegData(compressionQuality: 0.9) {
                    print("✅ Converted to JPEG - Size: \(jpegData.count) bytes")
                    return (jpegData, .jpeg)
                } else {
                    print("⚠️ JPEG conversion failed, trying PNG fallback")
                }
            case .png:
                // PNG supports transparency, so keep as PNG
                if let pngData = image.pngData() {
                    print("✅ Converted to PNG - Size: \(pngData.count) bytes")
                    return (pngData, .png)
                } else {
                    print("⚠️ PNG conversion failed")
                }
            case .tiff, .gif, .webp, .heif, .exr:
                // Convert to PNG for broad compatibility while preserving transparency
                if let pngData = image.pngData() {
                    print("✅ Converted \(originalFormat) to PNG - Size: \(pngData.count) bytes")
                    return (pngData, .png)
                } else {
                    print("⚠️ PNG conversion failed for \(originalFormat)")
                }
            case .unknown:
                // Default to PNG for unknown formats
                if let pngData = image.pngData() {
                    print("✅ Converted unknown format to PNG - Size: \(pngData.count) bytes")
                    return (pngData, .png)
                } else {
                    print("⚠️ PNG conversion failed for unknown format")
                }
            }
        }
        
        // Final fallback to PNG with more debug info
        print("🔄 Attempting final fallback to PNG")
        if let pngData = image.pngData() {
            print("✅ Final fallback to PNG succeeded - Size: \(pngData.count) bytes")
            return (pngData, .png)
        }
        
        print("❌ All image conversion attempts failed - returning nil")
        return nil
    }
    
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
    
    /// Extracts both UIImage and format from NSTextAttachment in a coordinated way
    static func extractImageWithFormat(from attachment: NSTextAttachment) -> (image: UIImage, format: ImageFormat)? {
        // Method 1: Try to get image from contents first (preserves original format)
        if let contents = attachment.contents,
           let image = UIImage(data: contents) {
            let format = detectImageFormat(from: contents)
            return (image, format)
        }
        
        // Method 2: Try fileWrapper if available (preserves original format)
        if let fileWrapper = attachment.fileWrapper,
           let data = fileWrapper.regularFileContents,
           let image = UIImage(data: data) {
            let format = detectImageFormat(from: data)
            return (image, format)
        }
        
        // Method 3: Direct image property (format unknown, assume PNG)
        if let image = attachment.image {
            // We don't have original data, so we can't detect the original format
            // Default to PNG as it's the most common format for processed images
            return (image, .png)
        }
        
        return nil
    }
    
    // MARK: - Image Processing Tasks
    
    struct ImageTask {
        let image: UIImage
        let index: Int
        let originalFormat: ImageFormat
        let attachment: NSTextAttachment
    }
    
    struct ImageResult {
        let index: Int
        let altText: String
        let markdown: String
        let format: ImageFormat
        let imageData: Data? // For saving to file
    }
    
    struct ProcessingResult {
        let markdown: String
        let fileURL: URL?
        let fileType: FileType
        
        enum FileType {
            case markdown
            case zip
            case none
        }
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
                    let (markdown, finalFormat, imageData) = generateImageMarkdownWithData(image: task.image, altText: altText, imageIndex: imageIndex, contentPreview: contentPreview, originalFormat: task.originalFormat, settings: settings)
                    return ImageResult(index: task.index, altText: altText, markdown: markdown, format: finalFormat, imageData: imageData)
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
    
    /// Generates markdown for an image with various handling options (with image data for saving)
    static func generateImageMarkdownWithData(image: UIImage, altText: String, imageIndex: Int, contentPreview: String, originalFormat: ImageFormat, settings: SettingsStore) -> (markdown: String, format: ImageFormat, imageData: Data?) {
        print("🎯 Generating image markdown with data - Index: \(imageIndex), Format: \(originalFormat), Handling: \(settings.imageHandling)")
        
        switch settings.imageHandling {
        case .ignore:
            print("ℹ️ Ignoring image")
            return ("<!-- Image ignored -->", originalFormat, nil)
        case .base64:
            print("📷 Converting image to base64")
            if let (imageData, finalFormat) = convertToOptimalFormat(image: image, originalFormat: originalFormat, forSaving: false) {
                let base64 = imageData.base64EncodedString()
                let truncatedBase64 = base64.prefix(50) + "..." // Show first 50 chars for logging
                print("✅ Base64 generated successfully - Format: \(finalFormat), Length: \(base64.count) chars, Preview: \(truncatedBase64)")
                let markdown = "![\(altText)](data:\(finalFormat.mimeType);base64,\(base64))"
                return (markdown, finalFormat, nil) // No separate image data needed for base64
            } else {
                print("❌ Base64 conversion failed - using fallback")
                return ("![\(altText)](<image conversion failed>)", originalFormat, nil)
            }
        case .saveToFolder:
            print("💾 Generating save to folder path and image data")
            let finalFormat = determineOutputFormat(originalFormat: originalFormat)
            let imagePath = settings.processImageFolderPath(imageIndex: imageIndex, contentPreview: contentPreview, fileExtension: finalFormat.fileExtension)
            print("✅ Generated folder path: \(imagePath)")
            
            // Get image data for saving
            if let (imageData, _) = convertToOptimalFormat(image: image, originalFormat: originalFormat, forSaving: true) {
                return ("![\(altText)](\(imagePath))", finalFormat, imageData)
            } else {
                print("❌ Failed to convert image data for saving")
                return ("![\(altText)](\(imagePath))", finalFormat, nil)
            }
        }
    }
    
    /// Generates markdown for an image with various handling options (backward compatibility)
    static func generateImageMarkdown(image: UIImage, altText: String, imageIndex: Int, contentPreview: String, originalFormat: ImageFormat, settings: SettingsStore) -> (markdown: String, format: ImageFormat) {
        let (markdown, format, _) = generateImageMarkdownWithData(image: image, altText: altText, imageIndex: imageIndex, contentPreview: contentPreview, originalFormat: originalFormat, settings: settings)
        return (markdown, format)
    }
    
    /// Determines the best output format for saving images - now preserves original format
    static func determineOutputFormat(originalFormat: ImageFormat) -> ImageFormat {
        switch originalFormat {
        case .jpeg, .jpeg2000, .png, .tiff, .gif, .webp, .heif, .exr:
            return originalFormat  // Keep original format
        case .unknown:
            return .png   // Convert unknown to PNG for compatibility
        }
    }
    
    /// Creates final output with appropriate file based on image handling mode
    static func createFinalOutput(markdown: String, imageResults: [ImageResult], settings: SettingsStore, contentPreview: String = "") -> ProcessingResult {
        let filename = settings.generateFinalOutputFilename(contentPreview: contentPreview)
        
        switch settings.imageHandling {
        case .ignore, .base64:
            // Create simple markdown file
            if let fileURL = FileManagerUtilities.createMarkdownFile(content: markdown, filename: filename) {
                return ProcessingResult(markdown: markdown, fileURL: fileURL, fileType: .markdown)
            } else {
                return ProcessingResult(markdown: markdown, fileURL: nil, fileType: .none)
            }
            
        case .saveToFolder:
            // Create zip file with markdown and images
            let imageResultsWithData = imageResults.filter { $0.imageData != nil }
            
            if !imageResultsWithData.isEmpty {
                if let zipURL = FileManagerUtilities.createZipFile(
                    markdownContent: markdown,
                    markdownFilename: filename,
                    imageResults: imageResultsWithData
                ) {
                    return ProcessingResult(markdown: markdown, fileURL: zipURL, fileType: .zip)
                }
            }
            
            // Fallback to markdown file if zip creation fails
            if let fileURL = FileManagerUtilities.createMarkdownFile(content: markdown, filename: filename) {
                return ProcessingResult(markdown: markdown, fileURL: fileURL, fileType: .markdown)
            } else {
                return ProcessingResult(markdown: markdown, fileURL: nil, fileType: .none)
            }
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