//
//  TemplateManagementListView.swift
//  pastedown-v1
//
//  Created by Claude Code on 2025/9/22.
//

import SwiftUI

struct TemplateManagementListView: View {
    @ObservedObject var settings: SettingsStore
    @Binding var isPresented: Bool

    @State private var isEditMode = false
    @State private var showingNewTemplate = false
    @State private var templateToEdit: Template?
    @State private var templateToRename: Template?
    @State private var templateToDuplicate: Template?
    @State private var newName = ""
    @State private var showingDeleteAlert = false
    @State private var templateToDelete: Template?

    private var isDuplicateNameValid: Bool {
        guard templateToDuplicate != nil else { return false }
        let trimmedName = newName.trimmingCharacters(in: .whitespacesAndNewlines)
        return !trimmedName.isEmpty && settings.isTemplateNameValid(trimmedName)
    }

    var body: some View {
        NavigationView {
            List {
                if settings.templates.isEmpty {
                    VStack(spacing: 16) {
                        Image(systemName: "folder.badge.plus")
                            .font(.system(size: 50))
                            .foregroundColor(.secondary)

                        Text("No Templates")
                            .font(.title2)
                            .fontWeight(.medium)
                            .foregroundColor(.secondary)

                        Text("Create your first template to get started")
                            .font(.body)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)

                        Button {
                            showingNewTemplate = true
                        } label: {
                            Text("Create Template")
                                .font(.headline)
                                .foregroundColor(.white)
                                .padding(.horizontal, 24)
                                .padding(.vertical, 12)
                                .background(Color.blue)
                                .cornerRadius(8)
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 40)
                    .listRowSeparator(.hidden)
                } else {
                    ForEach(settings.templates) { template in
                        TemplateListRowView(
                            template: template,
                            settings: settings,
                            isEditMode: isEditMode,
                            onApply: {
                                settings.applyTemplate(template)
                                isPresented = false
                            },
                            onEdit: {
                                templateToEdit = template
                            },
                            onRename: {
                                templateToRename = template
                                newName = template.name
                            },
                            onDuplicate: {
                                templateToDuplicate = template
                                newName = generateUniqueDuplicateName(for: template)
                            },
                            onDelete: {
                                if template.name != "default" {
                                    templateToDelete = template
                                    showingDeleteAlert = true
                                }
                            }
                        )
                    }
                    .onMove(perform: isEditMode ? settings.moveTemplate : nil)
                    .onDelete(perform: isEditMode ? settings.deleteTemplates : nil)
                }
            }
            .navigationTitle("Templates")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Done") {
                        isPresented = false
                    }
                }

                ToolbarItem(placement: .navigationBarTrailing) {
                    HStack {
                        if !settings.templates.isEmpty {
                            Button(isEditMode ? "Done" : "Edit") {
                                withAnimation {
                                    isEditMode.toggle()
                                }
                            }
                        }

                        Button {
                            showingNewTemplate = true
                        } label: {
                            Image(systemName: "plus")
                        }
                    }
                }
            }
            .environment(\.editMode, .constant(isEditMode ? .active : .inactive))
        }
        .sheet(isPresented: $showingNewTemplate) {
            TemplateSettingsView(settings: settings, isPresented: $showingNewTemplate)
        }
        .sheet(item: $templateToEdit) { template in
            TemplateSettingsView(settings: settings, isPresented: Binding(
                get: { templateToEdit != nil },
                set: { if !$0 { templateToEdit = nil } }
            ), template: template)
        }
        .alert("Rename Template", isPresented: Binding(
            get: { templateToRename != nil },
            set: { if !$0 { templateToRename = nil } }
        )) {
            TextField("Template name", text: $newName)
                .autocapitalization(.none)
                .disableAutocorrection(true)
            Button("Cancel", role: .cancel) {
                templateToRename = nil
            }
            Button("Rename") {
                if let template = templateToRename {
                    _ = settings.renameTemplate(template, newName: newName)
                    templateToRename = nil
                }
            }
            .disabled(!isValidNewName(for: templateToRename))
        } message: {
            if let template = templateToRename {
                let trimmedName = newName.trimmingCharacters(in: .whitespacesAndNewlines)
                if trimmedName.isEmpty {
                    Text("Please enter a template name")
                } else if !settings.isTemplateNameValid(trimmedName) || (trimmedName != template.name && settings.templates.contains(where: { $0.name == trimmedName })) {
                    Text("A template with this name already exists")
                } else {
                    Text("Enter a new name for '\(template.name)'")
                }
            }
        }
        .alert("Duplicate Template", isPresented: Binding(
            get: { templateToDuplicate != nil },
            set: { if !$0 { templateToDuplicate = nil } }
        )) {
            TextField("Template name", text: $newName)
                .autocapitalization(.none)
                .disableAutocorrection(true)
            Button("Cancel", role: .cancel) {
                templateToDuplicate = nil
            }
            Button("Create") {
                if let template = templateToDuplicate {
                    _ = settings.duplicateTemplate(template, newName: newName)
                    templateToDuplicate = nil
                }
            }
            .disabled(!isDuplicateNameValid)
        } message: {
            if let template = templateToDuplicate {
                let trimmedName = newName.trimmingCharacters(in: .whitespacesAndNewlines)
                if trimmedName.isEmpty {
                    Text("❌ Please enter a template name to continue")
                } else if !settings.isTemplateNameValid(trimmedName) {
                    Text("❌ Template name '\(trimmedName)' already exists. Please choose a different name.")
                } else {
                    Text("✅ Create a copy of '\(template.name)' with the name '\(trimmedName)'")
                }
            }
        }
        .alert("Delete Template", isPresented: $showingDeleteAlert) {
            Button("Cancel", role: .cancel) {
                templateToDelete = nil
            }
            Button("Delete", role: .destructive) {
                if let template = templateToDelete {
                    settings.deleteTemplate(template)
                    templateToDelete = nil
                }
            }
        } message: {
            if let template = templateToDelete {
                Text("Are you sure you want to delete '\(template.name)'? This action cannot be undone.")
            }
        }
    }

    private func isValidNewName(for template: Template?) -> Bool {
        let trimmedName = newName.trimmingCharacters(in: .whitespacesAndNewlines)

        // Empty name is invalid
        if trimmedName.isEmpty {
            return false
        }

        // For rename operation
        if let existingTemplate = template {
            // If name hasn't changed, it's valid
            if trimmedName == existingTemplate.name {
                return true
            }
            // Check if new name already exists
            return settings.isTemplateNameValid(trimmedName)
        }

        // For duplicate operation, just check if name is available
        return settings.isTemplateNameValid(trimmedName)
    }

    private func generateUniqueDuplicateName(for template: Template) -> String {
        var baseName = "\(template.name) Copy"
        var counter = 1

        // If "Template Name Copy" is available, use it
        if settings.isTemplateNameValid(baseName) {
            return baseName
        }

        // Otherwise, find "Template Name Copy 2", "Template Name Copy 3", etc.
        while !settings.isTemplateNameValid("\(baseName) \(counter)") {
            counter += 1
        }

        return "\(baseName) \(counter)"
    }
}

