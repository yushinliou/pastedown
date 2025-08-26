//
//  ContentView.swift
//  pastedown-v1
//
//  Created by 劉羽芯 on 2025/6/30.
//

import SwiftUI

// MARK: - Main Views
struct ContentView: View {
    // ViewModels
    @StateObject private var settings = SettingsStore()
    @StateObject private var imageAnalyzer: ImageAnalyzer 
    @StateObject private var richTextProcessor: RichTextProcessor
    @StateObject private var clipboardService: ClipboardService

    // States
    @State private var convertedMarkdown: String = ""
    @State private var processingResult: ImageUtilities.ProcessingResult?
    @State private var showingShareSheet = false
    @State private var showingAlert = false
    @State private var alertMessage = ""
    @State private var isConverting = false
    @State private var showingAdvancedSettings = false
    @State private var currentContentPreview: String = ""
    
    init() {
        let settings = SettingsStore()
        let imageAnalyzer = ImageAnalyzer(settings: settings)
        let richTextProcessor = RichTextProcessor(imageAnalyzer: imageAnalyzer, settings: settings)
        
        _settings = StateObject(wrappedValue: settings)
        _imageAnalyzer = StateObject(wrappedValue: imageAnalyzer)
        _richTextProcessor = StateObject(wrappedValue: richTextProcessor)
        _clipboardService = StateObject(wrappedValue: ClipboardService(imageAnalyzer: imageAnalyzer, settings: settings, richTextProcessor: richTextProcessor))
    }
    
    var body: some View {
        NavigationView {
            Group {
                VStack(spacing: 20) {
                    if convertedMarkdown.isEmpty {
                        ScrollView {
                            InitialViewWithSettings(
                                isConverting: $isConverting,
                                showingAdvancedSettings: $showingAdvancedSettings,
                                settings: settings,
                                pasteFromClipboard: pasteFromClipboard
                            )
                        }
                    } else {
                        ResultView(
                             convertedMarkdown: $convertedMarkdown,
                            showingAlert: $showingAlert,
                            alertMessage: $alertMessage,
                            showingAdvancedSettings: $showingAdvancedSettings,
                            settings: settings,
                            processingResult: processingResult
                        )
                    }
                }
                .padding()
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                if !convertedMarkdown.isEmpty {
                    ToolbarItem(placement: .navigationBarLeading) {
                        Button {
                            convertedMarkdown = ""   // clean content and back to InitialView
                        } label: {
                            Image(systemName: "xmark")
                        }
                    }
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
                if let result = processingResult,
                   let fileURL = result.fileURL,
                   FileManagerUtilities.prepareFileForSharing(fileURL) {
                    // Share the actual file (MD or ZIP)
                    ShareSheet(items: [fileURL], suggestedFilename: fileURL.lastPathComponent)
                } else {
                    // Fallback to sharing markdown text
                    let filename = settings.generateFinalOutputFilename(contentPreview: currentContentPreview)
                    ShareSheet(items: [convertedMarkdown], suggestedFilename: filename)
                }
            }
            .alert("Alert", isPresented: $showingAlert) {
                Button("OK") { }
            } message: {
                Text(alertMessage)
            }
        }
    }
    
    // MARK: - Paste from Clipboard
    private func pasteFromClipboard() {
        // Validate image path if saveToFolder is selected
        if settings.imageHandling == .saveToFolder && !settings.isValidImagePath() {
            alertMessage = "Invalid image path format. Please check your folder path."
            showingAlert = true
            return
        }
        
        // Validate output filename format
        if !settings.isValidOutputFilename() {
            alertMessage = "Invalid filename format. Please check your filename template."
            showingAlert = true
            return
        }
        
        isConverting = true
        
        Task {
            let result = await clipboardService.processClipboardWithFiles()
            
            await MainActor.run {
                switch result {
                case .success(let processingResult):
                    self.convertedMarkdown = processingResult.markdown
                    self.processingResult = processingResult
                    
                    // Store content preview for filename generation
                    if let firstLine = processingResult.markdown.components(separatedBy: .newlines).first(where: { !$0.isEmpty && !$0.hasPrefix("---") }) {
                        self.currentContentPreview = String(firstLine.prefix(100))
                    }
                    
                    // Clean up old temp files
                    FileManagerUtilities.cleanupTempFiles()
                    
                case .failure(let error):
                    self.alertMessage = error.localizedDescription
                    self.showingAlert = true
                }
                self.isConverting = false
            }
        }
    }
}

#Preview {
    ContentView()
}
