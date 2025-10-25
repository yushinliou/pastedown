//
//  VariablePickerView.swift
//  pastedown-v1
//
//  Modified by Yu Shin on 2025/10/25.
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
                            displayName: field.name, // no .capitalized
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
                                displayName: field.name, // no .capitalized
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
    @Binding var cursorPosition: Int
    let context: VariableCategory
    let settings: SettingsStore?
    let excludeFieldName: String?
    @State private var showingPicker = false

    init(text: Binding<String>, cursorPosition: Binding<Int>, context: VariableCategory, settings: SettingsStore?, excludeFieldName: String? = nil) {
        self._text = text
        self._cursorPosition = cursorPosition
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
                insertVariableAtCursor(variable)
            }, settings: settings, excludeFieldName: excludeFieldName, context: context)
        }
        .buttonStyle(.plain) // prevent button from expanding make the whole area clickable
    }
    

    private func insertVariableAtCursor(_ variable: String) {
        if text.isEmpty {
            text = variable
            cursorPosition = variable.count
        } else {
            let insertPosition = min(cursorPosition, text.count)
            let beforeCursor = String(text.prefix(insertPosition))
            let afterCursor = String(text.suffix(text.count - insertPosition))
            text = beforeCursor + variable + afterCursor
            cursorPosition = insertPosition + variable.count
        }
    }
}

// MARK: - Simple Variable Picker Button (for TextEditor)
struct SimpleVariablePickerButton: View {
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
                // Insert variable at the end of current text (fallback for TextEditor)
                if text.isEmpty {
                    text = variable
                } else {
                    text += variable
                }
            }, settings: settings, excludeFieldName: excludeFieldName, context: context)
        }
        .buttonStyle(.plain) // prevent button from expanding make the whole area clickable
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
    @State private var cursorPosition: Int = 0

    init(title: String, text: Binding<String>, context: VariableCategory, settings: SettingsStore?, excludeFieldName: String? = nil) {
        self.title = title
        self._text = text
        self.context = context
        self.settings = settings
        self.excludeFieldName = excludeFieldName
    }

    var body: some View {
        HStack {
            CursorTrackingTextField(
                placeholder: title,
                text: $text,
                cursorPosition: $cursorPosition,
                isEditing: $isEditing
            )
            .frame(maxWidth: .infinity)

            VariablePickerButton(
                text: $text,
                cursorPosition: $cursorPosition,
                context: context,
                settings: settings,
                excludeFieldName: excludeFieldName
            )
        }
        .padding(8)
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(isEditing ? Color.blue : Color.gray.opacity(0.3), lineWidth: 1)
        )
    }
}

// MARK: - Cursor Tracking Text Editor
struct CursorTrackingTextEditor: UIViewRepresentable {
    @Binding var text: String
    @Binding var cursorPosition: Int
    let minHeight: CGFloat

    init(text: Binding<String>, cursorPosition: Binding<Int>, minHeight: CGFloat = 80) {
        self._text = text
        self._cursorPosition = cursorPosition
        self.minHeight = minHeight
    }

    func makeUIView(context: Context) -> UITextView {
        let textView = UITextView()
        textView.delegate = context.coordinator
        textView.font = UIFont.systemFont(ofSize: 17)
        textView.backgroundColor = UIColor.clear
        textView.textContainerInset = UIEdgeInsets(top: 8, left: 8, bottom: 8, right: 8)
        return textView
    }

