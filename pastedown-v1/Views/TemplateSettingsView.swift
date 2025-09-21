//
//  TemplateSettingsView.swift
//  pastedown-v1
//
//  Created by Claude Code on 2025/9/21.
//

import SwiftUI

struct TemplateSettingsView: View {
    @ObservedObject var settings: SettingsStore
    @Binding var isPresented: Bool

    let template: Template?
    let isEditing: Bool

    @State private var templateName: String = ""
    @State private var outputFilenameFormat: String = ""
    @State private var imageHandling: ImageHandling = .ignore
    @State private var imageFolderPath: String = ""
    @State private var enableAutoAlt: Bool = true
    @State private var altTextTemplate: AltTextTemplate = .imageOf
    @State private var useExternalAPI: Bool = false
    @State private var apiKey: String = ""
    @State private var llmProvider: LLMProvider = .openai
    @State private var customPrompt: String = ""
    @State private var fixedAltText: String = "alt"
    @State private var frontMatterFields: [FrontMatterField] = []
    @State private var enableFrontMatter: Bool = true
    @State private var isEditingFields = false

    @State private var showingAlert = false
    @State private var alertMessage = ""

    init(settings: SettingsStore, isPresented: Binding<Bool>, template: Template? = nil) {
        self.settings = settings
        self._isPresented = isPresented
        self.template = template
        self.isEditing = template != nil
    }

