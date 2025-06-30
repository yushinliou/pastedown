import SwiftUI
import Vision
import UniformTypeIdentifiers

// MARK: - Models
struct FrontMatterField: Identifiable, Codable {
    let id = UUID()
    var name: String = ""
    var type: FrontMatterType = .string
    var value: String = ""
}

enum FrontMatterType: String, CaseIterable, Codable {
    case string = "string"
    case number = "number"
    case boolean = "boolean"
    case date = "date"
    case datetime = "datetime"
    case list = "list"
    case tag = "tag"
    case multiline = "multiline"
    case uuid = "uuid"
    case template = "template"
    
    var displayName: String {
        switch self {
        case .string: return "String"
        case .number: return "Number"
        case .boolean: return "Boolean"
        case .date: return "Date"
        case .datetime: return "DateTime"
        case .list: return "List"
        case .tag: return "Tag"
        case .multiline: return "Multiline"
        case .uuid: return "UUID"
        case .template: return "Template"
        }
    }
}

enum ImageHandling: String, CaseIterable, Codable {
    case ignore = "ignore"
    case saveLocal = "saveLocal"
    case saveCustom = "saveCustom"
    
    var displayName: String {
        switch self {
        case .ignore: return "Ignore images"
        case .saveLocal: return "Save to local"
        case .saveCustom: return "Save to custom folder"
        }
    }
}

enum AltTextTemplate: String, CaseIterable, Codable {
    case imageOf = "Image of {objects}"
    case thisShows = "This picture shows {objects}"
    case objects = "{objects}"
    
    var displayName: String {
        return self.rawValue
    }
}

// MARK: - Settings Store
class SettingsStore: ObservableObject {
    @Published var frontMatterFields: [FrontMatterField] = []
    @Published var imageHandling: ImageHandling = .ignore
    @Published var customImageFolder: String = "images"
    @Published var enableAutoAlt: Bool = true
    @Published var altTextTemplate: AltTextTemplate = .imageOf
    @Published var apiKey: String = ""
    @Published var useExternalAPI: Bool = false
    @Published var outputFilenameFormat: String = "note_{date}_{title}.md"
    
    init() {
        loadSettings()
    }
    
    private func loadSettings() {
        if let data = UserDefaults.standard.data(forKey: "frontMatterFields"),
           let fields = try? JSONDecoder().decode([FrontMatterField].self, from: data) {
            frontMatterFields = fields
        }
        
        if let imageHandlingRaw = UserDefaults.standard.string(forKey: "imageHandling"),
           let handling = ImageHandling(rawValue: imageHandlingRaw) {
            imageHandling = handling
        }
        
        customImageFolder = UserDefaults.standard.string(forKey: "customImageFolder") ?? "images"
        enableAutoAlt = UserDefaults.standard.bool(forKey: "enableAutoAlt")
        
        if let templateRaw = UserDefaults.standard.string(forKey: "altTextTemplate"),
           let template = AltTextTemplate(rawValue: templateRaw) {
            altTextTemplate = template
        }
        
        apiKey = UserDefaults.standard.string(forKey: "apiKey") ?? ""
        useExternalAPI = UserDefaults.standard.bool(forKey: "useExternalAPI")
        outputFilenameFormat = UserDefaults.standard.string(forKey: "outputFilenameFormat") ?? "note_{date}_{title}.md"
    }
    
    func saveSettings() {
        if let data = try? JSONEncoder().encode(frontMatterFields) {
            UserDefaults.standard.set(data, forKey: "frontMatterFields")
        }
        
        UserDefaults.standard.set(imageHandling.rawValue, forKey: "imageHandling")
        UserDefaults.standard.set(customImageFolder, forKey: "customImageFolder")
        UserDefaults.standard.set(enableAutoAlt, forKey: "enableAutoAlt")
        UserDefaults.standard.set(altTextTemplate.rawValue, forKey: "altTextTemplate")
        UserDefaults.standard.set(apiKey, forKey: "apiKey")
        UserDefaults.standard.set(useExternalAPI, forKey: "useExternalAPI")
        UserDefaults.standard.set(outputFilenameFormat, forKey: "outputFilenameFormat")
    }
}

