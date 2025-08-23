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
    @State private var showingShareSheet = false
    @State private var showingAlert = false
    @State private var alertMessage = ""
    @State private var isConverting = false
    @State private var showingAdvancedSettings = false
    
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
    
    // MARK: - Paste from Clipboard
    private func pasteFromClipboard() {
        isConverting = true
        
        Task {
            let result = await clipboardService.processClipboard()
            
            await MainActor.run {
                switch result {
                case .success(let markdown):
                    self.convertedMarkdown = markdown
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
