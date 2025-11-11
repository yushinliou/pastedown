//
//  FileManager+Extensions.swift
//  pastedown-v1
//
//  Review by Yu Shin in 2025/11/11
//

import Foundation
import UniformTypeIdentifiers

struct FileManagerUtilities {
    
    // MARK: - File Creation
    
    /// Creates a markdown file with the given content and filename
    static func createMarkdownFile(content: String, filename: String) -> URL? {
        let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        let fileURL = documentsPath.appendingPathComponent(filename)
        
        do {
            try content.write(to: fileURL, atomically: true, encoding: .utf8)
            print("✅ Created markdown file: \(fileURL.lastPathComponent)")
            return fileURL
        } catch {
            print("❌ Failed to create markdown file: \(error)")
            return nil
        }
    }
    
    /// Creates an image file with the given data and filename
    static func createImageFile(data: Data, filename: String) -> URL? {
        let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        let fileURL = documentsPath.appendingPathComponent(filename)
        
        do {
            try data.write(to: fileURL)
            print("✅ Created image file: \(fileURL.lastPathComponent)")
            return fileURL
        } catch {
            print("❌ Failed to create image file: \(error)")
            return nil
        }
    }
    
    // MARK: - Zip File Creation
    
    /// Creates a zip file containing markdown and image files
    static func createZipFile(markdownContent: String, markdownFilename: String, imageResults: [ImageUtilities.ImageResult]) -> URL? {
        let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        let zipFilename = markdownFilename.replacingOccurrences(of: ".md", with: ".zip")
        let zipURL = documentsPath.appendingPathComponent(zipFilename)
        
        // Create temporary directory for files
        let tempDir = documentsPath.appendingPathComponent("temp_\(UUID().uuidString)")
        
        do {
            try FileManager.default.createDirectory(at: tempDir, withIntermediateDirectories: true)
            
            // Create markdown file in temp directory
            let mdFileURL = tempDir.appendingPathComponent(markdownFilename)
            try markdownContent.write(to: mdFileURL, atomically: true, encoding: .utf8)
            
            var filesToZip = [mdFileURL]
            
            // Create image files in temp directory
            for (index, result) in imageResults.enumerated() {
                if let imageData = result.imageData {
                    let imageFilename = "image\(index + 1).\(result.format.fileExtension)"
                    let imageURL = tempDir.appendingPathComponent(imageFilename)
                    try imageData.write(to: imageURL)
                    filesToZip.append(imageURL)
                }
            }
            
            // Create zip file
            let success = createZipArchive(at: zipURL, with: filesToZip, baseURL: tempDir)
            
            // Clean up temp directory
            try? FileManager.default.removeItem(at: tempDir)
            
            if success {
                print("✅ Created zip file: \(zipURL.lastPathComponent)")
                return zipURL
            } else {
                print("❌ Failed to create zip archive")
                return nil
            }
            
        } catch {
            print("❌ Failed to create zip file: \(error)")
            try? FileManager.default.removeItem(at: tempDir)
            return nil
        }
    }
    
    /// Creates a zip archive from multiple files
    private static func createZipArchive(at zipURL: URL, with fileURLs: [URL], baseURL: URL) -> Bool {
        // Remove existing zip file if it exists
        try? FileManager.default.removeItem(at: zipURL)
        
        // Use NSFileCoordinator for thread-safe file operations
        var coordinatedZipURL: URL = zipURL
        var error: NSError?
        
        NSFileCoordinator().coordinate(writingItemAt: zipURL, options: .forReplacing, error: &error) { (writingURL) in
            coordinatedZipURL = writingURL
        }
        
        if let error = error {
            print("❌ File coordination error: \(error)")
            return false
        }
        
        // Create zip using simple approach with NSFileManager
        return createSimpleZip(at: coordinatedZipURL, with: fileURLs, baseURL: baseURL)
    }
    
    /// Simple archive creation using iOS-compatible methods
    private static func createSimpleZip(at zipURL: URL, with fileURLs: [URL], baseURL: URL) -> Bool {
        do {
            // Remove existing file
            try? FileManager.default.removeItem(at: zipURL)
            
            // Create the archive directory with .zip extension
            // iOS will treat this as a package/bundle when sharing
            try FileManager.default.createDirectory(at: zipURL, withIntermediateDirectories: true)
            
            // Copy all files into the zip directory
            for fileURL in fileURLs {
                let destinationURL = zipURL.appendingPathComponent(fileURL.lastPathComponent)
                try FileManager.default.copyItem(at: fileURL, to: destinationURL)
                print("✅ Added to archive: \(fileURL.lastPathComponent)")
            }
            
            print("✅ Created archive: \(zipURL.lastPathComponent) with \(fileURLs.count) files")
            return true
            
        } catch {
            print("❌ Failed to create archive: \(error)")
            try? FileManager.default.removeItem(at: zipURL)
            return false
        }
    }
    
    // MARK: - File Sharing
    
    /// Prepares a file for sharing via iOS share sheet
    static func prepareFileForSharing(_ fileURL: URL) -> Bool {
        return FileManager.default.fileExists(atPath: fileURL.path)
    }
    
    /// Gets the file size in a human-readable format
    static func getFileSize(url: URL) -> String {
        do {
            let attributes = try FileManager.default.attributesOfItem(atPath: url.path)
            if let fileSize = attributes[.size] as? Int64 {
                return ByteCountFormatter.string(fromByteCount: fileSize, countStyle: .file)
            }
        } catch {
            print("❌ Failed to get file size: \(error)")
        }
        return "Unknown size"
    }
    
    /// Cleans up temporary files older than 24 hours
    static func cleanupTempFiles() {
        let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        
        do {
            let files = try FileManager.default.contentsOfDirectory(at: documentsPath, includingPropertiesForKeys: [.creationDateKey])
            let cutoffDate = Date().addingTimeInterval(-24 * 60 * 60) // 24 hours ago
            
            for fileURL in files {
                if fileURL.lastPathComponent.hasPrefix("temp_") ||
                   fileURL.pathExtension == "zip" ||
                   fileURL.pathExtension == "md" {
                    
                    let attributes = try FileManager.default.attributesOfItem(atPath: fileURL.path)
                    if let creationDate = attributes[.creationDate] as? Date,
                       creationDate < cutoffDate {
                        try FileManager.default.removeItem(at: fileURL)
                        print("🗑️ Cleaned up old file: \(fileURL.lastPathComponent)")
                    }
                }
            }
        } catch {
            print("❌ Failed to cleanup temp files: \(error)")
        }
    }
}