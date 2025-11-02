//
//  TemplateNameSection.swift
//  pastedown-v1
//
//  Created by extracting from TemplateSettingsView
//

import SwiftUI

struct TemplateNameSection: View {
    @ObservedObject var viewModel: TemplateSettingsViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: AppSpacing.xs) {
            // Title
            Text("Template Name")
                .font(.app.title)
                .foregroundColor(.theme.textPrimary)

            // Caption
            Text("Giving a descriptive name. Eg. blog, meeting note ... etc")
                .font(.app.caption)
                .foregroundColor(.theme.textSecondary)
                .padding(.bottom, AppSpacing.sm)

            // Text Field
            TextField("My Template", text: $viewModel.templateName) // grey text when empty
                .autocapitalization(.none)
                .disableAutocorrection(true)
                .disabled(viewModel.isEditing && viewModel.template?.name == "default")
                .textFieldStyle(isError: !viewModel.isValidTemplateName())

            // Error Message
            if let errorMessage = viewModel.getTemplateNameError() {
                Text(errorMessage)
                    .font(.app.caption)
                    .foregroundColor(.theme.error)
                    .padding(.top, AppSpacing.xxs)
            }
        }
        .padding(.vertical, AppSpacing.lg)
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
