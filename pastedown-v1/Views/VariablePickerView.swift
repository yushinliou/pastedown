//
//  VariablePickerView.swift
//  pastedown-v1
//
//  Created by Claude Code on 2025/9/2.
//

import SwiftUI

// MARK: - Variable Definitions
struct TemplateVariable {
    let name: String
    let displayName: String
    let description: String
    let category: VariableCategory
}

enum VariableCategory: String, CaseIterable {
    case filename = "Filename"
    case frontMatter = "Front Matter"
    
    func variables(settings: SettingsStore? = nil, excludeFieldName: String? = nil) -> [TemplateVariable] {
        switch self {
        case .filename:
            var baseVariables = [
                TemplateVariable(name: "{clipboard_preview}", displayName: "Clipboard Preview", description: "First 20 chars of clipboard content", category: .filename),
                TemplateVariable(name: "{date}", displayName: "Current Date", description: "Current date (YYYY-MM-DD)", category: .filename),
                TemplateVariable(name: "{time}", displayName: "Current Time", description: "Current time (YYYY-MM-DD_HH-MM-SS)", category: .filename)
            ]
            
            // Add dynamic front matter fields for filename usage
            if let settings = settings {
                for field in settings.frontMatterFields {
                    baseVariables.append(
                        TemplateVariable(
                            name: "{\(field.name)}", 
                            displayName: field.name.capitalized, 
                            description: "From front matter field '\(field.name)'", 
                            category: .filename
                        )
                    )
                }
            }
            
            return baseVariables
            
        case .frontMatter:
            var baseVariables = [
                TemplateVariable(name: "{current_date}", displayName: "Current Date", description: "For Front Matter templates", category: .frontMatter),
                TemplateVariable(name: "{current_time}", displayName: "Current Time", description: "For Front Matter templates", category: .frontMatter)
            ]
            
            // Add dynamic front matter fields for cross-referencing, but exclude the current field
            if let settings = settings {
                for field in settings.frontMatterFields {
                    // Don't include the field we're currently editing to avoid self-reference
                    if field.name != excludeFieldName {
                        baseVariables.append(
                            TemplateVariable(
                                name: "{\(field.name)}", 
                                displayName: field.name.capitalized, 
                                description: "Reference to '\(field.name)' field", 
                                category: .frontMatter
                            )
                        )
                    }
                }
            }
            
            return baseVariables
        }
    }
    
    // Legacy method for backward compatibility
    var variables: [TemplateVariable] {
        return variables(settings: nil, excludeFieldName: nil)
    }
}

// MARK: - Variable Picker View
struct VariablePickerView: View {
    let onVariableSelected: (String) -> Void
    let settings: SettingsStore?
    let excludeFieldName: String?
    let context: VariableCategory?
    @Environment(\.presentationMode) var presentationMode
    
    init(onVariableSelected: @escaping (String) -> Void, settings: SettingsStore?, excludeFieldName: String? = nil, context: VariableCategory? = nil) {
        self.onVariableSelected = onVariableSelected
        self.settings = settings
        self.excludeFieldName = excludeFieldName
        self.context = context
    }
    
    var allVariables: [TemplateVariable] {
        VariableCategory.allCases.flatMap { $0.variables(settings: settings, excludeFieldName: excludeFieldName) }
    }
    
    var body: some View {
        NavigationView {
            List {
                if let context = context {
                    // Show only the specific context
                    Section(context.rawValue) {
                        ForEach(context.variables(settings: settings, excludeFieldName: excludeFieldName), id: \.name) { variable in
                            VariableRow(variable: variable) {
                                onVariableSelected(variable.name)
                                presentationMode.wrappedValue.dismiss()
                            }
                        }
                    }
                } else {
                    // Show all contexts (backward compatibility)
                    ForEach(VariableCategory.allCases, id: \.rawValue) { category in
                        Section(category.rawValue) {
                            ForEach(category.variables(settings: settings, excludeFieldName: excludeFieldName), id: \.name) { variable in
                                VariableRow(variable: variable) {
                                    onVariableSelected(variable.name)
                                    presentationMode.wrappedValue.dismiss()
                                }
                            }
                        }
                    }
                }
            }
            .navigationTitle("Insert Variable")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Cancel") {
                        presentationMode.wrappedValue.dismiss()
                    }
                }
            }
        }
    }
}

// MARK: - Variable Row
struct VariableRow: View {
    let variable: TemplateVariable
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(variable.displayName)
                        .font(.headline)
                        .foregroundColor(Color.primary)
                    Spacer()
                    Text(variable.name)
                        .font(.caption.monospaced())
                        .foregroundColor(Color.secondary)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 2)
                        .background(Color.gray.opacity(0.2))
                        .cornerRadius(4)
                }
                
                Text(variable.description)
                    .font(.caption)
                    .foregroundColor(Color.secondary)
            }
            .padding(.vertical, 2)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Variable Picker Button Component
