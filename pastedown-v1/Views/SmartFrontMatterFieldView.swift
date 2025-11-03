//
//  SmartFrontMatterFieldView.swift
//  pastedown-v1
//
//  Modified by Yu Shin on 2025/10/26.
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
        VStack(alignment: .leading, spacing: AppSpacing.xxs) {
            // Comment toggle and indentation indicator
            HStack {
                // Field name
                TextField("Field name", text: $field.name)
                    .font(.app.title1)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
                    .opacity(field.isCommented ? 0.5 : 1.0)

                // Field type picker
                Picker("Type", selection: $field.type) {
                    ForEach(FrontMatterType.allCases, id: \.self) { type in
                        Text(type.displayName).tag(type)
                    }
                }
                .pickerStyle(MenuPickerStyle())
                .tint(.theme.textPrimary)
                .disabled(field.isCommented)
                .opacity(field.isCommented ? 0.5 : 1.0)
                .onChange(of: field.type) { oldValue, newValue in
                    // Only reset value when type actually changes to avoid clearing existing data
                    guard oldValue != newValue else { return }

                    // Defer state modification to avoid "modifying state during view update" warning
                    Task { @MainActor in
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
                    }
                }                
            }

            if field.type.needsUserInput {
                FrontMatterFieldInputView(field: $field, settings: settings)
            } else {
                // For current_date and current_datetime, show info text
                Text("Automatically generated at processing time")
                    .font(.app.caption)
                    .foregroundColor(.theme.textSecondary)
                    .italic()
            }

            HStack {
                // Indentation indicator
                HStack(spacing: AppSpacing.xxs) {
                    Image(systemName: "arrow.right.to.line")
                        .font(.system(size: 12))
                        .foregroundColor(.theme.textSecondary)

                    ForEach(0..<3, id: \.self) { level in
                        RoundedRectangle(cornerRadius: 2)
                            .fill(level < field.indentLevel ? Color.theme.primary : Color.theme.surfaceBorder)
                            .frame(width: 4, height: 14)
                    }

                    Text("\(field.indentLevel)")
                        .font(.app.captionMedium)
                        .foregroundColor(.theme.textPrimary)
                        .frame(minWidth: 12)
                }
                .padding(.horizontal, AppSpacing.sm)
                .padding(.vertical, AppSpacing.sm)
                .background(Color.theme.surfaceCard)
                .cornerRadius(AppRadius.md)
                .overlay(
                    RoundedRectangle(cornerRadius: AppRadius.md)
                        .stroke(Color.theme.surfaceBorder, lineWidth: 1)
                )

                // Comment toggle
                Toggle(isOn: $field.isCommented) {
                    HStack(spacing: AppSpacing.xxs) {
                        Image(systemName: field.isCommented ? "number" : "number.slash")
                            .foregroundColor(field.isCommented ? .theme.warning : .theme.textSecondary)
                    }
                }
                .toggleStyle(SwitchToggleStyle(tint: .theme.warning))
                

            }
            .padding(.top, AppSpacing.xs)
        



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
                newListText = listItems.joined(separator: ", ")
            default:
                break
            }
        }
        .gesture(
            DragGesture(minimumDistance: 50, coordinateSpace: .local)
                .onEnded { value in
                    let horizontalDistance = value.translation.width
                    let verticalDistance = abs(value.translation.height)

                    // Only respond to mostly horizontal swipes
                    if abs(horizontalDistance) > verticalDistance {
                        if horizontalDistance > 0 {
                            // Swipe right: add indent (max 3)
                            if field.indentLevel < 3 {
                                field.indentLevel += 1
                                onUpdate()
                            }
                        } else {
                            // Swipe left: remove indent (min 0)
                            if field.indentLevel > 0 {
                                field.indentLevel -= 1
                                onUpdate()
                            }
                        }
                    }
                }
        )
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

// MARK: - User Input Field View
struct FrontMatterFieldInputView: View {
    @Binding var field: FrontMatterField
    let settings: SettingsStore
    
    // Local state variables
    @State private var boolValue: Bool = false
    @State private var numberText: String = ""
    @State private var dateValue: Date = Date()
    @State private var tagText: String = ""
    @State private var tagItems: [String] = []
    @State private var newListText: String = ""
    @State private var listItems: [String] = []
    
    var body: some View {
        if field.type.needsUserInput {
            Group {
                switch field.type {
                case .boolean:
                    booleanInput
                    
                case .number:
                    numberInput
                    
                case .date:
                    dateInput
                    
                case .datetime:
                    datetimeInput
                    
                case .tag:
                    tagInput
                    
                case .list:
                    listInput
                    
                case .multiline:
                    multilineInput
                    
                default:
                    stringInput
                }
            }
            .disabled(field.isCommented)
            .opacity(field.isCommented ? 0.5 : 1.0)
        } else {
            autoGeneratedInfo
        }
    }
    
