//
//  SmartFrontMatterFieldView.swift
//  pastedown-v1
//
//  Created by Claude Code on 2025/9/2.
//

import SwiftUI

// MARK: - Smart Front Matter Field View
struct SmartFrontMatterFieldView: View {
    @Binding var field: FrontMatterField
    let settings: SettingsStore
    let onUpdate: () -> Void
    
    @State private var dateValue = Date()
    @State private var boolValue = false
    @State private var numberText = ""
    @State private var tagItems: [String] = []
    @State private var listItems: [String] = []
    @State private var tagText = ""
    @State private var newListText = ""
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                TextField("Field name", text: $field.name)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
                    .onChange(of: field.name) { _, _ in onUpdate() }
                
                Picker("Type", selection: $field.type) {
                    ForEach(FrontMatterType.allCases, id: \.self) { type in
                        Text(type.displayName).tag(type)
                    }
                }
                .pickerStyle(MenuPickerStyle())
                .onChange(of: field.type) { oldValue, newValue in
                    // Only reset value when type actually changes to avoid clearing existing data
                    guard oldValue != newValue else { return }
                    
                    // Reset value when type changes
                    switch newValue {
                    case .boolean:
                        field.value = "false"
                        boolValue = false
                    case .number:
                        field.value = "0"
                        numberText = "0"
                    case .date:
                        let formatter = DateFormatter()
                        formatter.dateFormat = "yyyy-MM-dd"
                        field.value = formatter.string(from: Date())
                        dateValue = Date()
                    case .datetime:
                        let formatter = DateFormatter()
                        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss"
                        field.value = formatter.string(from: Date())
                        dateValue = Date()
                    case .current_date, .current_datetime:
                        field.value = "" // No user input needed
                    case .tag:
                        tagItems = []
                        tagText = ""
                        field.value = "[]"
                    case .list:
                        listItems = []
                        field.value = "[]"
                    default:
                        field.value = ""
                    }
                    onUpdate()
                }
            }
            
            // Conditional value input based on type
            if field.type.needsUserInput {
                switch field.type {
                case .boolean:
                    HStack {
                        Text("Value:")
                        Toggle("", isOn: $boolValue)
                            .onChange(of: boolValue) { _, newValue in
                                field.value = newValue ? "true" : "false"
                                onUpdate()
                            }
                        Text(boolValue ? "True" : "False")
                            .foregroundColor(Color.secondary)
                        Spacer()
                    }
                    
                case .number:
                    HStack {
                        Text("Value:")
                        TextField("Enter number", text: $numberText)
                            .keyboardType(.numberPad)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .overlay(
                                RoundedRectangle(cornerRadius: 8)
                                    .stroke(isValidNumber(numberText) ? Color.clear : Color.red, lineWidth: 1)
                            )
                            .onChange(of: numberText) { _, newValue in
                                if isValidNumber(newValue) {
                                    field.value = newValue
                                    onUpdate()
                                }
                            }
                    }
                    if !isValidNumber(numberText) && !numberText.isEmpty {
                        Text("Please enter a valid number")
                            .font(.caption)
                            .foregroundColor(Color.red)
                    }
                    
                case .date:
                    HStack {
                        Text("Value:")
                        DatePicker("", selection: $dateValue, displayedComponents: .date)
                            .onChange(of: dateValue) { _, newValue in
                                let formatter = DateFormatter()
                                formatter.dateFormat = "yyyy-MM-dd"
                                field.value = formatter.string(from: newValue)
                                onUpdate()
                            }
                    }
                    
                case .datetime:
                    HStack {
                        Text("Value:")
                        DatePicker("", selection: $dateValue, displayedComponents: [.date, .hourAndMinute])
                            .onChange(of: dateValue) { _, newValue in
                                let formatter = DateFormatter()
                                formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss"
                                field.value = formatter.string(from: newValue)
                                onUpdate()
                            }
                    }
                    
                case .tag:
                    VStack(alignment: .leading, spacing: 8) {
                        VStack(alignment: .leading, spacing: 4) {
                            TextField("Tags (separate with commas: tag1, tag2, tag3)", text: $tagText)
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                                .onChange(of: tagText) { _, newValue in
                                    // Parse comma-separated tags and update field value
                                    let tags = newValue.components(separatedBy: ",")
                                        .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
                                        .filter { !$0.isEmpty }
                                    
                                    if let jsonData = try? JSONEncoder().encode(tags),
                                       let jsonString = String(data: jsonData, encoding: .utf8) {
                                        field.value = jsonString
                                        tagItems = tags
                                        onUpdate()
                                    }
                                }
                            
                            Text("Use commas to separate tags: tag1, tag2, tag3")
                                .font(.caption)
                                .foregroundColor(Color.secondary)
                        }
                        
                        // Preview
                        if !tagItems.isEmpty {
                            Text("Preview:")
                                .font(.caption)
                                .fontWeight(.medium)
                                .foregroundColor(Color.secondary)
                            
                            Text(generateTagPreview())
                                .font(.caption.monospaced())
                                .foregroundColor(Color.blue)
                                .padding(8)
                                .background(Color.blue.opacity(0.1))
                                .cornerRadius(4)
                        }
                    }
                    
                case .list:
                    VStack(alignment: .leading, spacing: 8) {
                        Text("List Items:")
                            .font(.subheadline)
                            .fontWeight(.medium)
                        
                        // Display existing list items
                        if !listItems.isEmpty {
                            ForEach(listItems.indices, id: \.self) { index in
                                HStack {
                                    Text("•")
                                        .foregroundColor(Color.blue)
                                    Text(listItems[index])
                                        .font(.body)
                                    
                                    Spacer()
                                    
                                    Button(action: {
                                        listItems.remove(at: index)
                                        updateListValue()
                                    }) {
                                        Image(systemName: "trash")
                                            .foregroundColor(Color.red)
                                            .font(.caption)
                                    }
                                }
                                .padding(.vertical, 2)
                            }
                        }
                        
                        // Add new list item
                        HStack {
                            TextField("Add list item", text: $newListText)
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                            
                            Button("Add") {
                                if !newListText.isEmpty {
                                    listItems.append(newListText)
                                    newListText = ""
                                    updateListValue()
                                }
                            }
                            .disabled(newListText.isEmpty)
                        }
                        
                        // Preview
                        if !listItems.isEmpty {
                            Text("Preview:")
                                .font(.caption)
                                .fontWeight(.medium)
                                .foregroundColor(Color.secondary)
                            
                            Text(generateListPreview())
                                .font(.caption.monospaced())
                                .foregroundColor(Color.blue)
                                .padding(8)
                                .background(Color.blue.opacity(0.1))
                                .cornerRadius(4)
                        }
                    }
                    
                case .multiline:
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text("Value:")
                                .font(.subheadline)
                                .fontWeight(.medium)
                            
                            Spacer()
                            
                            SimpleVariablePickerButton(text: $field.value, context: .frontMatter, settings: settings, excludeFieldName: field.name)
                        }
                        
                        TextEditor(text: $field.value)
                            .frame(minHeight: 100)
                            .padding(8)
                            .overlay(
                                RoundedRectangle(cornerRadius: 8)
                                    .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                            )
                            .onChange(of: field.value) { _, _ in onUpdate() }
                        
                        Text("Supports multiple lines of text")
                            .font(.caption)
                            .foregroundColor(Color.secondary)
                        
                        // Preview
                        if !field.value.isEmpty {
                            Text("Preview:")
                                .font(.caption)
                                .fontWeight(.medium)
                                .foregroundColor(Color.secondary)
                            
                            Text(generateMultilinePreview())
                                .font(.caption.monospaced())
                                .foregroundColor(Color.blue)
                                .padding(8)
                                .background(Color.blue.opacity(0.1))
                                .cornerRadius(4)
                        }
                    }
                    
                default:
                    // String - use the enhanced text field with variables
                    TextFieldWithVariablePicker(title: "Value", text: $field.value, context: .frontMatter, settings: settings, excludeFieldName: field.name)
                        .onChange(of: field.value) { _, _ in onUpdate() }
                }
            } else {
                // For current_date and current_datetime, show info text
                Text("Automatically generated at processing time")
                    .font(.caption)
                    .foregroundColor(Color.secondary)
                    .italic()
            }
        }
        .onAppear {
            // Initialize state values based on field type and value
            switch field.type {
            case .boolean:
                boolValue = field.value.lowercased() == "true"
            case .number:
                numberText = field.value
            case .date, .datetime:
                if let date = parseDate(field.value, type: field.type) {
                    dateValue = date
                }
            case .tag:
                tagItems = parseTagsFromValue(field.value)
                tagText = tagItems.joined(separator: ", ")
            case .list:
                listItems = parseListFromValue(field.value)
            default:
                break
            }
        }
    }
    
    private func isValidNumber(_ text: String) -> Bool {
        return Double(text) != nil
    }
    
    private func parseDate(_ dateString: String, type: FrontMatterType) -> Date? {
        let formatter = DateFormatter()
        switch type {
        case .date:
            formatter.dateFormat = "yyyy-MM-dd"
        case .datetime:
            formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss"
        default:
            return nil
        }
        return formatter.date(from: dateString)
    }
    
    // MARK: - Tag Helper Functions
    private func updateTagValue() {
        // Store tags as JSON array for internal storage
        if let jsonData = try? JSONEncoder().encode(tagItems),
           let jsonString = String(data: jsonData, encoding: .utf8) {
            field.value = jsonString
            onUpdate()
        }
    }
    
    private func parseTagsFromValue(_ value: String) -> [String] {
        // Try to parse as JSON array first
        if let jsonData = value.data(using: .utf8),
           let tags = try? JSONDecoder().decode([String].self, from: jsonData) {
            return tags
        }
        
        // If not JSON, treat as comma-separated values
        if !value.isEmpty {
            return value.components(separatedBy: ",").map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }.filter { !$0.isEmpty }
        }
        
        return []
    }
    
    private func generateTagPreview() -> String {
        guard !tagItems.isEmpty else { return "" }
        
        var preview = "\(field.name):\n"
        for tag in tagItems {
            preview += "    - \"\(tag)\"\n"
        }
        return preview.trimmingCharacters(in: .newlines)
    }
    
    // MARK: - List Helper Functions
    private func updateListValue() {
        // Store list as JSON array for internal storage
        if let jsonData = try? JSONEncoder().encode(listItems),
           let jsonString = String(data: jsonData, encoding: .utf8) {
            field.value = jsonString
            onUpdate()
        }
    }
    
    private func parseListFromValue(_ value: String) -> [String] {
        // Try to parse as JSON array first
        if let jsonData = value.data(using: .utf8),
           let items = try? JSONDecoder().decode([String].self, from: jsonData) {
            return items
        }
        
        // If not JSON, treat as comma-separated values
        if !value.isEmpty {
            return value.components(separatedBy: ",").map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }.filter { !$0.isEmpty }
        }
        
        return []
    }
    
    private func generateListPreview() -> String {
        guard !listItems.isEmpty else { return "" }
        
        let quotedItems = listItems.map { "\"\($0)\"" }
        return "\(field.name): [\(quotedItems.joined(separator: ", "))]"
    }
    
    // MARK: - Multiline Helper Functions
    private func generateMultilinePreview() -> String {
        guard !field.value.isEmpty else { return "" }
        
        var preview = "\(field.name): >-\n"
        let lines = field.value.components(separatedBy: .newlines)
        for line in lines {
            preview += "  \(line)\n"
        }
        return preview.trimmingCharacters(in: .newlines)
    }
}

