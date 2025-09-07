//
//  ShareViewController.swift
//  pastedownShareExtension
//
//  Created by liuyuxin on 2025/9/7.

import UIKit
import Social
import MobileCoreServices
import UniformTypeIdentifiers

class ShareViewController: SLComposeServiceViewController {
    
    private var sharedContent: NSAttributedString?
    private var sharedImages: [UIImage] = []
    
    override func viewDidLoad() {
        super.viewDidLoad()
        NSLog("🔥 PASTEDOWN: ShareViewController viewDidLoad() called")
        
        // Customize the appearance
        title = "Convert to Markdown"
        placeholder = "Converting your content to Markdown..."
        
        // Make text view non-editable and hide it initially
        textView.isEditable = false
        textView.text = "Processing content..."
        
        NSLog("🔥 PASTEDOWN: About to extract shared content")
        // Extract and immediately process shared content
        extractSharedContent()
    }

    override func isContentValid() -> Bool {
        // Content is valid if we have either text content or images
        return sharedContent != nil || !sharedImages.isEmpty
    }

    override func didSelectPost() {
        // Show loading state
        self.textView.isEditable = false
        
        // Process the shared content
        processSharedContent()
    }

    override func configurationItems() -> [Any]! {
        // No additional configuration items needed for now
        return []
    }
    
