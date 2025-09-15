//
//  AdvancedSettingsView.swift
//  pastedown-v1
//
//  Created by 劉羽芯 on 2025/6/30.
//
 import SwiftUI

// MARK: - Advanced Settings View
struct AdvancedSettingsView: View {
    @ObservedObject var settings: SettingsStore
    @Environment(\.presentationMode) var presentationMode
    @Environment(\.editMode) var editMode

    // Template management state
    @State private var showingSaveTemplateDialog = false
    @State private var showingRenameDialog = false
    @State private var showingDuplicateDialog = false
    @State private var showingDeleteConfirmation = false
    @State private var templateName = ""
    @State private var renameName = ""
    @State private var duplicateName = ""
    @State private var selectedTemplate: FrontMatterTemplate?
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: 
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Front Matter Template")
                        if !settings.frontMatterFields.isEmpty {
                            Text("Tap 'Edit' to reorder fields by dragging")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                ) {
                    ForEach($settings.frontMatterFields) { $field in
                        SmartFrontMatterFieldView(field: $field, settings: settings) {
                            if let index = settings.frontMatterFields.firstIndex(where: { $0.id == field.id }) {
                                settings.frontMatterFields[index] = field
                                settings.saveSettings()
                            }
                        }
                    }
                    .onDelete(perform: deleteFrontMatterField)
                    .onMove(perform: moveFrontMatterField)
                    
                    // Add new field
                    SmartAddNewFieldView(settings: settings) { newField in
                        settings.frontMatterFields.append(newField)
                        settings.saveSettings()
                    }

                    // Save current as template button
                    if !settings.frontMatterFields.isEmpty {
                        Button(action: {
                            templateName = ""
                            showingSaveTemplateDialog = true
                        }) {
                            HStack {
                                Image(systemName: "square.and.arrow.down")
                                Text("Save Current as Template")
                            }
                        }
                        .foregroundColor(.blue)
                    }
                }

                // Saved Templates Section
                if !settings.savedTemplates.isEmpty {
                    Section(header:
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Saved Templates")
                            Text("\(settings.savedTemplates.count) template(s) available")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    ) {
                        ForEach(settings.savedTemplates) { template in
                            TemplateRowView(
                                template: template,
                                settings: settings,
                                onApply: {
                                    settings.applyTemplate(template)
                                },
                                onRename: {
                                    selectedTemplate = template
                                    renameName = template.name
                                    showingRenameDialog = true
                                },
                                onDuplicate: {
                                    selectedTemplate = template
                                    duplicateName = "\(template.name) Copy"
                                    showingDuplicateDialog = true
                                },
                                onDelete: {
                                    selectedTemplate = template
                                    showingDeleteConfirmation = true
                                }
                            )
                        }
                    }
                }

                Section("LLM Alt Text Generation") {
                    Toggle("Use LLM for Alt Text", isOn: $settings.useExternalAPI)
                        .onChange(of: settings.useExternalAPI) { oldValue, newValue in
                            settings.saveSettings()
                        }
                    
                    if settings.useExternalAPI {
                        VStack(alignment: .leading, spacing: 12) {
                            HStack {
                                Text("Provider")
                                Spacer()
                                Picker("LLM Provider", selection: $settings.llmProvider) {
                                    ForEach(LLMProvider.allCases) { provider in
                                        Text(provider.displayName).tag(provider)
                                    }
                                }
                                .pickerStyle(MenuPickerStyle())
                                .onChange(of: settings.llmProvider) { oldValue, newValue in
                                    settings.saveSettings()
                                }
                            }
                            
                            SecureField("API Key", text: $settings.apiKey)
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                                .onChange(of: settings.apiKey) { oldValue, newValue in
                                    settings.saveSettings()
                                }
                            
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Custom Prompt (optional)")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                TextField("Leave empty to use default prompt", text: $settings.customPrompt, axis: .vertical)
                                    .textFieldStyle(RoundedBorderTextFieldStyle())
                                    .onChange(of: settings.customPrompt) { oldValue, newValue in
                                        settings.saveSettings()
                                    }
                                Text("Default: Generate concise, descriptive alt text focusing on main content and context.")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                }
                
                Section("Template Variables Help") {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Available variables for Front Matter and filenames:")
                            .font(.subheadline)
                            .fontWeight(.medium)
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Filename variables:")
                                .fontWeight(.medium)
                            Text("• {clipboard_preview} - First 20 chars of clipboard")
                            Text("• {date} - Current date (YYYY-MM-DD)")
                            Text("• {time} - Current time (YYYY-MM-DD_HH-MM-SS)")
                            
                            Text("Front Matter variables:")
                                .fontWeight(.medium)
                                .padding(.top, 8)
                            Text("• {title} - Front Matter title field")
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
                ToolbarItem(placement: .navigationBarLeading) {
                    EditButton()
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        settings.saveSettings()
                        presentationMode.wrappedValue.dismiss()
                    }
                }
            }
        }
        .sheet(isPresented: $showingSaveTemplateDialog) {
            SaveTemplateDialog(
                isPresented: $showingSaveTemplateDialog,
                templateName: $templateName,
                onSave: { _ in },
                settings: settings
            )
        }
        .sheet(isPresented: $showingRenameDialog) {
            if let template = selectedTemplate {
                RenameTemplateDialog(
                    isPresented: $showingRenameDialog,
                    newName: $renameName,
                    template: template,
                    settings: settings,
                    onRename: { _ in }
                )
            }
        }
        .sheet(isPresented: $showingDuplicateDialog) {
            if let template = selectedTemplate {
                DuplicateTemplateDialog(
                    isPresented: $showingDuplicateDialog,
                    duplicateName: $duplicateName,
                    template: template,
                    settings: settings,
                    onDuplicate: { _ in }
                )
            }
        }
        .alert("Delete Template", isPresented: $showingDeleteConfirmation) {
            Button("Cancel", role: .cancel) { }
            Button("Delete", role: .destructive) {
                if let template = selectedTemplate {
                    settings.deleteTemplate(template)
                }
            }
        } message: {
            if let template = selectedTemplate {
                Text("Are you sure you want to delete '\(template.name)'? This action cannot be undone.")
            }
        }
    }
    
    private func deleteFrontMatterField(offsets: IndexSet) {
        settings.frontMatterFields.remove(atOffsets: offsets)
        settings.saveSettings()
    }
    
    private func moveFrontMatterField(from source: IndexSet, to destination: Int) {
        settings.frontMatterFields.move(fromOffsets: source, toOffset: destination)
        settings.saveSettings()
    }
}


