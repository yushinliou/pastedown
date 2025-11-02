//
//  ImageHandlingSection.swift
//  pastedown-v1
//
//  Created by extracting from TemplateSettingsView
//

import SwiftUI

struct ImageHandlingSection: View {
    @ObservedObject var viewModel: TemplateSettingsViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: AppSpacing.xs) {

            // Title
            Text("Pasted Image")
                .font(.app.title)
                .foregroundColor(.theme.textPrimary)

            VStack(alignment: .leading) {

                // Caption
                Text("Choose how pasted images are handled in your markdown files.")
                    .font(.app.caption)
                    .foregroundColor(.theme.textSecondary)
            }
            .padding(.bottom, AppSpacing.sm)

            // Custom Menu for Image Handling
            Menu {
                Picker("Image Handling", selection: $viewModel.imageHandling) {
                    ForEach(ImageHandling.allCases, id: \.self) { handling in
                        Text(handling.displayName).tag(handling)
                    }
                }
            } label: {
                CustomMenuLabel(text: viewModel.imageHandling.displayName)
            }

            // Image handling specific settings
            if viewModel.imageHandling == .saveToFolder {
                ImageFolderPathSettings(viewModel: viewModel)
            } else if viewModel.imageHandling == .base64 {
                Text("Embed images directly into Markdown as Base64 strings:")
                    .font(.app.caption)
                    .foregroundColor(.theme.textSecondary)
                PreviewText(label: "Image preview:", preview: viewModel.generateImageHandlingPreview())
            } else {
                Text("Images will be replaced with a comment:")
                    .font(.app.caption)
                    .foregroundColor(.theme.textSecondary)
                PreviewText(label: "Image preview:", preview: viewModel.generateImageHandlingPreview())
            }

            // Alt Text Generation section
            if viewModel.imageHandling != .ignore {
                VStack(alignment: .leading, spacing: AppSpacing.sm) {
                    HStack {
                        Text("Alt Text Generation")
                            .font(.app.body)
                            .foregroundColor(.theme.textPrimary)

                        Spacer()

                        Toggle("", isOn: $viewModel.enableAutoAlt)
                    }

                    if viewModel.enableAutoAlt {
                        AltTextSettingsView(viewModel: viewModel)
                    }
                }
            }
        }
        .padding(.bottom, AppSpacing.lg)
        .background(Color.theme.surfaceCard)
        .overlay(
            VStack {
                Spacer()
                Rectangle()
                    .fill(Color.theme.surfaceBorder)
                    .frame(height: 1)
            }
        )
    }
}

// MARK: - Image Folder Path Settings

struct ImageFolderPathSettings: View {
    @ObservedObject var viewModel: TemplateSettingsViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: AppSpacing.xs) {

            TextFieldWithVariablePicker(
                title: "Image folder path",
                text: $viewModel.imageFolderPath,
                context: .filename,
                settings: viewModel.cachedSettings
            )
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(viewModel.isValidImagePath() ? Color.clear : Color.red, lineWidth: 1)
            )

            Text("Set the image save path. Click the tag icon to insert variables like {date} or {time} or {clipboard_preview}. Preview:")
                .font(.app.caption)
                .foregroundColor(.theme.textSecondary)
            
            if viewModel.isValidImagePath() {
                PreviewText(label: "Image path preview:", preview: viewModel.generateImagePathPreview())
            } else {
                Text("Invalid path format")
                    .font(.app.caption)
                    .foregroundColor(.theme.error)
            }
        }
        .padding(.top, AppSpacing.sm)
    }
}