struct VariablePickerButton: View {
    @Binding var text: String
    let context: VariableCategory
    let settings: SettingsStore?
    let excludeFieldName: String?
    @State private var showingPicker = false
    
    init(text: Binding<String>, context: VariableCategory, settings: SettingsStore?, excludeFieldName: String? = nil) {
        self._text = text
        self.context = context
        self.settings = settings
        self.excludeFieldName = excludeFieldName
    }
    
    var body: some View {
        Button(action: {
            showingPicker = true
        }) {
            Image(systemName: "tag")
                .foregroundColor(Color.accentColor)
        }
        .sheet(isPresented: $showingPicker) {
            VariablePickerView(onVariableSelected: { variable in
                // Insert variable at the end of current text
                if text.isEmpty {
                    text = variable
                } else {
                    text += variable
                }
            }, settings: settings, excludeFieldName: excludeFieldName, context: context)
        }
    }
}

// MARK: - Smart Text View with Variable Highlighting
struct SmartTextView: View {
    let text: String
    
    var body: some View {
        HStack(alignment: .center, spacing: 2) {
            ForEach(parseTextComponents(), id: \.id) { component in
                if component.isVariable {
                    Text(component.text)
                        .font(.caption.monospaced())
                        .foregroundColor(Color.white)
                        .padding(.horizontal, 4)
                        .padding(.vertical, 2)
                        .background(Color.blue)
                        .cornerRadius(3)
                } else {
                    Text(component.text)
                        .foregroundColor(Color.primary)
                }
            }
            Spacer()
        }
    }
    
    private func parseTextComponents() -> [TextComponent] {
        var components: [TextComponent] = []
        let pattern = "\\{[^}]+\\}"
        
        do {
            let regex = try NSRegularExpression(pattern: pattern, options: [])
            let matches = regex.matches(in: text, options: [], range: NSRange(location: 0, length: text.count))
            
            var lastEnd = 0
            
            for match in matches {
                // Add text before variable
                if match.range.location > lastEnd {
                    let beforeRange = NSRange(location: lastEnd, length: match.range.location - lastEnd)
                    if let beforeText = text.substring(with: beforeRange), !beforeText.isEmpty {
                        components.append(TextComponent(text: beforeText, isVariable: false))
                    }
                }
                
                // Add variable
                if let variableText = text.substring(with: match.range) {
                    components.append(TextComponent(text: variableText, isVariable: true))
                }
                
                lastEnd = match.range.location + match.range.length
            }
            
            // Add remaining text
            if lastEnd < text.count {
                let remainingRange = NSRange(location: lastEnd, length: text.count - lastEnd)
                if let remainingText = text.substring(with: remainingRange), !remainingText.isEmpty {
                    components.append(TextComponent(text: remainingText, isVariable: false))
                }
            }
            
        } catch {
            // If regex fails, just return the whole text as non-variable
            components.append(TextComponent(text: text, isVariable: false))
        }
        
        // If no variables found and text is not empty, add as regular text
        if components.isEmpty && !text.isEmpty {
            components.append(TextComponent(text: text, isVariable: false))
        }
        
        return components
    }
}

struct TextComponent {
    let id = UUID()
    let text: String
    let isVariable: Bool
}

extension String {
    func substring(with range: NSRange) -> String? {
        guard let stringRange = Range(range, in: self) else { return nil }
        return String(self[stringRange])
    }
}

// MARK: - Enhanced Text Field with Variable Picker
struct TextFieldWithVariablePicker: View {
    let title: String
    @Binding var text: String
    let context: VariableCategory
    let settings: SettingsStore?
    let excludeFieldName: String?
    @State private var isEditing = false
    
    init(title: String, text: Binding<String>, context: VariableCategory, settings: SettingsStore?, excludeFieldName: String? = nil) {
        self.title = title
        self._text = text
        self.context = context
        self.settings = settings
        self.excludeFieldName = excludeFieldName
    }
    
    var body: some View {
        HStack {
            VStack(alignment: .leading) {
                if isEditing {
                    TextField(title, text: $text)
                        .textFieldStyle(PlainTextFieldStyle())
                } else {
                    if text.isEmpty {
                        Text(title)
                            .foregroundColor(Color.gray)
                    } else {
                        SmartTextView(text: text)
                    }
                }
            }
            .contentShape(Rectangle()) // Make the entire area tappable
            .onTapGesture {
                isEditing = true
            }
            .onReceive(NotificationCenter.default.publisher(for: UIResponder.keyboardDidHideNotification)) { _ in
                isEditing = false
            }
            
            VariablePickerButton(text: $text, context: context, settings: settings, excludeFieldName: excludeFieldName)
        }
        .padding(8)
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(isEditing ? Color.blue : Color.gray.opacity(0.3), lineWidth: 1)
        )
    }
}