struct TemplateListRowView: View {
    let template: Template
    let settings: SettingsStore
    let isEditMode: Bool
    let onApply: () -> Void
    let onEdit: () -> Void
    let onRename: () -> Void
    let onDuplicate: () -> Void
    let onDelete: () -> Void

    var isCurrentTemplate: Bool {
        settings.currentTemplateID == template.id
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text(template.name)
                            .font(.headline)
                            .foregroundColor(.primary)

                        if isCurrentTemplate {
                            Text("ACTIVE")
                                .font(.caption2)
                                .fontWeight(.bold)
                                .foregroundColor(.white)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(Color.blue)
                                .cornerRadius(4)
                        }

                        if template.name == "default" {
                            Text("DEFAULT")
                                .font(.caption2)
                                .fontWeight(.bold)
                                .foregroundColor(.white)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(Color.orange)
                                .cornerRadius(4)
                        }
                    }

                    HStack {
                        Text("\(template.frontMatterFields.count) fields")
                            .font(.caption)
                            .foregroundColor(.secondary)

                        Text("•")
                            .font(.caption)
                            .foregroundColor(.secondary)

                        Text(template.imageHandling.displayName)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }

                    Text("Created \(template.formattedCreatedDate)")
                        .font(.caption2)
                        .foregroundColor(.secondary)

                    if let lastUsed = template.formattedLastUsedDate {
                        Text("Last used \(lastUsed)")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                }

                Spacer()

                if !isEditMode {
                    Menu {
                        Button("Apply Template") {
                            onApply()
                        }

                        Button("Edit") {
                            onEdit()
                        }

                        if template.name != "default" {
                            Button("Rename") {
                                onRename()
                            }
                        }

                        Button("Duplicate") {
                            onDuplicate()
                        }

                        if template.name != "default" {
                            Divider()
                            Button("Delete", role: .destructive) {
                                onDelete()
                            }
                        }
                    } label: {
                        Image(systemName: "ellipsis.circle")
                            .font(.title2)
                            .foregroundColor(.secondary)
                    }
                }
            }

            if !isEditMode && !template.frontMatterFields.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 4) {
                        ForEach(template.frontMatterFields.prefix(5), id: \.id) { field in
                            Text(field.name)
                                .font(.caption2)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(Color.blue.opacity(0.1))
                                .foregroundColor(.blue)
                                .cornerRadius(3)
                        }

                        if template.frontMatterFields.count > 5 {
                            Text("...")
                                .font(.caption2)
                                .foregroundColor(.secondary)
                        }
                    }
                }
            }
        }
        .padding(.vertical, 4)
        .contentShape(Rectangle())
        .onTapGesture {
            if !isEditMode {
                onApply()
            }
        }
    }
}