// MARK: - Markdown Converter
class MarkdownConverter: ObservableObject {
    private let settings: SettingsStore
    
    init(settings: SettingsStore) {
        self.settings = settings
    }
    
    func convertToMarkdown(from attributedString: NSAttributedString) async -> String {
        var markdown = ""
        
        // Add Front Matter if configured
        if !settings.frontMatterFields.isEmpty {
            markdown += generateFrontMatter()
            markdown += "\n"
        }
        
        // Convert attributed string to markdown
        let range = NSRange(location: 0, length: attributedString.length)
        var currentIndex = 0
        
        attributedString.enumerateAttributes(in: range, options: []) { attributes, range, _ in
            let substring = attributedString.attributedSubstring(from: range).string
            let convertedText = self.convertTextWithAttributes(substring, attributes: attributes)
            markdown += convertedText
            currentIndex = range.location + range.length
        }
        
        return markdown
    }
    
    private func generateFrontMatter() -> String {
        var frontMatter = "---\n"
        
        for field in settings.frontMatterFields {
            let processedValue = processFieldValue(field)
            
            switch field.type {
            case .string, .template:
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
            }
        }
        
        frontMatter += "---"
        return frontMatter
    }
    
    private func processFieldValue(_ field: FrontMatterField) -> String {
        var value = field.value
        
        // Process template variables
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
    
    func generateFilename(title: String = "", clipboardPreview: String = "") -> String {
        var filename = settings.outputFilenameFormat
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        let currentDate = dateFormatter.string(from: Date())
        
        let timeFormatter = DateFormatter()
        timeFormatter.dateFormat = "HH-mm-ss"
        let currentTime = timeFormatter.string(from: Date())
        
        filename = filename.replacingOccurrences(of: "{title}", with: title.isEmpty ? "untitled" : title)
        filename = filename.replacingOccurrences(of: "{date}", with: currentDate)
        filename = filename.replacingOccurrences(of: "{time}", with: currentTime)
        filename = filename.replacingOccurrences(of: "{uuid}", with: UUID().uuidString.prefix(8).lowercased())
        filename = filename.replacingOccurrences(of: "{clipboard_preview}", with: clipboardPreview.prefix(20).description)
        
        // Handle index - for simplicity, using timestamp
        let index = Int(Date().timeIntervalSince1970) % 10000
        filename = filename.replacingOccurrences(of: "{index}", with: String(index))
        
        return filename
    }
}

// MARK: - Image Analyzer
class ImageAnalyzer: ObservableObject {
    private let settings: SettingsStore
    
    init(settings: SettingsStore) {
        self.settings = settings
    }
    
    func generateAltText(for image: UIImage) async -> String {
        guard settings.enableAutoAlt else { return "Image" }
        
        if settings.useExternalAPI && !settings.apiKey.isEmpty {
            // Placeholder for external API call
            return await generateAltTextWithAPI(image)
        } else {
            return await generateAltTextWithVision(image)
        }
    }
    
    private func generateAltTextWithVision(_ image: UIImage) async -> String {
        guard let ciImage = CIImage(image: image) else {
            return "Image"
        }
        
        return await withCheckedContinuation { continuation in
            let request = VNRecognizeTextRequest { request, error in
                if let error = error {
                    print("Vision error: \(error)")
                    continuation.resume(returning: "Image")
                    return
                }
                
                guard let observations = request.results as? [VNRecognizedTextObservation] else {
                    continuation.resume(returning: "Image")
                    return
                }
                
                let recognizedText = observations.compactMap { observation in
                    observation.topCandidates(1).first?.string
                }.joined(separator: " ")
                
                let template = self.settings.altTextTemplate.rawValue
                let result = template.replacingOccurrences(of: "{objects}", with: recognizedText.isEmpty ? "content" : recognizedText)
                continuation.resume(returning: result)
            }
            
            let handler = VNImageRequestHandler(ciImage: ciImage, options: [:])
            try? handler.perform([request])
        }
    }
    
