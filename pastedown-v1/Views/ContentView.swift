//
//  ContentView.swift
//  pastedown-v1
//
//  Created by 劉羽芯 on 2025/6/30.
//

import SwiftUI

// MARK: - Main Views
struct ContentView: View {
    @StateObject private var settings = SettingsStore()
    @StateObject private var converter: MarkdownConverter // ?
    @StateObject private var imageAnalyzer: ImageAnalyzer // ViewModels

    @State private var convertedMarkdown: String = ""
    @State private var showingShareSheet = false
    @State private var showingAlert = false
    @State private var alertMessage = ""
    @State private var isConverting = false
    @State private var showingAdvancedSettings = false
    
    init() {
        let settings = SettingsStore()
        
        _settings = StateObject(wrappedValue: settings)
        _converter = StateObject(wrappedValue: MarkdownConverter(settings: settings)) // // ?
        _imageAnalyzer = StateObject(wrappedValue: ImageAnalyzer(settings: settings))
    }
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    if convertedMarkdown.isEmpty {
                        InitialViewWithSettings(
                            isConverting: $isConverting,
                            showingAdvancedSettings: $showingAdvancedSettings,
                            settings: settings,
                            pasteFromClipboard: pasteFromClipboard
                        )
                    } else {
                        ResultView(
                             convertedMarkdown: $convertedMarkdown,
                            showingAlert: $showingAlert,
                            alertMessage: $alertMessage,
                            showingAdvancedSettings: $showingAdvancedSettings,
                            settings: settings
                        )
                    }
                }
                .padding()
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                if !convertedMarkdown.isEmpty {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button("Save") {
                            showingShareSheet = true
                        }
                    }
                }
            }
            .sheet(isPresented: $showingAdvancedSettings) {
                AdvancedSettingsView(settings: settings)
            }
            .sheet(isPresented: $showingShareSheet) {
                ShareSheet(items: [convertedMarkdown])
            }
            .alert("Alert", isPresented: $showingAlert) {
                Button("OK") { }
            } message: {
                Text(alertMessage)
            }
        }
    }
    
    private func pasteFromClipboard() {
        let pasteboard = UIPasteboard.general
        
        guard pasteboard.hasStrings || pasteboard.hasImages else {
            alertMessage = "Clipboard is empty"
            showingAlert = true
            return
        }
        
        isConverting = true
        
        Task {
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
                    let frontMatter = generateFrontMatter()
                    markdown = frontMatter + "\n"
                }
                
                // Process attributed string with inline images
                markdown += await processAttributedStringWithImages(attributedString)
            } else if let plainText = pasteboard.string {
                // Add front matter if configured
                if !settings.frontMatterFields.isEmpty {
                    let frontMatter = generateFrontMatter()
                    markdown = frontMatter + "\n" + plainText
                } else {
                    markdown = plainText
                }
                
                // Handle standalone images if any
                if let image = pasteboard.image {
                    let altText = await imageAnalyzer.generateAltText(for: image)
                    let imageMarkdown = generateImageMarkdown(altText: altText)
                    markdown += "\n\n" + imageMarkdown
                }
            }
            
            await MainActor.run {
                self.convertedMarkdown = markdown
                self.isConverting = false
            }
        }
    }
    
    private func processAttributedStringWithImages(_ attributedString: NSAttributedString) async -> String {
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
                    let imageMarkdown = generateImageMarkdownWithBase64(image: image, altText: altText)
                    markdown += imageMarkdown
                    imageIndex += 1
                } else {
                    // Fallback for attachments without images
                    markdown += "![attachment]"
                }
            } else {
                // Handle regular text with formatting
                let substring = attributedString.attributedSubstring(from: range).string
                let formattedText = convertTextWithAttributes(substring, attributes: attrs)
                markdown += formattedText
            }
        }
        
        return markdown
    }
    
     private func convertTextWithAttributes(_ text: String, attributes: [NSAttributedString.Key: Any]) -> String {
         var result = text
        
         // Handle font styles
         if let font = attributes[.font] as? UIFont {
             if font.fontDescriptor.symbolicTraits.contains(.traitBold) {
                 result = "**\(result)**"
             }
             if font.fontDescriptor.symbolicTraits.contains(.traitItalic) {
                 result = "*\(result)*"
             }
         }
        
         // Handle strikethrough
         if attributes[.strikethroughStyle] != nil {
             result = "~~\(result)~~"
         }
        
         // Handle links
         if let url = attributes[.link] as? URL {
             result = "[\(text)](\(url.absoluteString))"
         }
        
         return result
     }
    
    private func generateImageMarkdownWithBase64(image: UIImage, altText: String) -> String {
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
    
    private func generateFrontMatter() -> String {
        guard !settings.frontMatterFields.isEmpty else { return "" }
        
        var frontMatter = "---\n"
        
        for field in settings.frontMatterFields {
            let processedValue = processFieldValue(field)
            
            switch field.type {
            case .string:
                frontMatter += "\(field.name): \"\(processedValue)\"\n"
            case .number:
                frontMatter += "\(field.name): \(processedValue)\n"
            case .boolean:
                frontMatter += "\(field.name): \(processedValue.lowercased() == "true" ? "true" : "false")\n"
            case .date, .datetime:
                frontMatter += "\(field.name): \"\(processedValue)\"\n"
            case .list:
                let items = processedValue.components(separatedBy: ",").map { $0.trimmingCharacters(in: .whitespaces) }
                frontMatter += "\(field.name): [\(items.map { "\"\($0)\"" }.joined(separator: ", "))]\n"
            case .tag:
                let items = processedValue.components(separatedBy: ",").map { $0.trimmingCharacters(in: .whitespaces) }
                frontMatter += "\(field.name):\n"
                for item in items {
                    frontMatter += "  - \"\(item)\"\n"
                }
            case .multiline:
                frontMatter += "\(field.name): >-\n"
                let lines = processedValue.components(separatedBy: .newlines)
                for line in lines {
                    frontMatter += "  \(line)\n"
                }
            case .uuid:
                frontMatter += "\(field.name): \"\(UUID().uuidString)\"\n"
            case .current_date:
                frontMatter += "\(field.name): \"\(processFieldValue(field))\"\n"
            case .current_datetime:
                frontMatter += "\(field.name): \"\(processFieldValue(field))\"\n"
            }
        }
        
        frontMatter += "---"
        return frontMatter
    }
    
    private func processFieldValue(_ field: FrontMatterField) -> String {
        var value = field.value
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        let currentDate = dateFormatter.string(from: Date())
        
        let timeFormatter = DateFormatter()
        timeFormatter.dateFormat = "HH:mm:ss"
        let currentTime = timeFormatter.string(from: Date())
        
        value = value.replacingOccurrences(of: "{current_date}", with: currentDate)
        value = value.replacingOccurrences(of: "{current_time}", with: currentTime)
        
        return value
    }
    
    private func generateImageMarkdown(altText: String) -> String {
        switch settings.imageHandling {
        case .ignore:
            return "<!-- Image ignored -->"
        case .saveLocal:
            return "![\(altText)](./images/image.png)"
        case .saveCustom:
            return "![\(altText)](.//\(settings.customImageFolder)/image.png)"
        }
    }
}

#Preview {
    ContentView()
}