    var body: some View {
        NavigationView {
            Form {
                // Section 1: File Name Settings
                Section {
                    VStack(alignment: .leading, spacing: 8) {
                        TextField("Template name", text: $templateName)
                            .autocapitalization(.words)
                            .disableAutocorrection(true)
                            .disabled(isEditing && template?.name == "default")

                        TextFieldWithVariablePicker(
                            title: "Output filename format (without .md)",
                            text: $outputFilenameFormat,
                            context: .filename,
                            settings: settings
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(isValidOutputFilename() ? Color.clear : Color.red, lineWidth: 1)
                        )

                        Text("Variables: {clipboard_preview}, {date}, {time}")
                            .font(.caption2)
                            .foregroundColor(.secondary)

                        if isValidOutputFilename() {
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Preview:")
                                    .font(.caption2)
                                    .fontWeight(.medium)
                                    .foregroundColor(.secondary)
                                Text(generateFilenamePreview())
                                    .font(.caption2)
                                    .foregroundColor(.blue)
                                    .padding(.horizontal, 6)
                                    .padding(.vertical, 2)
                                    .background(Color.blue.opacity(0.1))
                                    .cornerRadius(4)
                            }
                        } else {
                            Text("Invalid filename format")
                                .font(.caption2)
                                .foregroundColor(.red)
                        }
                    }
                } header: {
                    Text(isEditing ? "Template Settings" : "New Template")
                } footer: {
                    if isEditing && template?.name == "default" {
                        Text("The default template name cannot be changed. Configure the output filename format for this template.")
                    } else {
                        Text("Enter a name for this template and configure the output filename format")
                    }
                }

                // Section 2: Image Handling
                Section {
                    Picker("Image handling", selection: $imageHandling) {
                        ForEach(ImageHandling.allCases, id: \.self) { handling in
                            Text(handling.displayName).tag(handling)
                        }
                    }
                    .pickerStyle(SegmentedPickerStyle())

                    if imageHandling == .saveToFolder {
                        VStack(alignment: .leading, spacing: 8) {
                            TextFieldWithVariablePicker(
                                title: "Image folder path",
                                text: $imageFolderPath,
                                context: .filename,
                                settings: settings
                            )
                            .overlay(
                                RoundedRectangle(cornerRadius: 8)
                                    .stroke(isValidImagePath() ? Color.clear : Color.red, lineWidth: 1)
                            )

                            Text("Variables: {time}, {date}, {clipboard_preview}")
                                .font(.caption2)
                                .foregroundColor(.secondary)

                            if isValidImagePath() {
                                VStack(alignment: .leading, spacing: 2) {
                                    Text("Preview:")
                                        .font(.caption2)
                                        .fontWeight(.medium)
                                        .foregroundColor(.secondary)
                                    Text(generateImagePathPreview())
                                        .font(.caption2)
                                        .foregroundColor(.blue)
                                        .padding(.horizontal, 6)
                                        .padding(.vertical, 2)
                                        .background(Color.blue.opacity(0.1))
                                        .cornerRadius(4)
                                }
                            } else {
                                Text("Invalid path format")
                                    .font(.caption2)
                                    .foregroundColor(.red)
                            }
                        }
                    } else {
                        // Preview for ignore and embed modes
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Preview:")
                                .font(.caption2)
                                .fontWeight(.medium)
                                .foregroundColor(.secondary)
                            Text(generateImageHandlingPreview())
                                .font(.caption2)
                                .foregroundColor(.blue)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(Color.blue.opacity(0.1))
                                .cornerRadius(4)
                        }
                    }

                    if imageHandling != .ignore {
                        VStack(alignment: .leading, spacing: 12) {
                            HStack {
                                Text("Alt Text Generation")
                                    .font(.subheadline)
                                    .fontWeight(.medium)

                                Spacer()

                                Toggle("", isOn: $enableAutoAlt)
                            }

                            if enableAutoAlt {
                                VStack(alignment: .leading, spacing: 16) {
                                    // Alt Text Method Picker
                                    VStack(alignment: .leading, spacing: 8) {
                                        Text("Alt Text Method")
                                            .font(.caption)
                                            .fontWeight(.medium)
                                            .foregroundColor(.secondary)

                                        Picker("Alt Text Method", selection: Binding(
                                            get: {
                                                if useExternalAPI {
                                                    return 1 // LLM Generated
                                                } else if altTextTemplate == .objects {
                                                    return 2 // Fixed Alt Text
                                                } else {
                                                    return 0 // Apple Vision Generated
                                                }
                                            },
                                            set: { newValue in
                                                switch newValue {
                                                case 0: // Apple Vision Generated
                                                    useExternalAPI = false
                                                    altTextTemplate = .imageOf
                                                case 1: // LLM Generated
                                                    useExternalAPI = true
                                                case 2: // Fixed Alt Text
                                                    useExternalAPI = false
                                                    altTextTemplate = .objects
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
                                    if useExternalAPI {
                                        // LLM Generated Settings
                                        VStack(alignment: .leading, spacing: 12) {
                                            VStack(alignment: .leading, spacing: 8) {
                                                Text("LLM Provider")
                                                    .font(.caption)
                                                    .fontWeight(.medium)

                                                Picker("LLM Provider", selection: $llmProvider) {
                                                    ForEach(LLMProvider.allCases, id: \.self) { provider in
                                                        Text(provider.displayName).tag(provider)
                                                    }
                                                }
                                                .pickerStyle(MenuPickerStyle())
                                            }

                                            VStack(alignment: .leading, spacing: 8) {
                                                Text("API Key")
                                                    .font(.caption)
                                                    .fontWeight(.medium)

                                                SecureField("Enter API key", text: $apiKey)
                                                    .textFieldStyle(RoundedBorderTextFieldStyle())
                                            }

                                            VStack(alignment: .leading, spacing: 8) {
                                                Text("Custom Prompt (Optional)")
                                                    .font(.caption)
                                                    .fontWeight(.medium)

                                                ZStack(alignment: .topLeading) {
                                                    TextEditor(text: $customPrompt)
                                                        .frame(minHeight: 80)
                                                        .padding(8)
                                                        .overlay(
                                                            RoundedRectangle(cornerRadius: 8)
                                                                .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                                                        )

                                                    if customPrompt.isEmpty {
                                                        Text("Leave empty to use default: \(ImageAnalyzer.defaultPrompt)")
                                                            .font(.body)
                                                            .foregroundColor(.gray)
                                                            .padding(.horizontal, 12)
                                                            .padding(.vertical, 16)
                                                            .allowsHitTesting(false)
                                                    }
                                                }
                                            }
                                        }
                                    } else if altTextTemplate == .objects {
                                        // Fixed Alt Text - only user input
                                        VStack(alignment: .leading, spacing: 8) {
                                            Text("Fixed Alt Text")
                                                .font(.caption)
                                                .fontWeight(.medium)

                                            TextField("Enter fixed alt text", text: $fixedAltText)
                                                .textFieldStyle(RoundedBorderTextFieldStyle())

                                            Text("This text will be used for all images")
                                                .font(.caption2)
                                                .foregroundColor(.secondary)
                                        }
                                    } else {
                                        // Apple Vision Generated
                                        VStack(alignment: .leading, spacing: 8) {
                                            Text("Apple Vision Generated")
                                                .font(.caption)
                                                .fontWeight(.medium)

                                            Picker("Template", selection: $altTextTemplate) {
                                                ForEach(AltTextTemplate.allCases.filter { $0 != .objects }, id: \.self) { template in
                                                    Text(template.displayName).tag(template)
                                                }
                                            }
                                            .pickerStyle(MenuPickerStyle())

                                            Text("Uses Apple Vision to detect objects and text in images")
                                                .font(.caption2)
                                                .foregroundColor(.secondary)
                                        }
                                    }
                                }
                            }
                        }
                    }
                } header: {
                    Text("Image Handling")
                } footer: {
                    Text("Configure how images in your clipboard are processed and where they are saved")
                }

                // Section 3: Front Matter
                Section {
                    // Front Matter toggle
                    HStack {
                        Text("Enable Front Matter")
                            .font(.subheadline)
                            .fontWeight(.medium)

                        Spacer()

                        Toggle("", isOn: $enableFrontMatter)
                    }
                    .padding(.vertical, 4)

                    if enableFrontMatter {
                        if frontMatterFields.isEmpty {
                            VStack(alignment: .leading, spacing: 12) {
                                Text("No front matter fields configured")
                                    .foregroundColor(.secondary)
                                    .padding(.vertical, 8)

                                Button {
                                    // Add a default field to get started
                                    let defaultField = FrontMatterField(name: "title", type: .string, value: "")
                                    frontMatterFields.append(defaultField)
                                } label: {
                                    HStack {
                                        Image(systemName: "plus.circle.fill")
                                        Text("Add Front Matter Field")
                                    }
                                    .foregroundColor(.blue)
                                }
                            }
                        } else {
                            if isEditingFields {
                                // Edit mode: Show list with reordering and delete
                                ForEach(Array(frontMatterFields.enumerated()), id: \.element.id) { index, field in
                                    HStack {
                                        Image(systemName: "line.3.horizontal")
                                            .foregroundColor(.gray)
                                            .padding(.trailing, 8)

                                        VStack(alignment: .leading, spacing: 2) {
                                            Text(field.name.isEmpty ? "Unnamed Field" : field.name)
                                                .font(.subheadline)
                                                .fontWeight(.medium)

                                            Text(field.type.displayName)
                                                .font(.caption)
                                                .foregroundColor(.secondary)

                                            if !field.value.isEmpty {
                                                Text(field.value.prefix(30) + (field.value.count > 30 ? "..." : ""))
                                                    .font(.caption2)
                                                    .foregroundColor(.blue)
                                            }
                                        }

                                        Spacer()

                                        Button {
                                            frontMatterFields.remove(at: index)
                                        } label: {
                                            Image(systemName: "minus.circle.fill")
                                                .foregroundColor(.red)
                                        }
                                    }
                                    .padding(.vertical, 4)
                                }
                                .onMove(perform: moveFields)
                                .onDelete(perform: deleteFields)
                            } else {
                                // View mode: Show full editing interface
                                ForEach(Array(frontMatterFields.enumerated()), id: \.element.id) { index, _ in
                                    VStack(alignment: .leading, spacing: 8) {
                                        SmartFrontMatterFieldView(
                                            field: $frontMatterFields[index],
                                            settings: settings,
                                            onUpdate: {
                                                // Update triggered when field changes
                                            }
                                        )
                                    }
                                    .padding(.vertical, 8)
                                }
                            }
                        }

                        if !isEditingFields {
                            // Add new field section (only show when not in edit mode)
                            VStack(alignment: .leading, spacing: 8) {
                                Divider()

                                Text("Add New Field")
                                    .font(.subheadline)
                                    .fontWeight(.medium)

                                SmartAddNewFieldView(settings: settings) { newField in
                                    frontMatterFields.append(newField)
                                }
                            }
                            .padding(.vertical, 8)
                        }
                    }
                } header: {
                    HStack {
                        Text("Front Matter")

                        Spacer()

                        if enableFrontMatter && !frontMatterFields.isEmpty {
                            Button(isEditingFields ? "Done" : "Edit") {
                                isEditingFields.toggle()
                            }
                            .font(.caption)
                            .foregroundColor(.blue)
                        }
                    }
                } footer: {
                    if enableFrontMatter {
                        if isEditingFields {
                            Text("Tap and drag to reorder fields, or tap the minus button to remove them")
                        } else {
                            Text("Configure YAML front matter fields that will be added to your Markdown output")
                        }
                    } else {
                        Text("Front matter is disabled. Toggle on to add YAML metadata to your files")
                    }
                }
            }
            .navigationTitle(isEditing ? "Edit Template" : "New Template")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        isPresented = false
                    }
                }

                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(isEditing ? "Update" : "Save") {
                        saveTemplate()
                    }
                    .disabled(!canSave())
                }
            }
            .onAppear {
                loadTemplateData()
            }
        }
        .alert("Error", isPresented: $showingAlert) {
            Button("OK") { }
        } message: {
            Text(alertMessage)
        }
    }

    private func loadTemplateData() {
        if let template = template {
            templateName = template.name
            outputFilenameFormat = template.outputFilenameFormat
            imageHandling = template.imageHandling
            imageFolderPath = template.imageFolderPath
            enableAutoAlt = template.enableAutoAlt
            altTextTemplate = template.altTextTemplate
            useExternalAPI = template.useExternalAPI
            apiKey = template.apiKey
            llmProvider = template.llmProvider
            customPrompt = template.customPrompt
            fixedAltText = template.fixedAltText
            frontMatterFields = template.frontMatterFields
            enableFrontMatter = template.enableFrontMatter
        } else {
            templateName = ""
            outputFilenameFormat = settings.outputFilenameFormat
            imageHandling = settings.imageHandling
            imageFolderPath = settings.imageFolderPath
            enableAutoAlt = settings.enableAutoAlt
            altTextTemplate = settings.altTextTemplate
            useExternalAPI = settings.useExternalAPI
            apiKey = settings.apiKey
            llmProvider = settings.llmProvider
            customPrompt = settings.customPrompt
            fixedAltText = settings.fixedAltText
            frontMatterFields = settings.frontMatterFields
            enableFrontMatter = settings.enableFrontMatter
        }
    }

    private func canSave() -> Bool {
        if !isEditing && templateName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            return false
        }
        return isValidOutputFilename() && isValidImagePath()
    }

    private func saveTemplate() {
        let trimmedName = templateName.trimmingCharacters(in: .whitespacesAndNewlines)

        if !isEditing {
            if trimmedName.isEmpty {
                alertMessage = "Please enter a template name"
                showingAlert = true
                return
            }

            if !settings.isTemplateNameValid(trimmedName) {
                alertMessage = "Template name already exists"
                showingAlert = true
                return
            }
        }

        // Create or update template with current form values
        if isEditing, let existingTemplate = template {
            var updatedTemplate = existingTemplate

            // Update name if it's not the default template and name has changed
            if existingTemplate.name != "default" && trimmedName != existingTemplate.name {
                if !settings.isTemplateNameValid(trimmedName) {
                    alertMessage = "Template name already exists"
                    showingAlert = true
                    return
                }
                updatedTemplate.name = trimmedName
            }

            updatedTemplate.outputFilenameFormat = outputFilenameFormat
            updatedTemplate.imageHandling = imageHandling
            updatedTemplate.imageFolderPath = imageFolderPath
            updatedTemplate.enableAutoAlt = enableAutoAlt
            updatedTemplate.altTextTemplate = altTextTemplate
            updatedTemplate.useExternalAPI = useExternalAPI
            updatedTemplate.apiKey = apiKey
            updatedTemplate.llmProvider = llmProvider
            updatedTemplate.customPrompt = customPrompt
            updatedTemplate.fixedAltText = fixedAltText
            updatedTemplate.frontMatterFields = frontMatterFields
            updatedTemplate.enableFrontMatter = enableFrontMatter

            if let index = settings.templates.firstIndex(where: { $0.id == existingTemplate.id }) {
                settings.templates[index] = updatedTemplate
                // Apply the updated template to current settings if it's the active template
                if settings.currentTemplateID == existingTemplate.id {
                    settings.applyTemplate(updatedTemplate)
                } else {
                    settings.saveSettings()
                }
                isPresented = false
            }
        } else {
            // Create new template
            var newTemplate = Template(name: trimmedName, settingsStore: settings)
            newTemplate.outputFilenameFormat = outputFilenameFormat
            newTemplate.imageHandling = imageHandling
            newTemplate.imageFolderPath = imageFolderPath
            newTemplate.enableAutoAlt = enableAutoAlt
            newTemplate.altTextTemplate = altTextTemplate
            newTemplate.useExternalAPI = useExternalAPI
            newTemplate.apiKey = apiKey
            newTemplate.llmProvider = llmProvider
            newTemplate.customPrompt = customPrompt
            newTemplate.fixedAltText = fixedAltText
            newTemplate.frontMatterFields = frontMatterFields
            newTemplate.enableFrontMatter = enableFrontMatter

            settings.templates.append(newTemplate)
            // Automatically apply the new template as the current template
            settings.applyTemplate(newTemplate)
            isPresented = false
        }
    }


    private func isValidOutputFilename() -> Bool {
        let filename = outputFilenameFormat.trimmingCharacters(in: .whitespacesAndNewlines)

        if filename.isEmpty {
            return false
        }

        let invalidChars = CharacterSet(charactersIn: "<>:\"/|?*")
        if filename.rangeOfCharacter(from: invalidChars) != nil {
            return false
        }

        return true
    }

    private func isValidImagePath() -> Bool {
        if imageHandling != .saveToFolder {
            return true
        }

        let path = imageFolderPath.trimmingCharacters(in: .whitespacesAndNewlines)

        if path.isEmpty {
            return true
        }

        if path.contains("\0") || path.contains("NULL") {
            return false
        }

        let invalidChars = CharacterSet(charactersIn: ":\"|?*")
        if path.rangeOfCharacter(from: invalidChars) != nil {
            return false
        }

        return true
    }

    private func generateFilenamePreview() -> String {
        // Create a temporary settings store with the current values to use existing filename processing logic
        let tempSettings = SettingsStore()
        tempSettings.outputFilenameFormat = outputFilenameFormat
        tempSettings.frontMatterFields = frontMatterFields

        return tempSettings.generateFinalOutputFilename(contentPreview: "example preview")
    }

    private func generateImagePathPreview() -> String {
        // Create a temporary settings store with the current values to use existing path processing logic
        let tempSettings = SettingsStore()
        tempSettings.imageFolderPath = imageFolderPath

        let processedPath = tempSettings.processImageFolderPath(imageIndex: 1, contentPreview: "example-preview", fileExtension: "png")

        return "![\(enableAutoAlt ? altTextTemplate.displayName : "alt")](\(processedPath))"
    }

    private func generateImageHandlingPreview() -> String {
        switch imageHandling {
        case .ignore:
            return "<!-- Image ignored -->"
        case .base64:
            return "![alt text](data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAAA...)"
        case .saveToFolder:
            return "![alt](/path/to/image.png)"
        }
    }

    private func moveFields(from source: IndexSet, to destination: Int) {
        frontMatterFields.move(fromOffsets: source, toOffset: destination)
    }

    private func deleteFields(offsets: IndexSet) {
        frontMatterFields.remove(atOffsets: offsets)
    }
}