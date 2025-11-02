//
//  FileNameSection.swift
//  pastedown-v1
//
//  Created by extracting from TemplateSettingsView
//

import SwiftUI

struct FileNameSection: View {
    @ObservedObject var viewModel: TemplateSettingsViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: AppSpacing.xs) {
            // Title
            Text("File Name Format")
                .font(.app.title)
                .foregroundColor(.theme.textPrimary)


            // Caption
            VStack(alignment: .leading) {

            Text("Click the tags on the right to insert variables like {date} or {time} or {clipboard_preview}. Preview:")
                .font(.app.caption)
                .foregroundColor(.theme.textSecondary)
        
            // Preview or error
            if viewModel.isValidOutputFilename() {
                PreviewText(preview: viewModel.generateFilenamePreview())
            } else {
                Text("Invalid filename format")
                    .font(.app.caption)
                    .foregroundColor(.theme.error)
            }
            }

            // Input field
            TextFieldWithVariablePicker(
                title: "Output filename format (without .md)",
                text: $viewModel.outputFilenameFormat,
                context: .filename,
                settings: viewModel.cachedSettings
            )
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
