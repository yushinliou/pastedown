//
//  FrontMatterSection.swift
//  pastedown-v1
//
//  Created by extracting from TemplateSettingsView
//

import SwiftUI

struct FrontMatterSection: View {
    @ObservedObject var viewModel: TemplateSettingsViewModel

    var body: some View {

        VStack(alignment: .leading, spacing: AppSpacing.xs) {
            // Header with title and edit button
            HStack {
                VStack(alignment: .leading, spacing: AppSpacing.xs) {
                Text("Front Matter")
                    .font(.app.title)
                    .foregroundColor(.theme.textPrimary)  
                // Caption text
                if viewModel.enableFrontMatter {
                    if viewModel.isEditingFields {
                        Text("Tap and drag to reorder fields, or tap the minus button to remove them")
                            .font(.app.caption)
                            .foregroundColor(.theme.textSecondary)
                            
                    } else {
                        Text("Configure YAML front matter fields that will be added to your Markdown output")
                            .font(.app.caption)
                            .foregroundColor(.theme.textSecondary)
                    }
                } else {
                    Text("Front matter is disabled. Toggle on to add YAML metadata to your files")
                        .font(.app.caption)
                        .foregroundColor(.theme.textSecondary)
                        
                }                  
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                // .border(Color.red)

                // Front Matter toggle
                Toggle("", isOn: $viewModel.enableFrontMatter)
                .fixedSize() // Prevent toggle from stretching
                // .border(Color.red)
            }
            


            if viewModel.enableFrontMatter {
                if viewModel.isEditingFields {
                    EditModeFrontMatterView(viewModel: viewModel)
                } else {
                    ViewModeFrontMatterView(viewModel: viewModel)
                }
                if !viewModel.isEditingFields {
                    AddNewFieldSection(viewModel: viewModel)
                }
                
            }


            // if viewModel.enableFrontMatter {
            //     if viewModel.frontMatterFields.isEmpty {
            //         EmptyFrontMatterView(viewModel: viewModel)
            //     } else {
            //         if viewModel.isEditingFields {
            //             EditModeFrontMatterView(viewModel: viewModel)
            //         } else {
            //             ViewModeFrontMatterView(viewModel: viewModel)
            //         }
            //     }

            //     if !viewModel.isEditingFields {
            //         AddNewFieldSection(viewModel: viewModel)
            //     }
            // }
            
        // Edit button
        if viewModel.enableFrontMatter { //  && !viewModel.frontMatterFields.isEmpty 
                Button(viewModel.isEditingFields ? "Done" : "Edit") {
                    viewModel.isEditingFields.toggle()
                }
                .font(.app.calloutSemibold)
                .foregroundColor(.theme.primary)
                .frame(maxWidth: .infinity, alignment: .trailing)
                .padding(.horizontal, AppSpacing.xs)
                // .border(Color.red)
        }

        }
        .background(Color.theme.surfaceCard)
    }
}

// MARK: - Empty Front Matter View

struct EmptyFrontMatterView: View {
    @ObservedObject var viewModel: TemplateSettingsViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: AppSpacing.sm) {

            Button {
                // Add a default field to get started
                let defaultField = FrontMatterField(name: "title", type: .string, value: "")
                viewModel.frontMatterFields.append(defaultField)
            } label: {
                HStack {
                    Image(systemName: "plus.circle.fill")
                    Text("Add Front Matter Field")
                }
                .font(.app.calloutSemibold)
                .foregroundColor(.theme.primary)
            }
        }
    }
}

// MARK: - Edit Mode Front Matter View

struct EditModeFrontMatterView: View {
    @ObservedObject var viewModel: TemplateSettingsViewModel

    var body: some View {
        ForEach(Array(viewModel.frontMatterFields.enumerated()), id: \.element.id) { index, field in
            HStack {
                Image(systemName: "line.3.horizontal")
                    .foregroundColor(.theme.textTertiary)
                    .padding(.trailing, AppSpacing.xs)

                VStack(alignment: .leading, spacing: AppSpacing.xxs) {
                    Text(field.name.isEmpty ? "Unnamed Field" : field.name)
                        .font(.app.calloutSemibold)
                        .foregroundColor(.theme.textPrimary)

                    Text(field.type.displayName)
                        .font(.app.caption)
                        .foregroundColor(.theme.textSecondary)

                    if !field.value.isEmpty {
                        Text(field.value.prefix(30) + (field.value.count > 30 ? "..." : ""))
                            .font(.app.caption)
                            .foregroundColor(.theme.primary)
                    }
                }

                Spacer()

                Button {
                    viewModel.frontMatterFields.remove(at: index)
                } label: {
                    Image(systemName: "minus.circle.fill")
                        .foregroundColor(.theme.error)
                }
            }
            .padding(.vertical, AppSpacing.xxs)
        }
        .onMove(perform: viewModel.moveFields)
        .onDelete(perform: viewModel.deleteFields)
    }
}

// MARK: - View Mode Front Matter View

struct ViewModeFrontMatterView: View {
    @ObservedObject var viewModel: TemplateSettingsViewModel

    var body: some View {
        ForEach(Array(viewModel.frontMatterFields.enumerated()), id: \.element.id) { index, _ in
            VStack(alignment: .leading, spacing: AppSpacing.xs) {
                SmartFrontMatterFieldView(
                    field: $viewModel.frontMatterFields[index],
                    settings: viewModel.cachedSettings,
                    onUpdate: {
                        // Update triggered when field changes
                    }
                )
            }
            .padding(.vertical, AppSpacing.xs)
        }
    }
}

// MARK: - Add New Field Section

struct AddNewFieldSection: View {
    @FocusState private var isAddingField: Bool
    @ObservedObject var viewModel: TemplateSettingsViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: AppSpacing.xs) {

            SmartAddNewFieldView(settings: viewModel.cachedSettings) { newField in
                viewModel.frontMatterFields.append(newField)
            }
            .focused($isAddingField)
        }
        .padding(AppSpacing.sm)
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(isAddingField ? Color.theme.inputFieldSurfaceFocus : .clear, lineWidth: 2)
        )
        .background(isAddingField ? Color.theme.inputFieldSurfaceFocus : Color.theme.surfaceCard)
    }
}