    private func generateAltTextWithAPI(_ image: UIImage) async -> String {
        // Placeholder for external API implementation
        // In a real app, you would implement OpenAI Vision API call here
        return "Image analyzed with external API"
    }
}

// MARK: - Main Views
struct ContentView: View {
    @StateObject private var settings = SettingsStore()
    @StateObject private var converter: MarkdownConverter
    @StateObject private var imageAnalyzer: ImageAnalyzer
    
    @State private var convertedMarkdown: String = ""
    @State private var showingShareSheet = false
    @State private var showingAlert = false
    @State private var alertMessage = ""
    @State private var isConverting = false
    @State private var showingAdvancedSettings = false
    
    init() {
        let settings = SettingsStore()
        _settings = StateObject(wrappedValue: settings)
        _converter = StateObject(wrappedValue: MarkdownConverter(settings: settings))
        _imageAnalyzer = StateObject(wrappedValue: ImageAnalyzer(settings: settings))
    }
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    if convertedMarkdown.isEmpty {
                        initialViewWithSettings
                    } else {
                        resultView
                    }
                }
                .padding()
            }
            .navigationTitle("Paste Down")
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
    
    private var initialViewWithSettings: some View {
        VStack(spacing: 25) {
            // Header section
            VStack(spacing: 30) {
                Image(systemName: "doc.on.clipboard")
                    .font(.system(size: 60))
                    .foregroundColor(.blue)
                
                VStack(spacing: 10) {
                    Text("Paste Down")
                        .font(.title)
                        .fontWeight(.bold)
                    
                    Text("Convert clipboard rich text to Markdown")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
                
                Button(action: pasteFromClipboard) {
                    HStack {
                        Image(systemName: "clipboard")
                        Text("Paste")
                    }
                    .font(.title2)
                    .foregroundColor(.white)
                    .padding(.horizontal, 40)
                    .padding(.vertical, 15)
                    .background(Color.blue)
                    .cornerRadius(10)
                }
                .disabled(isConverting)
                
                if isConverting {
                    ProgressView("Converting...")
                        .padding(.top, 10)
                }
            }
            
            Divider()
            
            // Quick Settings Section
            VStack(alignment: .leading, spacing: 20) {
                HStack {
                    Text("Quick Settings")
                        .font(.headline)
                        .fontWeight(.semibold)
                    
                    Spacer()
                    
                    Button("Advanced") {
                        showingAdvancedSettings = true
                    }
                    .font(.caption)
                    .foregroundColor(.blue)
                }
                
                // Image Handling
                VStack(alignment: .leading, spacing: 8) {
                    Text("Image Handling")
                        .font(.subheadline)
                        .fontWeight(.medium)
                    
                    Picker("Image handling", selection: $settings.imageHandling) {
                        ForEach(ImageHandling.allCases, id: \.self) { handling in
                            Text(handling.displayName).tag(handling)
                        }
                    }
                    .pickerStyle(SegmentedPickerStyle())
                    .onChange(of: settings.imageHandling) { _ in
                        settings.saveSettings()
                    }
                    
                    if settings.imageHandling == .saveCustom {
                        TextField("Custom folder", text: $settings.customImageFolder)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .onChange(of: settings.customImageFolder) { _ in
                                settings.saveSettings()
                            }
                    }
                }
                
                // Alt Text Generation
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text("Alt Text Generation")
                            .font(.subheadline)
                            .fontWeight(.medium)
                        
                        Spacer()
                        
                        Toggle("", isOn: $settings.enableAutoAlt)
                            .onChange(of: settings.enableAutoAlt) { _ in
                                settings.saveSettings()
                            }
                    }
                    
                    if settings.enableAutoAlt {
                        Picker("Template", selection: $settings.altTextTemplate) {
                            ForEach(AltTextTemplate.allCases, id: \.self) { template in
                                Text(template.displayName).tag(template)
                            }
                        }
                        .pickerStyle(MenuPickerStyle())
                        .onChange(of: settings.altTextTemplate) { _ in
                            settings.saveSettings()
                        }
                    }
                }
                
                // Output Filename
                VStack(alignment: .leading, spacing: 8) {
                    Text("Output Filename")
                        .font(.subheadline)
                        .fontWeight(.medium)
                    
                    TextField("Filename format", text: $settings.outputFilenameFormat)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .onChange(of: settings.outputFilenameFormat) { _ in
                            settings.saveSettings()
                        }
                    
                    Text("Variables: {title}, {date}, {time}, {uuid}, {index}, {clipboard_preview}")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
                
                // Front Matter Preview
                if !settings.frontMatterFields.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text("Front Matter Fields")
                                .font(.subheadline)
                                .fontWeight(.medium)
                            
                            Spacer()
                            
                            Text("\(settings.frontMatterFields.count) fields")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 8) {
                                ForEach(settings.frontMatterFields.prefix(3)) { field in
                                    Text(field.name.isEmpty ? "unnamed" : field.name)
                                        .font(.caption)
                                        .padding(.horizontal, 8)
                                        .padding(.vertical, 4)
                                        .background(Color.blue.opacity(0.1))
                                        .foregroundColor(.blue)
                                        .cornerRadius(4)
                                }
                                
                                if settings.frontMatterFields.count > 3 {
                                    Text("+\(settings.frontMatterFields.count - 3) more")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                            }
                            .padding(.horizontal, 2)
                        }
                    }
                }
            }
            .padding()
            .background(Color.gray.opacity(0.05))
            .cornerRadius(12)
        }
    }
    
    private var resultView: some View {
        VStack(spacing: 20) {
            // Quick settings in result view
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Text("Settings")
                        .font(.headline)
                        .fontWeight(.semibold)
                    
                    Spacer()
                    
                    Button("Advanced") {
                        showingAdvancedSettings = true
                    }
                    .font(.caption)
                    .foregroundColor(.blue)
                }
                
                HStack(spacing: 15) {
                    // Image handling quick toggle
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Images")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        Picker("", selection: $settings.imageHandling) {
                            Text("Ignore").tag(ImageHandling.ignore)
                            Text("Local").tag(ImageHandling.saveLocal)
                            Text("Custom").tag(ImageHandling.saveCustom)
                        }
                        .pickerStyle(MenuPickerStyle())
                        .onChange(of: settings.imageHandling) { _ in
                            settings.saveSettings()
                        }
                    }
                    
                    // Alt text toggle
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Alt Text")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        Toggle("", isOn: $settings.enableAutoAlt)
                            .onChange(of: settings.enableAutoAlt) { _ in
                                settings.saveSettings()
                            }
                    }
                    
                    Spacer()
                }
            }
            .padding()
            .background(Color.gray.opacity(0.05))
            .cornerRadius(12)
            
            // Editor
            VStack(alignment: .leading, spacing: 8) {
                Text("Markdown Output")
                    .font(.headline)
                    .fontWeight(.semibold)
                
                TextEditor(text: $convertedMarkdown)
                    .font(.system(.body, design: .monospaced))
                    .padding()
                    .background(Color.gray.opacity(0.05))
                    .cornerRadius(8)
                    .frame(minHeight: 300)
            }
            
            // Bottom buttons
            HStack {
                Button("New") {
                    convertedMarkdown = ""
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 10)
                .background(Color.gray.opacity(0.2))
                .cornerRadius(8)
                
                Spacer()
                
                Button("Copy Markdown") {
                    UIPasteboard.general.string = convertedMarkdown
                    alertMessage = "Markdown copied to clipboard!"
                    showingAlert = true
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 10)
                .background(Color.blue)
                .foregroundColor(.white)
                .cornerRadius(8)
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
            case .string, .template:
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

// MARK: - Advanced Settings View
struct AdvancedSettingsView: View {
    @ObservedObject var settings: SettingsStore
    @Environment(\.presentationMode) var presentationMode
    @State private var newFieldName = ""
    @State private var newFieldType = FrontMatterType.string
    @State private var newFieldValue = ""
    
    var body: some View {
        NavigationView {
            Form {
                Section("Front Matter Template") {
                    ForEach(settings.frontMatterFields) { field in
                        FrontMatterFieldRow(field: field, settings: settings)
                    }
                    .onDelete(perform: deleteFrontMatterField)
                    
                    // Add new field
                    VStack(alignment: .leading) {
                        HStack {
                            TextField("Field name", text: $newFieldName)
                            Picker("Type", selection: $newFieldType) {
                                ForEach(FrontMatterType.allCases, id: \.self) { type in
                                    Text(type.displayName).tag(type)
                                }
                            }
                            .pickerStyle(MenuPickerStyle())
                        }
                        
                        TextField("Value", text: $newFieldValue)
                        
                        Button("Add Field") {
                            let newField = FrontMatterField(name: newFieldName, type: newFieldType, value: newFieldValue)
                            settings.frontMatterFields.append(newField)
                            newFieldName = ""
                            newFieldValue = ""
                            settings.saveSettings()
                        }
                        .disabled(newFieldName.isEmpty)
                    }
                }
                
                Section("External API Settings") {
                    Toggle("Use external API", isOn: $settings.useExternalAPI)
                        .onChange(of: settings.useExternalAPI) { _ in
                            settings.saveSettings()
                        }
                    
                    if settings.useExternalAPI {
                        SecureField("API Key", text: $settings.apiKey)
                            .onChange(of: settings.apiKey) { _ in
                                settings.saveSettings()
                            }
                    }
                }
                
                Section("Template Variables Help") {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Available variables for Front Matter and filenames:")
                            .font(.subheadline)
                            .fontWeight(.medium)
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text("• {title} - Front Matter title field")
                            Text("• {date} - Current date (YYYY-MM-DD)")
                            Text("• {time} - Current time (HH:MM:SS)")
                            Text("• {uuid} - Generated UUID")
                            Text("• {index} - Auto-increment number")
                            Text("• {clipboard_preview} - First 20 chars of clipboard")
                            Text("• {current_date} - For Front Matter templates")
                            Text("• {current_time} - For Front Matter templates")
                        }
                        .font(.caption)
                        .foregroundColor(.secondary)
                    }
                }
            }
            .navigationTitle("Advanced Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        settings.saveSettings()
                        presentationMode.wrappedValue.dismiss()
                    }
                }
            }
        }
    }
    
    private func deleteFrontMatterField(offsets: IndexSet) {
        settings.frontMatterFields.remove(atOffsets: offsets)
        settings.saveSettings()
    }
}

struct FrontMatterFieldRow: View {
    @State var field: FrontMatterField
    @ObservedObject var settings: SettingsStore
    
    var body: some View {
        VStack(alignment: .leading) {
            HStack {
                TextField("Name", text: $field.name)
                    .onChange(of: field.name) { _ in updateField() }
                
                Picker("Type", selection: $field.type) {
                    ForEach(FrontMatterType.allCases, id: \.self) { type in
                        Text(type.displayName).tag(type)
                    }
                }
                .pickerStyle(MenuPickerStyle())
                .onChange(of: field.type) { _ in updateField() }
            }
            
            TextField("Value", text: $field.value)
                .onChange(of: field.value) { _ in updateField() }
        }
    }
    
    private func updateField() {
        if let index = settings.frontMatterFields.firstIndex(where: { $0.id == field.id }) {
            settings.frontMatterFields[index] = field
        }
    }
}

// MARK: - Share Sheet
struct ShareSheet: UIViewControllerRepresentable {
    let items: [Any]
    
    func makeUIViewController(context: Context) -> UIActivityViewController {
        let controller = UIActivityViewController(activityItems: items, applicationActivities: nil)
        return controller
    }
    
    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}

// MARK: - App
@main
struct pastedown_v1App: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
