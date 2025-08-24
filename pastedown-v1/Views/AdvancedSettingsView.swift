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
    @State private var newFieldName = ""
    @State private var newFieldType = FrontMatterType.string
    @State private var newFieldValue = ""
    
    var body: some View {
        NavigationView {
            Form {
                Section("Front Matter Template") {
                    ForEach(settings.frontMatterFields) { field in
                        FrontMatterFieldRow(field: field, settings: settings)
                    }
                    .onDelete(perform: deleteFrontMatterField)
                    
                    // Add new field
                    VStack(alignment: .leading) {
                        HStack {
                            TextField("Field name", text: $newFieldName)
                            Picker("Type", selection: $newFieldType) {
                                ForEach(FrontMatterType.allCases, id: \.self) { type in
                                    Text(type.displayName).tag(type)
                                }
                            }
                            .pickerStyle(MenuPickerStyle())
                        }
                        
                        TextField("Value", text: $newFieldValue)
                        
                        Button("Add Field") {
                            let newField = FrontMatterField(name: newFieldName, type: newFieldType, value: newFieldValue)
                            settings.frontMatterFields.append(newField)
                            newFieldName = ""
                            newFieldValue = ""
                            settings.saveSettings()
                        }
                        .disabled(newFieldName.isEmpty)
                    }
                }
                
                Section("External API Settings") {
                    Toggle("Use external API", isOn: $settings.useExternalAPI)
                        .onChange(of: settings.useExternalAPI) {  oldValue, newValue in
                            print("\(oldValue) -> \(newValue)")
                            settings.saveSettings()
                        }
                    
                    if settings.useExternalAPI {
                        SecureField("API Key", text: $settings.apiKey)
                            .onChange(of: settings.apiKey) {  oldValue, newValue in
                                print("\(oldValue) -> \(newValue)")
                                settings.saveSettings()
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
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        settings.saveSettings()
                        presentationMode.wrappedValue.dismiss()
                    }
                }
            }
        }
    }
    
    private func deleteFrontMatterField(offsets: IndexSet) {
        settings.frontMatterFields.remove(atOffsets: offsets)
        settings.saveSettings()
    }
}

struct FrontMatterFieldRow: View {
    @State var field: FrontMatterField
    @ObservedObject var settings: SettingsStore
    
    var body: some View {
        VStack(alignment: .leading) {
            HStack {
                TextField("Name", text: $field.name)
                    .onChange(of: field.name) {  oldValue, newValue in
                        print("\(oldValue) -> \(newValue)")
                        updateField() }
                
                Picker("Type", selection: $field.type) {
                    ForEach(FrontMatterType.allCases, id: \.self) { type in
                        Text(type.displayName).tag(type)
                    }
                }
                .pickerStyle(MenuPickerStyle())
                .onChange(of: field.type) {  oldValue, newValue in
                    print("\(oldValue) -> \(newValue)")
                    updateField() }
            }
            
            TextField("Value", text: $field.value)
                .onChange(of: field.value) {  oldValue, newValue in
                    print("\(oldValue) -> \(newValue)")
                    updateField() }
        }
    }
    
    private func updateField() {
        if let index = settings.frontMatterFields.firstIndex(where: { $0.id == field.id }) {
            settings.frontMatterFields[index] = field
        }
    }
}