    private func extractSharedContent() {
        NSLog("🔥 PASTEDOWN: extractSharedContent() called")
        guard let extensionContext = extensionContext else { 
            NSLog("🔥 PASTEDOWN: No extensionContext!")
            return 
        }
        
        NSLog("🔥 PASTEDOWN: Found \(extensionContext.inputItems.count) input items")
        
        for (itemIndex, item) in extensionContext.inputItems.enumerated() {
            guard let inputItem = item as? NSExtensionItem else { 
                NSLog("🔥 PASTEDOWN: Item \(itemIndex) is not NSExtensionItem")
                continue 
            }
            
            NSLog("🔥 PASTEDOWN: Item \(itemIndex) has \(inputItem.attachments?.count ?? 0) attachments")
            
            for (attachmentIndex, provider) in (inputItem.attachments ?? []).enumerated() {
                NSLog("🔥 PASTEDOWN: Processing attachment \(attachmentIndex)")
                NSLog("🔥 PASTEDOWN: Registered type identifiers: \(provider.registeredTypeIdentifiers)")
                
                // Handle different content types
                if provider.hasItemConformingToTypeIdentifier(UTType.rtfd.identifier) {
                    NSLog("🔥 PASTEDOWN: Found RTFD content")
                    extractRTFDContent(from: provider)
                } else if provider.hasItemConformingToTypeIdentifier(UTType.rtf.identifier) {
                    NSLog("🔥 PASTEDOWN: Found RTF content")
                    extractRTFContent(from: provider)
                } else if provider.hasItemConformingToTypeIdentifier(UTType.html.identifier) {
                    NSLog("🔥 PASTEDOWN: Found HTML content")
                    extractHTMLContent(from: provider)
                } else if provider.hasItemConformingToTypeIdentifier(UTType.plainText.identifier) {
                    NSLog("🔥 PASTEDOWN: Found plain text content")
                    extractPlainTextContent(from: provider)
                }
                
                // Handle images
                if provider.hasItemConformingToTypeIdentifier(UTType.image.identifier) {
                    NSLog("🔥 PASTEDOWN: Found image content")
                    extractImageContent(from: provider)
                }
            }
        }
        
        NSLog("🔥 PASTEDOWN: Finished processing all attachments")
        
        // If we haven't found any content yet, try a more generic approach
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            if self.sharedContent == nil {
                NSLog("🔥 PASTEDOWN: No content found, trying fallback extraction")
                self.extractContentFallback()
            }
        }
    }
    
    private func extractRTFDContent(from provider: NSItemProvider) {
        provider.loadItem(forTypeIdentifier: UTType.rtfd.identifier, options: nil) { [weak self] (item, error) in
            if let error = error {
                print("[PASTEDOWN]Error loading RTFD: \(error)")
                return
            }
            
            if let url = item as? URL {
                self?.processRTFDFile(at: url)
            } else if let data = item as? Data {
                self?.processRTFDData(data)
            }
        }
    }
    
    private func extractRTFContent(from provider: NSItemProvider) {
        provider.loadItem(forTypeIdentifier: UTType.rtf.identifier, options: nil) { [weak self] (item, error) in
            if let error = error {
                print("[PASTEDOWN]Error loading RTF: \(error)")
                return
            }
            
            if let data = item as? Data {
                self?.processRTFData(data)
            }
        }
    }
    
    private func extractHTMLContent(from provider: NSItemProvider) {
        provider.loadItem(forTypeIdentifier: UTType.html.identifier, options: nil) { [weak self] (item, error) in
            if let error = error {
                print("[PASTEDOWN] Error loading HTML: \(error)")
                return
            }
            
            if let data = item as? Data {
                self?.processHTMLData(data)
            }
        }
    }
    
    private func extractPlainTextContent(from provider: NSItemProvider) {
        provider.loadItem(forTypeIdentifier: UTType.plainText.identifier, options: nil) { [weak self] (item, error) in
            if let error = error {
                print("[PASTEDOWN] Error loading plain text: \(error)")
                return
            }
            
            if let text = item as? String {
                DispatchQueue.main.async {
                    self?.sharedContent = NSAttributedString(string: text)
                    self?.updatePreview()
                }
            }
        }
    }
    
    private func extractImageContent(from provider: NSItemProvider) {
        provider.loadItem(forTypeIdentifier: UTType.image.identifier, options: nil) { [weak self] (item, error) in
            if let error = error {
                print("[PASTEDOWN] Error loading image: \(error)")
                return
            }
            
            if let image = item as? UIImage {
                DispatchQueue.main.async {
                    self?.sharedImages.append(image)
                    self?.updatePreview()
                }
            } else if let url = item as? URL,
                      let image = UIImage(contentsOfFile: url.path) {
                DispatchQueue.main.async {
                    self?.sharedImages.append(image)
                    self?.updatePreview()
                }
            }
        }
    }
    
    private func processRTFDFile(at url: URL) {
        do {
            let rtfdData = try Data(contentsOf: url)
            processRTFDData(rtfdData)
        } catch {
            print("[PASTEDOWN] Error reading RTFD file: \(error)")
        }
    }
    
    private func processRTFDData(_ data: Data) {
        NSLog("🔥 PASTEDOWN: Processing RTFD data of size: \(data.count)")
        DispatchQueue.main.async { [weak self] in
            do {
                let attributedString = try NSAttributedString(
                    data: data,
                    options: [.documentType: NSAttributedString.DocumentType.rtfd],
                    documentAttributes: nil
                )
                NSLog("🔥 PASTEDOWN: RTFD converted to NSAttributedString with length: \(attributedString.length)")
                NSLog("🔥 PASTEDOWN: RTFD string preview: \(attributedString.string.prefix(200))")
                self?.sharedContent = attributedString
                self?.updatePreview()
            } catch {
                print("[PASTEDOWN] Error processing RTFD data: \(error)")
            }
        }
    }
    
    private func processRTFData(_ data: Data) {
        NSLog("🔥 PASTEDOWN: Processing RTF data of size: \(data.count)")
        if let rtfString = String(data: data, encoding: .utf8) {
            NSLog("🔥 PASTEDOWN: RTF raw content: \(rtfString.prefix(500))")
        }
        DispatchQueue.main.async { [weak self] in
            do {
                let attributedString = try NSAttributedString(
                    data: data,
                    options: [.documentType: NSAttributedString.DocumentType.rtf],
                    documentAttributes: nil
                )
                NSLog("🔥 PASTEDOWN: RTF converted to NSAttributedString with length: \(attributedString.length)")
                NSLog("🔥 PASTEDOWN: RTF string preview: \(attributedString.string.prefix(200))")
                self?.sharedContent = attributedString
                self?.updatePreview()
            } catch {
                print("[PASTEDOWN] Error processing RTF data: \(error)")
            }
        }
    }
    
    private func processHTMLData(_ data: Data) {
        NSLog("🔥 PASTEDOWN: Processing HTML data of size: \(data.count)")
        if let htmlString = String(data: data, encoding: .utf8) {
            NSLog("🔥 PASTEDOWN: HTML raw content: \(htmlString.prefix(500))")
        }
        DispatchQueue.main.async { [weak self] in
            do {
                let attributedString = try NSAttributedString(
                    data: data,
                    options: [.documentType: NSAttributedString.DocumentType.html],
                    documentAttributes: nil
                )
                NSLog("🔥 PASTEDOWN: HTML converted to NSAttributedString with length: \(attributedString.length)")
                NSLog("🔥 PASTEDOWN: HTML string preview: \(attributedString.string.prefix(200))")
                self?.sharedContent = attributedString
                self?.updatePreview()
            } catch {
                print("[PASTEDOWN] Error processing HTML data: \(error)")
            }
        }
    }
    
    private func updatePreview() {
        NSLog("🔥 PASTEDOWN: updatePreview() called")
        guard let content = sharedContent else { 
            NSLog("🔥 PASTEDOWN: No shared content in updatePreview")
            return 
        }
        
        // Debug: Log content details
        NSLog("🔥 PASTEDOWN: Content length: \(content.length)")
        NSLog("🔥 PASTEDOWN: Content string: \(content.string.prefix(500))")
        
        // Debug: Log RTF representation if available
        if let rtfData = try? content.data(from: NSRange(location: 0, length: content.length), documentAttributes: [.documentType: NSAttributedString.DocumentType.rtf]) {
            if let rtfString = String(data: rtfData, encoding: .utf8) {
                NSLog("🔥 PASTEDOWN: RTF data: \(rtfString.prefix(1000))")
            }
        }
        
        // Debug: Log attributes at different ranges
        content.enumerateAttributes(in: NSRange(location: 0, length: content.length), options: []) { attributes, range, _ in
            let substring = content.attributedSubstring(from: range)
            NSLog("🔥 PASTEDOWN: Range \(range): '\(substring.string)' - Attributes: \(attributes)")
        }
        
        let previewText = content.string
        let maxPreviewLength = 200
        
        var displayText = ""
        if previewText.count > maxPreviewLength {
            displayText = String(previewText.prefix(maxPreviewLength)) + "..."
        } else {
            displayText = previewText
        }
        
        if !sharedImages.isEmpty {
            displayText += "\n\n[\(sharedImages.count) image(s) detected]"
        }
        
        // Update the text view with preview
        textView.text = displayText
        textView.isEditable = false
        
        // Validate content and auto-process
        validateContent()
        
        // Automatically start conversion after a short delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            self.processSharedContentAutomatically()
        }
    }
    
    private func processSharedContent() {
        guard let content = sharedContent else {
            showErrorAndClose("No content to convert")
            return
        }
        
        // Load settings from shared container or use defaults
        let settings = loadSharedSettings()
        
        Task {
            // Create processor and convert content
            let imageAnalyzer = ImageAnalyzer(settings: settings)
            let processor = RichTextProcessor(imageAnalyzer: imageAnalyzer, settings: settings)
            let markdown = await processor.processAttributedStringWithImages(content)
            
            // Save to shared container
            let success = self.saveMarkdownToSharedContainer(markdown, settings: settings)
            
            await MainActor.run {
                if success {
                    let contentPreview = content.string
                    let filename = settings.generateFinalOutputFilename(contentPreview: contentPreview)
                    self.showSaveSuccessAndClose(filename: filename)
                } else {
                    self.showErrorAndClose("Failed to save converted content")
                }
            }
        }
    }
    
    private func loadSharedSettings() -> SettingsStore {
        let settings = SettingsStore()
        
        // Try to load settings from shared container
        if let sharedContainer = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: "group.Yu-shin.pastedown") {
            let settingsURL = sharedContainer.appendingPathComponent("SharedSettings.plist")
            
            if let data = try? Data(contentsOf: settingsURL),
               let plist = try? PropertyListSerialization.propertyList(from: data, format: nil) as? [String: Any] {
                
                // Load settings from shared plist
                if let frontMatterData = plist["frontMatterFields"] as? Data,
                   let fields = try? JSONDecoder().decode([FrontMatterField].self, from: frontMatterData) {
                    settings.frontMatterFields = fields
                }
                
                if let imageHandlingRaw = plist["imageHandling"] as? String,
                   let handling = ImageHandling(rawValue: imageHandlingRaw) {
                    settings.imageHandling = handling
                }
                
                settings.imageFolderPath = plist["imageFolderPath"] as? String ?? "./images"
                settings.enableAutoAlt = plist["enableAutoAlt"] as? Bool ?? true
                
                if let templateRaw = plist["altTextTemplate"] as? String,
                   let template = AltTextTemplate(rawValue: templateRaw) {
                    settings.altTextTemplate = template
                }
                
                settings.apiKey = plist["apiKey"] as? String ?? ""
                settings.useExternalAPI = plist["useExternalAPI"] as? Bool ?? false
                
                if let providerRaw = plist["llmProvider"] as? String,
                   let provider = LLMProvider(rawValue: providerRaw) {
                    settings.llmProvider = provider
                }
                
                settings.customPrompt = plist["customPrompt"] as? String ?? ""
                settings.outputFilenameFormat = plist["outputFilenameFormat"] as? String ?? "note_{date}_{clipboard_preview}"
            }
        }
        
        return settings
    }
    
    private func saveMarkdownToSharedContainer(_ markdown: String, settings: SettingsStore) -> Bool {
        guard let sharedContainer = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: "group.Yu-shin.pastedown") else {
            print("[PASTEDOWN] Could not access shared container")
            return false
        }
        
        // Create converted files directory if it doesn't exist
        let convertedDir = sharedContainer.appendingPathComponent("ConvertedFiles")
        do {
            try FileManager.default.createDirectory(at: convertedDir, withIntermediateDirectories: true, attributes: nil)
        } catch {
            print("[PASTEDOWN] Error creating directory: \(error)")
        }
        
        let contentPreview = sharedContent?.string ?? ""
        let filename = settings.generateFinalOutputFilename(contentPreview: contentPreview)
        let fileURL = convertedDir.appendingPathComponent(filename)
        
        do {
            try markdown.write(to: fileURL, atomically: true, encoding: .utf8)
            print("[PASTEDOWN] Markdown saved to shared container: \(filename)")
            return true
        } catch {
            print("[PASTEDOWN] Error saving markdown: \(error)")
            return false
        }
    }
    
    private func processSharedContentAutomatically() {
        guard let content = sharedContent else {
            showErrorAndClose("No content to convert")
            return
        }
        
        // Update UI to show processing
        textView.text = "Converting to Markdown..."
        
        // Load settings from shared container or use defaults
        let settings = loadSharedSettings()
        
        Task {
            NSLog("🔥 PASTEDOWN: Starting conversion process")
            NSLog("🔥 PASTEDOWN: Content to convert: '\(content.string.prefix(300))'")
            
            // Create processor and convert content
            let imageAnalyzer = ImageAnalyzer(settings: settings)
            let processor = RichTextProcessor(imageAnalyzer: imageAnalyzer, settings: settings)
            let markdown = await processor.processAttributedStringWithImages(content)
            
            NSLog("🔥 PASTEDOWN: Conversion complete")
            NSLog("🔥 PASTEDOWN: Generated markdown: '\(markdown.prefix(500))'")
            
            await MainActor.run {
                self.showConversionResult(markdown: markdown, settings: settings)
            }
        }
    }
    
    private func showConversionResult(markdown: String, settings: SettingsStore) {
        let contentPreview = sharedContent?.string ?? ""
        let filename = settings.generateFinalOutputFilename(contentPreview: contentPreview)
        
        // Create alert with options
        let alert = UIAlertController(
            title: "Conversion Complete!",
            message: "Your content has been converted to Markdown. What would you like to do?",
            preferredStyle: .alert
        )
        
        // Copy to clipboard option
        alert.addAction(UIAlertAction(title: "Copy Markdown", style: .default) { [weak self] _ in
            UIPasteboard.general.string = markdown
            self?.showCopySuccessAndClose()
        })
        
        // Save to shared container option
        alert.addAction(UIAlertAction(title: "Save File", style: .default) { [weak self] _ in
            let success = self?.saveMarkdownToSharedContainer(markdown, settings: settings) ?? false
            if success {
                self?.showSaveSuccessAndClose(filename: filename)
            } else {
                self?.showErrorAndClose("Failed to save file")
            }
        })
        
        // Cancel option
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel) { [weak self] _ in
            self?.extensionContext?.completeRequest(returningItems: nil, completionHandler: nil)
        })
        
        present(alert, animated: true)
    }
    
    private func showCopySuccessAndClose() {
        let alert = UIAlertController(
            title: "Copied!",
            message: "Markdown has been copied to clipboard.",
            preferredStyle: .alert
        )
        
        alert.addAction(UIAlertAction(title: "OK", style: .default) { [weak self] _ in
            self?.extensionContext?.completeRequest(returningItems: nil, completionHandler: nil)
        })
        
        present(alert, animated: true)
    }
    
    private func showSaveSuccessAndClose(filename: String) {
        let alert = UIAlertController(
            title: "Saved!",
            message: "Markdown saved as: \(filename)",
            preferredStyle: .alert
        )
        
        alert.addAction(UIAlertAction(title: "OK", style: .default) { [weak self] _ in
            self?.extensionContext?.completeRequest(returningItems: nil, completionHandler: nil)
        })
        
        present(alert, animated: true)
    }
    
    private func showErrorAndClose(_ message: String) {
        // Create alert
        let alert = UIAlertController(
            title: "Error",
            message: message,
            preferredStyle: .alert
        )
        
        alert.addAction(UIAlertAction(title: "OK", style: .default) { [weak self] _ in
            self?.extensionContext?.completeRequest(returningItems: nil, completionHandler: nil)
        })
        
        present(alert, animated: true)
    }
    
    // MARK: - Fallback Content Extraction
    private func extractContentFallback() {
        NSLog("🔥 PASTEDOWN: Starting fallback content extraction")
        guard let extensionContext = extensionContext else { return }
        
        for item in extensionContext.inputItems {
            guard let inputItem = item as? NSExtensionItem else { continue }
            
            for provider in inputItem.attachments ?? [] {
                NSLog("🔥 PASTEDOWN: Fallback - trying all available type identifiers")
                
                // Try each registered type identifier
                for typeIdentifier in provider.registeredTypeIdentifiers {
                    NSLog("🔥 PASTEDOWN: Fallback - trying type: \(typeIdentifier)")
                    
                    provider.loadItem(forTypeIdentifier: typeIdentifier, options: nil) { [weak self] (item, error) in
                        if let error = error {
                            NSLog("🔥 PASTEDOWN: Fallback error for \(typeIdentifier): \(error)")
                            return
                        }
                        
                        NSLog("🔥 PASTEDOWN: Fallback - successfully loaded \(typeIdentifier)")
                        NSLog("🔥 PASTEDOWN: Item type: \(type(of: item))")
                        
                        DispatchQueue.main.async {
                            if let string = item as? String {
                                NSLog("🔥 PASTEDOWN: Fallback found string: \(String(string.prefix(100)))")
                                self?.sharedContent = NSAttributedString(string: string)
                                self?.updatePreview()
                            } else if let data = item as? Data {
                                NSLog("🔥 PASTEDOWN: Fallback found data of size: \(data.count)")
                                // Try to convert data to attributed string
                                if let attrString = try? NSAttributedString(data: data, options: [.documentType: NSAttributedString.DocumentType.rtf], documentAttributes: nil) {
                                    self?.sharedContent = attrString
                                    self?.updatePreview()
                                } else if let htmlString = try? NSAttributedString(data: data, options: [.documentType: NSAttributedString.DocumentType.html], documentAttributes: nil) {
                                    self?.sharedContent = htmlString
                                    self?.updatePreview()
                                } else if let plainString = String(data: data, encoding: .utf8) {
                                    self?.sharedContent = NSAttributedString(string: plainString)
                                    self?.updatePreview()
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}
