//
//  AltTextSettingsView.swift
//  pastedown-v1
//
//  Created by extracting from TemplateSettingsView
//

import SwiftUI

struct AltTextSettingsView: View {
    @ObservedObject var viewModel: TemplateSettingsViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: AppSpacing.md) {
            // Alt Text Method Picker
            VStack(alignment: .leading, spacing: AppSpacing.xs) {
                Text("Alt Text Method")
                    .font(.app.calloutSemibold)
                    .foregroundColor(.theme.textPrimary)

                Picker("Alt Text Method", selection: Binding(
                    get: {
                        if viewModel.useExternalAPI {
                            return 1 // LLM Generated
                        } else if viewModel.altTextTemplate == .objects {
                            return 2 // Fixed Alt Text
                        } else {
                            return 0 // Apple Vision Generated
                        }
                    },
                    set: { newValue in
                        switch newValue {
                        case 0: // Apple Vision Generated
                            viewModel.useExternalAPI = false
                            viewModel.altTextTemplate = .imageOf
                        case 1: // LLM Generated
                            viewModel.useExternalAPI = true
                        case 2: // Fixed Alt Text
                            viewModel.useExternalAPI = false
                            viewModel.altTextTemplate = .objects
                        default:
                            break
                        }
                    }
                )) {
                    Text("Apple Vision").tag(0)
                    Text("External LLM").tag(1)
                    Text("Fixed").tag(2)
                }
                .pickerStyle(SegmentedPickerStyle())
            }

            // Method-specific settings
            if viewModel.useExternalAPI {
                LLMGeneratedSettings(viewModel: viewModel)
            } else if viewModel.altTextTemplate == .objects {
                FixedAltTextSettings(viewModel: viewModel)
            } else {
                AppleVisionSettings(viewModel: viewModel)
            }
        }
    }
}

// MARK: - LLM Generated Settings

struct LLMGeneratedSettings: View {
    @ObservedObject var viewModel: TemplateSettingsViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: AppSpacing.sm) {
            VStack(alignment: .leading, spacing: AppSpacing.xs) {
                Text("LLM Provider")
                    .font(.app.calloutSemibold)
                    .foregroundColor(.theme.textPrimary)

                Picker("LLM Provider", selection: $viewModel.llmProvider) {
                    ForEach(LLMProvider.allCases, id: \.self) { provider in
                        Text(provider.displayName).tag(provider)
                    }
                }
                .pickerStyle(MenuPickerStyle())
                .fullWidthPickerStyle()
            }

            VStack(alignment: .leading, spacing: AppSpacing.xs) {
                Text("API Key")
                    .font(.app.calloutSemibold)
                    .foregroundColor(.theme.textPrimary)

                SecureField("Enter API key", text: $viewModel.apiKey)
                    .textFieldStyle(isError: !viewModel.isValidAPIKey())
            }

            VStack(alignment: .leading, spacing: AppSpacing.xs) {
                Text("Custom Prompt (Optional)")
                    .font(.app.calloutSemibold)
                    .foregroundColor(.theme.textPrimary)

                ZStack(alignment: .topLeading) {
                    TextEditor(text: $viewModel.customPrompt)
                        .textEditorStyle(minHeight: 80)

                    if viewModel.customPrompt.isEmpty {
                        Text("Leave empty to use default: \(ImageAnalyzer.defaultPrompt)")
                            .font(.app.body)
                            .foregroundColor(.theme.textTertiary)
                            .padding(.horizontal, AppSpacing.sm)
                            .padding(.vertical, AppSpacing.sm)
                            .allowsHitTesting(false)
                    }
                }
            }
        }
    }
}

// MARK: - Fixed Alt Text Settings

struct FixedAltTextSettings: View {
    @ObservedObject var viewModel: TemplateSettingsViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: AppSpacing.xs) {
            Text("Fixed Alt Text")
                .font(.app.calloutSemibold)
                .foregroundColor(.theme.textPrimary)

            TextField("Enter fixed alt text", text: $viewModel.fixedAltText)
                .textFieldStyle()

            Text("This text will be used for all images")
                .font(.app.caption)
                .foregroundColor(.theme.textSecondary)
        }
    }
}

// MARK: - Apple Vision Settings

struct AppleVisionSettings: View {
    @ObservedObject var viewModel: TemplateSettingsViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: AppSpacing.xs) {
            Text("Apple Vision Generated")
                .font(.app.calloutSemibold)
                .foregroundColor(.theme.textPrimary)

            Picker("Template", selection: $viewModel.altTextTemplate) {
                ForEach(AltTextTemplate.allCases.filter { $0 != .objects }, id: \.self) { template in
                    Text(template.displayName).tag(template)
                }
            }
            .pickerStyle(MenuPickerStyle())
            .fullWidthPickerStyle()

            Text("Uses Apple Vision to detect objects and text in images")
                .font(.app.caption)
                .foregroundColor(.theme.textSecondary)
        }
    }
}