    // MARK: - Boolean Input
    
    private var booleanInput: some View {
        HStack(spacing: AppSpacing.sm) {
            Text(boolValue ? "True" : "False")
                .font(.app.callout)
                .foregroundColor(.theme.textSecondary)
            Toggle("", isOn: $boolValue)
                .onChange(of: boolValue) { _, newValue in
                    field.value = newValue ? "true" : "false"
                }
        }
        .padding(.horizontal, AppSpacing.xxs)
        .onAppear {
            // Initialize boolValue from field.value
            boolValue = field.value.lowercased() == "true"
        }
    }
    
    // MARK: - Number Input
    
    private var numberInput: some View {
        VStack(alignment: .leading, spacing: AppSpacing.xs) {
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
                    }
                }
            
            if !isValidNumber(numberText) && !numberText.isEmpty {
                HStack(spacing: AppSpacing.xxs) {
                    Image(systemName: "exclamationmark.circle.fill")
                        .font(.app.caption)
                    Text("Please enter a valid number")
                        .font(.app.caption)
                }
                .foregroundColor(.theme.error)
            }
        }
        .onAppear {
            // Initialize numberText from field.value
            numberText = field.value
        }
    }
    
    // MARK: - Date Input
    
    private var dateInput: some View {
        DatePicker("", selection: $dateValue, displayedComponents: .date)
            .onChange(of: dateValue) { _, newValue in
                let formatter = DateFormatter()
                formatter.dateFormat = "yyyy-MM-dd"
                field.value = formatter.string(from: newValue)
            }
            .onAppear {
                // Initialize dateValue from field.value
                if !field.value.isEmpty {
                    let formatter = DateFormatter()
                    formatter.dateFormat = "yyyy-MM-dd"
                    if let date = formatter.date(from: field.value) {
                        dateValue = date
                    }
                }
            }
    }
    
    // MARK: - DateTime Input
    
    private var datetimeInput: some View {
        DatePicker("", selection: $dateValue, displayedComponents: [.date, .hourAndMinute])
            .onChange(of: dateValue) { _, newValue in
                let formatter = DateFormatter()
                formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss"
                field.value = formatter.string(from: newValue)
            }
            .onAppear {
                // Initialize dateValue from field.value
                if !field.value.isEmpty {
                    let formatter = DateFormatter()
                    formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss"
                    if let date = formatter.date(from: field.value) {
                        dateValue = date
                    }
                }
            }
    }
    
    // MARK: - Tag Input
    
    private var tagInput: some View {
        VStack(alignment: .leading, spacing: 8) {
            VStack(alignment: .leading, spacing: 4) {
                TextField("Tags (separate with commas: tag1, tag2, tag3)", text: $tagText)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .textInputAutocapitalization(.never)
                    .onChange(of: tagText) { _, newValue in
                        // Parse comma-separated tags and update field value
                        let tags = newValue.components(separatedBy: ",")
                            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
                            .filter { !$0.isEmpty }

                        if let jsonData = try? JSONEncoder().encode(tags),
                           let jsonString = String(data: jsonData, encoding: .utf8) {
                            field.value = jsonString
                            tagItems = tags
                        }
                    }
                
                Text("Use commas to separate tags: tag1, tag2, tag3")
                    .font(.app.caption)
                    .foregroundColor(.theme.textSecondary)
            }
            
            // Preview
            if !tagItems.isEmpty {
                Text("Preview:")
                    .font(.app.captionMedium)
                    .foregroundColor(.theme.textSecondary)

                Text(generateTagPreview())
                    .font(.app.monoCaption)
                    .foregroundColor(.theme.info)
                    .padding(AppSpacing.xs)
                    .background(Color.theme.infoBackground)
                    .cornerRadius(AppRadius.xs)
            }
        }
        .onAppear {
            // Initialize tagText and tagItems from field.value
            if !field.value.isEmpty,
               let data = field.value.data(using: .utf8),
               let tags = try? JSONDecoder().decode([String].self, from: data) {
                tagItems = tags
                tagText = tags.joined(separator: ", ")
            }
        }
    }
    
    // MARK: - List Input
    
    private var listInput: some View {
        VStack(alignment: .leading, spacing: 8) {
            VStack(alignment: .leading, spacing: 4) {
                TextField("List items (separate with commas: item1, item2, item3)", text: $newListText)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .textInputAutocapitalization(.never)
                    .onChange(of: newListText) { _, newValue in
                        // Parse comma-separated list items and update field value
                        let items = newValue.components(separatedBy: ",")
                            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
                            .filter { !$0.isEmpty }

                        if let jsonData = try? JSONEncoder().encode(items),
                           let jsonString = String(data: jsonData, encoding: .utf8) {
                            field.value = jsonString
                            listItems = items
                        }
                    }

                Text("Use commas to separate list items: item1, item2, item3")
                    .font(.app.caption)
                    .foregroundColor(.theme.textSecondary)
            }

            // Preview
            if !listItems.isEmpty {
                Text("Preview:")
                    .font(.app.captionMedium)
                    .foregroundColor(.theme.textSecondary)

                Text(generateListPreview())
                    .font(.app.monoCaption)
                    .foregroundColor(.theme.info)
                    .padding(AppSpacing.xs)
                    .background(Color.theme.infoBackground)
                    .cornerRadius(AppRadius.xs)
            }
        }
        .onAppear {
            // Initialize newListText and listItems from field.value
            if !field.value.isEmpty,
               let data = field.value.data(using: .utf8),
               let items = try? JSONDecoder().decode([String].self, from: data) {
                listItems = items
                newListText = items.joined(separator: ", ")
            }
        }
    }
    
    // MARK: - Multiline Input
    
    private var multilineInput: some View {
        VStack(alignment: .leading, spacing: AppSpacing.sm) {
            TextEditorWithVariablePicker(
                text: $field.value,
                context: .frontMatter,
                settings: settings,
                excludeFieldName: field.name,
                minHeight: 100
            )
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(Color.gray.opacity(0.3), lineWidth: 1)
            )

            Text("Supports multiple lines of text")
                .font(.app.caption)
                .foregroundColor(.theme.textSecondary)
            
            // Preview
            if !field.value.isEmpty {
                Text("Preview:")
                    .font(.app.captionMedium)
                    .foregroundColor(.theme.textSecondary)

                Text(generateMultilinePreview())
                    .font(.app.monoCaption)
                    .foregroundColor(.theme.info)
                    .padding(AppSpacing.xs)
                    .background(Color.theme.infoBackground)
                    .cornerRadius(AppRadius.xs)
            }
        }
    }
    
    // MARK: - String Input
    
    private var stringInput: some View {
        TextFieldWithVariablePicker(
            title: "Value",
            text: $field.value,
            context: .frontMatter,
            settings: settings,
            excludeFieldName: field.name
        )
    }
    
    // MARK: - Auto Generated Info
    
    private var autoGeneratedInfo: some View {
        Text("Automatically generated at processing time")
            .font(.app.caption)
            .foregroundColor(.theme.textSecondary)
            .italic()
    }
    
    // MARK: - Helper Methods
    
    private func isValidNumber(_ text: String) -> Bool {
        if text.isEmpty {
            return true
        }
        return Double(text) != nil
    }
    
    private func generateTagPreview() -> String {
        var lines: [String] = []
        lines.append("tags:")
        for tag in tagItems {
            lines.append("  - \(tag)")
        }
        return lines.joined(separator: "\n")
    }
    
    private func generateListPreview() -> String {
        var lines: [String] = []
        lines.append("\(field.name):")
        for item in listItems {
            lines.append("  - \(item)")
        }
        return lines.joined(separator: "\n")
    }
    
    private func generateMultilinePreview() -> String {
        var lines: [String] = []
        lines.append("\(field.name): |")
        let contentLines = field.value.components(separatedBy: .newlines)
        for line in contentLines {
            lines.append("  \(line)")
        }
        return lines.joined(separator: "\n")
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
        VStack(alignment: .leading, spacing: AppSpacing.sm) {
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
                .tint(.theme.textPrimary)
                .frame(width: .infinity)
                .onChange(of: newFieldType) { oldValue, newValue in
                    // Defer state modification to avoid "modifying state during view update" warning
                    Task { @MainActor in
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
                
            }
            
            
            // Conditional value input based on type
            if newFieldType.needsUserInput {
                switch newFieldType {
                case .boolean:
                    HStack {                        
                        Toggle(isOn: $newBoolValue){
                            Text(newBoolValue ? "True" : "False")
                                .foregroundColor(Color.secondary)
                        }
                            .onChange(of: newBoolValue) { _, newValue in
                                newFieldValue = newValue ? "true" : "false"
                        }
                    }
                    .padding(.horizontal, AppSpacing.sm)
                case .number:
                    HStack {
                        // Text("Value:")
                        TextField("Enter number", text: $newNumberText)
                            .keyboardType(.numberPad)
                            .textFieldStyle()
                            .overlay(
                                RoundedRectangle(cornerRadius: AppRadius.sm)
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
                    // HStack {
                        // Text(newDateValue, formatter: dataFormatter)
                        //     .foregroundColor(Color.secondary)

                        DatePicker("", selection: $newDateValue, displayedComponents: .date)
                            .onChange(of: newDateValue) { _, newValue in
                                let formatter = DateFormatter()
                                formatter.dateFormat = "yyyy-MM-dd"
                                newFieldValue = formatter.string(from: newValue)
                            }
                    // }
                    
                case .datetime:
                // VStack (alignment: .leading, spacing: AppSpacing.xs) {
                DatePicker("", selection: $newDateValue, displayedComponents: [.date, .hourAndMinute])
                    .onChange(of: newDateValue) { _, newValue in
                        let formatter = DateFormatter()
                        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss"
                        newFieldValue = formatter.string(from: newValue)
                    }

                case .tag:
                    VStack(alignment: .leading, spacing: AppSpacing.xs) {                        
                        TextField("Example: tag1, tag2, tag3", text: $newTagText)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .onChange(of: newTagText) { _, newValue in
                                // Parse comma-separated tags and update field value
                                let tags = newValue.components(separatedBy: ",")
                                    .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
                                    .filter { !$0.isEmpty }
                                
                                newTagItems = tags
                                updateNewTagValue()
                            }

                        Text("Use commas (',') to separate tags")
                            .font(.app.caption)
                            .foregroundColor(.theme.textSecondary)
                            .padding(.horizontal, AppSpacing.xxs)
                    }
                    
                case .list:
                    VStack(alignment: .leading, spacing: AppSpacing.xs) {
                        TextField("Example: item1, item2, item3", text: $addListText)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .onChange(of: addListText) { _, newValue in
                                // Parse comma-separated list items and update field value
                                let items = newValue.components(separatedBy: ",")
                                    .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
                                    .filter { !$0.isEmpty }
                                
                                newListItems = items
                                updateNewListValue()
                            }

                        Text("Use commas (',') to separate list items")
                            .font(.app.caption)
                            .foregroundColor(.theme.textSecondary)
                            .padding(.horizontal, AppSpacing.xxs)
                    }
                    
                    
                case .multiline:
                    VStack(alignment: .leading, spacing: AppSpacing.sm) {
                        TextEditorWithVariablePicker(
                            text: $newFieldValue,
                            context: .frontMatter,
                            settings: settings,
                            excludeFieldName: nil,
                            minHeight: 100
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                        )
                        
                        Text("Field name: >- your text")
                            .font(.app.caption)
                            .foregroundColor(.theme.textSecondary)
                    }
                    .id("newField-multiline")
                default:
                    // String - use the enhanced text field with variables
                    TextFieldWithVariablePicker(
                        title: "Value",
                        text: $newFieldValue,
                        context: .frontMatter,
                        settings: settings,
                        excludeFieldName: nil
                    )
                    .id("newField-\(newFieldType.rawValue)")
                }
            }
            else {
                switch newFieldType {
                    case .current_date:
                        Text("YYYY-mm-dd, generated at processing time")
                        .font(.app.caption)
                        .foregroundColor(.theme.textSecondary)
                        .italic()
                        .frame(maxWidth: .infinity, alignment: .leading)
                    case .current_datetime:
                        Text("YYYY-mm-dd'T'HH:MM:ss, generated at processing time")
                        .font(.app.caption)
                        .foregroundColor(.theme.textSecondary)
                        .italic()
                        .frame(maxWidth: .infinity, alignment: .leading)
                    default:
                        Text("generated at processing time")
                            .font(.app.caption)
                            .foregroundColor(.theme.textSecondary)
                            .italic()
                }
                // For current_date and current_datetime, show info text

            }

            VStack (spacing: AppSpacing.xxs) {
            Divider()
                .background(Color.gray.opacity(0.3))
                .padding(.vertical, AppSpacing.xs)
                // .border(Color.red)

            Button(
                action: {
                    let newField = FrontMatterField(name: newFieldName, type: newFieldType, value: newFieldValue)

                    // Defer state modification to avoid "modifying state during view update" warning
                    Task {
                        onAddField(newField)

                        // Reset form
                        await MainActor.run {
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
                }
            ){
                HStack {
                    Image(systemName: "plus.circle.fill")
                    Text("Add")
                }
                .frame(maxWidth: .infinity)
            }
            .buttonStyle(.ghost(color: Color.theme.info))
            // .border(Color.red)

            }


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

    private let dataFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter
    }()

    private func dataTimeFormatter() -> DateFormatter {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss"
        return formatter
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


// preview

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