    func updateUIView(_ uiView: UITextView, context: Context) {
        if uiView.text != text {
            uiView.text = text
            // Update cursor position after text change
            DispatchQueue.main.async {
                let newPosition = min(cursorPosition, uiView.text.count)
                if let newRange = uiView.position(from: uiView.beginningOfDocument, offset: newPosition) {
                    uiView.selectedTextRange = uiView.textRange(from: newRange, to: newRange)
                }
            }
        }
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    class Coordinator: NSObject, UITextViewDelegate {
        let parent: CursorTrackingTextEditor

        init(_ parent: CursorTrackingTextEditor) {
            self.parent = parent
        }

        func textViewDidChange(_ textView: UITextView) {
            parent.text = textView.text
            updateCursorPosition(textView)
        }

        func textViewDidChangeSelection(_ textView: UITextView) {
            updateCursorPosition(textView)
        }

        private func updateCursorPosition(_ textView: UITextView) {
            let cursorPosition = textView.offset(from: textView.beginningOfDocument, to: textView.selectedTextRange?.start ?? textView.beginningOfDocument)
            parent.cursorPosition = cursorPosition
        }
    }
}

// MARK: - Text Editor with Variable Picker
struct TextEditorWithVariablePicker: View {
    @Binding var text: String
    let context: VariableCategory
    let settings: SettingsStore?
    let excludeFieldName: String?
    let minHeight: CGFloat
    @State private var cursorPosition: Int = 0

    init(text: Binding<String>, context: VariableCategory, settings: SettingsStore?, excludeFieldName: String? = nil, minHeight: CGFloat = 80) {
        self._text = text
        self.context = context
        self.settings = settings
        self.excludeFieldName = excludeFieldName
        self.minHeight = minHeight
    }

    var body: some View {
        HStack(alignment: .top, spacing: 8) {
            CursorTrackingTextEditor(
                text: $text,
                cursorPosition: $cursorPosition,
                minHeight: minHeight
            )
            .frame(minHeight: minHeight)

            VariablePickerButton(
                text: $text,
                cursorPosition: $cursorPosition,
                context: context,
                settings: settings,
                excludeFieldName: excludeFieldName
            )
            .padding(.top, 4)
        }
    }
}

// MARK: - Cursor Tracking Text Field
struct CursorTrackingTextField: UIViewRepresentable {
    let placeholder: String
    @Binding var text: String
    @Binding var cursorPosition: Int
    @Binding var isEditing: Bool

    func makeUIView(context: Context) -> UITextField {
        let textField = UITextField()
        textField.placeholder = placeholder
        textField.delegate = context.coordinator
        textField.addTarget(context.coordinator, action: #selector(Coordinator.textFieldChanged), for: .editingChanged)
        textField.addTarget(context.coordinator, action: #selector(Coordinator.textFieldEditingEnded), for: .editingDidEnd)

        textField.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)

        textField.autocapitalizationType = .none 
        textField.autocorrectionType = .no 

        return textField
    }

    func updateUIView(_ uiView: UITextField, context: Context) {
        if uiView.text != text {
            uiView.text = text
            // Update cursor position after text change
            DispatchQueue.main.async {
                if let newPosition = uiView.position(from: uiView.beginningOfDocument, offset: min(cursorPosition, uiView.text?.count ?? 0)) {
                    uiView.selectedTextRange = uiView.textRange(from: newPosition, to: newPosition)
                }
            }
        }
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    class Coordinator: NSObject, UITextFieldDelegate {
        let parent: CursorTrackingTextField

        init(_ parent: CursorTrackingTextField) {
            self.parent = parent
        }

        @objc func textFieldChanged(_ textField: UITextField) {
            parent.text = textField.text ?? ""
            updateCursorPosition(textField)
        }

        @objc func textFieldEditingEnded(_ textField: UITextField) {
            parent.isEditing = false
        }

        func textFieldShouldReturn(_ textField: UITextField) -> Bool {
            textField.resignFirstResponder()
            return true
        }

        func textFieldDidBeginEditing(_ textField: UITextField) {
            parent.isEditing = true
            updateCursorPosition(textField)
        }

        func textFieldDidChangeSelection(_ textField: UITextField) {
            updateCursorPosition(textField)
        }

        private func updateCursorPosition(_ textField: UITextField) {
            if let selectedRange = textField.selectedTextRange {
                let cursorPosition = textField.offset(from: textField.beginningOfDocument, to: selectedRange.start)
                parent.cursorPosition = cursorPosition
            }
        }
    }
}