// MARK: - Smart Add New Field Component
struct SmartAddNewFieldView: View {
    let settings: SettingsStore
    
    @State private var newFieldName = ""
    @State private var newFieldType = FrontMatterType.string
    @State private var newFieldValue = ""
    @State private var newDateValue = Date()
    @State private var newBoolValue = false
    @State private var newNumberText = ""
    @State private var newTagItems: [String] = []
    @State private var newListItems: [String] = []
    @State private var newTagText = ""
    @State private var addListText = ""
    
    let onAddField: (FrontMatterField) -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                TextField("Field name", text: $newFieldName)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
                
                Picker("Type", selection: $newFieldType) {
                    ForEach(FrontMatterType.allCases, id: \.self) { type in
                        Text(type.displayName).tag(type)
                    }
                }
                .pickerStyle(MenuPickerStyle())
                .onChange(of: newFieldType) { oldValue, newValue in
                    // Reset value when type changes (this is for new fields, so always reset)
                    switch newValue {
                    case .boolean:
                        newFieldValue = "false"
                        newBoolValue = false
                    case .number:
                        newFieldValue = "0"
                        newNumberText = "0"
                    case .date:
                        let formatter = DateFormatter()
                        formatter.dateFormat = "yyyy-MM-dd"
                        newFieldValue = formatter.string(from: Date())
                        newDateValue = Date()
                    case .datetime:
                        let formatter = DateFormatter()
                        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss"
                        newFieldValue = formatter.string(from: Date())
                        newDateValue = Date()
                    case .current_date, .current_datetime:
                        newFieldValue = ""
                    case .tag:
                        newTagItems = []
                        newTagText = ""
                        newFieldValue = "[]"
                    case .list:
                        newListItems = []
                        newFieldValue = "[]"
                    default:
                        newFieldValue = ""
                    }
                }
            }
            
            // Conditional value input based on type
            if newFieldType.needsUserInput {
                switch newFieldType {
                case .boolean:
                    HStack {
                        Text("Value:")
                        Toggle("", isOn: $newBoolValue)
                            .onChange(of: newBoolValue) { _, newValue in
                                newFieldValue = newValue ? "true" : "false"
                            }
                        Text(newBoolValue ? "True" : "False")
                            .foregroundColor(Color.secondary)
                        Spacer()
                    }
                    
                case .number:
                    HStack {
                        Text("Value:")
                        TextField("Enter number", text: $newNumberText)
                            .keyboardType(.numberPad)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .overlay(
                                RoundedRectangle(cornerRadius: 8)
                                    .stroke(isValidNumber(newNumberText) ? Color.clear : Color.red, lineWidth: 1)
                            )
                            .onChange(of: newNumberText) { _, newValue in
                                if isValidNumber(newValue) {
                                    newFieldValue = newValue
                                }
                            }
                    }
                    if !isValidNumber(newNumberText) && !newNumberText.isEmpty {
                        Text("Please enter a valid number")
                            .font(.caption)
                            .foregroundColor(Color.red)
                    }
                    
                case .date:
                    HStack {
                        Text("Value:")
                        DatePicker("", selection: $newDateValue, displayedComponents: .date)
                            .onChange(of: newDateValue) { _, newValue in
                                let formatter = DateFormatter()
                                formatter.dateFormat = "yyyy-MM-dd"
                                newFieldValue = formatter.string(from: newValue)
                            }
                    }
                    
                case .datetime:
                    HStack {
                        Text("Value:")
                        DatePicker("", selection: $newDateValue, displayedComponents: [.date, .hourAndMinute])
                            .onChange(of: newDateValue) { _, newValue in
                                let formatter = DateFormatter()
                                formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss"
                                newFieldValue = formatter.string(from: newValue)
                            }
                    }
                    
                case .tag:
                    VStack(alignment: .leading, spacing: 6) {
                        VStack(alignment: .leading, spacing: 4) {
                            TextField("Tags (separate with commas: tag1, tag2, tag3)", text: $newTagText)
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                                .onChange(of: newTagText) { _, newValue in
                                    // Parse comma-separated tags and update field value
                                    let tags = newValue.components(separatedBy: ",")
                                        .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
                                        .filter { !$0.isEmpty }
                                    
                                    newTagItems = tags
                                    updateNewTagValue()
                                }
                            
                            Text("Use commas to separate tags: tag1, tag2, tag3")
                                .font(.caption)
                                .foregroundColor(Color.secondary)
                        }
                    }
                    
                case .list:
                    VStack(alignment: .leading, spacing: 6) {
                        Text("List Items:")
                            .font(.subheadline)
                            .fontWeight(.medium)
                        
                        // Display existing list items
                        if !newListItems.isEmpty {
                            ForEach(newListItems.indices, id: \.self) { index in
                                HStack {
                                    Text("•")
                                        .foregroundColor(Color.blue)
                                    Text(newListItems[index])
                                        .font(.caption)
                                    
                                    Spacer()
                                    
                                    Button(action: {
                                        newListItems.remove(at: index)
                                        updateNewListValue()
                                    }) {
                                        Image(systemName: "trash")
                                            .foregroundColor(Color.red)
                                            .font(.caption2)
                                    }
                                }
                                .padding(.vertical, 1)
                            }
                        }
                        
                        // Add new list item
                        HStack {
                            TextField("Add list item", text: $addListText)
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                            
                            Button("Add") {
                                if !addListText.isEmpty {
                                    newListItems.append(addListText)
                                    addListText = ""
                                    updateNewListValue()
                                }
                            }
                            .disabled(addListText.isEmpty)
                        }
                    }
                    
                case .multiline:
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text("Value:")
                                .font(.subheadline)
                                .fontWeight(.medium)
                            
                            Spacer()
                            
                            SimpleVariablePickerButton(text: $newFieldValue, context: .frontMatter, settings: settings, excludeFieldName: nil)
                        }
                        
                        TextEditor(text: $newFieldValue)
                            .frame(minHeight: 100)
                            .padding(8)
                            .overlay(
                                RoundedRectangle(cornerRadius: 8)
                                    .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                            )
                        
                        Text("Supports multiple lines of text")
                            .font(.caption)
                            .foregroundColor(Color.secondary)
                    }
                    .id("newField-multiline")
                    
                default:
                    HStack {
                        Text("Value:")
                        TextField("Enter value", text: $newFieldValue)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                    }
                    .id("newField-\(newFieldType.rawValue)")
                }
            } else {
                Text("Automatically generated at processing time")
                    .font(.caption)
                    .foregroundColor(Color.secondary)
                    .italic()
            }
            
            Button("Add Field") {
                let newField = FrontMatterField(name: newFieldName, type: newFieldType, value: newFieldValue)
                onAddField(newField)
                
                // Reset form with a small delay to avoid UI conflicts
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    newFieldName = ""
                    newFieldType = .string
                    newFieldValue = ""
                    newDateValue = Date()
                    newBoolValue = false
                    newNumberText = ""
                    newTagItems = []
                    newListItems = []
                    newTagText = ""
                    addListText = ""
                }
            }
            .disabled(newFieldName.isEmpty || (newFieldType.needsUserInput && !isValidFieldValue()))
        }
    }
    
    private func isValidNumber(_ text: String) -> Bool {
        return Double(text) != nil
    }
    
    private func isValidFieldValue() -> Bool {
        switch newFieldType {
        case .number:
            return isValidNumber(newNumberText)
        case .current_date, .current_datetime:
            return true // No validation needed
        case .tag:
            return !newTagItems.isEmpty
        case .list:
            return !newListItems.isEmpty
        default:
            return !newFieldValue.isEmpty
        }
    }
    
    // MARK: - New Field Tag/List Helper Functions
    private func updateNewTagValue() {
        if let jsonData = try? JSONEncoder().encode(newTagItems),
           let jsonString = String(data: jsonData, encoding: .utf8) {
            newFieldValue = jsonString
        }
    }
    
    private func updateNewListValue() {
        if let jsonData = try? JSONEncoder().encode(newListItems),
           let jsonString = String(data: jsonData, encoding: .utf8) {
            newFieldValue = jsonString
        }
    }
}


// 添加到 SmartFrontMatterFieldView.swift 檔案末尾

#Preview("String Field") {
    @State var field = FrontMatterField(name: "publish", type: .string, value: "Sample Title")
    @StateObject var settings = SettingsStore()
    
    NavigationView {
        Form {
            SmartFrontMatterFieldView(
                field: $field,
                settings: settings,
                onUpdate: {}
            )
        }
    }
}

