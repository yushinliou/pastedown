//
//  TemplateManagementView.swift
//  pastedown-v1
//
//  Created by Claude Code on 2025/9/15.
//

import SwiftUI

// MARK: - Template Row View
struct TemplateRowView: View {
    let template: FrontMatterTemplate
    let settings: SettingsStore
    let onApply: () -> Void
    let onRename: () -> Void
    let onDuplicate: () -> Void
    let onDelete: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text(template.name)
                        .font(.headline)
                        .foregroundColor(.primary)

                    Text("\(template.fieldCount) fields")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                Spacer()

                VStack(alignment: .trailing, spacing: 2) {
                    Text("Created \(template.formattedCreatedDate)")
                        .font(.caption2)
                        .foregroundColor(.secondary)

                    if let lastUsed = template.formattedLastUsedDate {
                        Text("Last used \(lastUsed)")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                }
            }

            // Field preview
            if !template.fieldNames.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 4) {
                        ForEach(template.fieldNames.prefix(5), id: \.self) { fieldName in
                            Text(fieldName)
                                .font(.caption2)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(Color.blue.opacity(0.1))
                                .foregroundColor(.blue)
                                .cornerRadius(3)
                        }

                        if template.fieldNames.count > 5 {
                            Text("...")
                                .font(.caption2)
                                .foregroundColor(.secondary)
                        }
                    }
                }
            }

            // Action buttons
            HStack(spacing: 12) {
                Button("Apply") {
                    onApply()
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.small)

                Button("Rename") {
                    onRename()
                }
                .buttonStyle(.bordered)
                .controlSize(.small)

                Button("Duplicate") {
                    onDuplicate()
                }
                .buttonStyle(.bordered)
                .controlSize(.small)

                Spacer()

                Button("Delete") {
                    onDelete()
                }
                .buttonStyle(.bordered)
                .controlSize(.small)
                .foregroundColor(.red)
            }
        }
        .padding(.vertical, 8)
    }
}

// MARK: - Save Template Dialog
struct SaveTemplateDialog: View {
    @Binding var isPresented: Bool
    @Binding var templateName: String
    let onSave: (String) -> Void
    let settings: SettingsStore

    @State private var showingError = false
    @State private var errorMessage = ""

    var body: some View {
        NavigationView {
            Form {
                Section {
                    TextField("Template name", text: $templateName)
                        .textInputAutocapitalization(.words)
                        .autocorrectionDisabled()
                } header: {
                    Text("Save Current Front Matter as Template")
                } footer: {
                    if settings.frontMatterFields.isEmpty {
                        Text("Add some front matter fields before saving a template")
                            .foregroundColor(.red)
                    } else {
                        Text("This will save your current \(settings.frontMatterFields.count) front matter fields as a reusable template")
                    }
                }
            }
            .navigationTitle("New Template")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        isPresented = false
                    }
                }

                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        saveTemplate()
                    }
                    .disabled(templateName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || settings.frontMatterFields.isEmpty)
                }
            }
        }
        .alert("Error", isPresented: $showingError) {
            Button("OK") { }
        } message: {
            Text(errorMessage)
        }
    }

    private func saveTemplate() {
        let trimmedName = templateName.trimmingCharacters(in: .whitespacesAndNewlines)

        if !settings.isTemplateNameAvailable(trimmedName) {
            errorMessage = "A template with this name already exists"
            showingError = true
            return
        }

        if settings.saveCurrentAsTemplate(name: trimmedName) {
            onSave(trimmedName)
            isPresented = false
        } else {
            errorMessage = "Failed to save template"
            showingError = true
        }
    }
}

// MARK: - Rename Template Dialog
struct RenameTemplateDialog: View {
    @Binding var isPresented: Bool
    @Binding var newName: String
    let template: FrontMatterTemplate
    let settings: SettingsStore
    let onRename: (String) -> Void

    @State private var showingError = false
    @State private var errorMessage = ""

    var body: some View {
        NavigationView {
            Form {
                Section {
                    TextField("Template name", text: $newName)
                        .textInputAutocapitalization(.words)
                        .autocorrectionDisabled()
                } header: {
                    Text("Rename Template")
                } footer: {
                    Text("Enter a new name for '\(template.name)'")
                }
            }
            .navigationTitle("Rename")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        isPresented = false
                    }
                }

                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        renameTemplate()
                    }
                    .disabled(newName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
        }
        .alert("Error", isPresented: $showingError) {
            Button("OK") { }
        } message: {
            Text(errorMessage)
        }
    }

    private func renameTemplate() {
        let trimmedName = newName.trimmingCharacters(in: .whitespacesAndNewlines)

        if trimmedName == template.name {
            isPresented = false
            return
        }

        if settings.savedTemplates.contains(where: { $0.name == trimmedName && $0.id != template.id }) {
            errorMessage = "A template with this name already exists"
            showingError = true
            return
        }

        if settings.renameTemplate(template, newName: trimmedName) {
            onRename(trimmedName)
            isPresented = false
        } else {
            errorMessage = "Failed to rename template"
            showingError = true
        }
    }
}

// MARK: - Duplicate Template Dialog
struct DuplicateTemplateDialog: View {
    @Binding var isPresented: Bool
    @Binding var duplicateName: String
    let template: FrontMatterTemplate
    let settings: SettingsStore
    let onDuplicate: (String) -> Void

    @State private var showingError = false
    @State private var errorMessage = ""

    var body: some View {
        NavigationView {
            Form {
                Section {
                    TextField("Template name", text: $duplicateName)
                        .textInputAutocapitalization(.words)
                        .autocorrectionDisabled()
                } header: {
                    Text("Duplicate Template")
                } footer: {
                    Text("This will create a copy of '\(template.name)' with \(template.fieldCount) fields")
                }
            }
            .navigationTitle("Duplicate")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        isPresented = false
                    }
                }

                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Create") {
                        duplicateTemplate()
                    }
                    .disabled(duplicateName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
        }
        .alert("Error", isPresented: $showingError) {
            Button("OK") { }
        } message: {
            Text(errorMessage)
        }
    }

    private func duplicateTemplate() {
        let trimmedName = duplicateName.trimmingCharacters(in: .whitespacesAndNewlines)

        if !settings.isTemplateNameAvailable(trimmedName) {
            errorMessage = "A template with this name already exists"
            showingError = true
            return
        }

        if settings.duplicateTemplate(template, newName: trimmedName) {
            onDuplicate(trimmedName)
            isPresented = false
        } else {
            errorMessage = "Failed to duplicate template"
            showingError = true
        }
    }
}