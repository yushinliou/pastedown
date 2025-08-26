import SwiftUI


struct InitialViewWithSettings: View {
    @Binding var isConverting: Bool
    @Binding var showingAdvancedSettings: Bool
    @ObservedObject var settings: SettingsStore
    var pasteFromClipboard: () -> Void

    var body: some View {
        Group {
            VStack(spacing: 25) {
                // Header section
                VStack(spacing: 20) {
                    
                    VStack(spacing: 10) {
                        Image("pastedown")
                            .resizable()
                            .frame(width: 60, height: 60)
                            .foregroundColor(.blue)
                        
                        Text("Paste Down")
                            .font(.title)
                            .fontWeight(.bold)
                        
                        Text("Convert clipboard rich text to Markdown")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    
                    Button(action: pasteFromClipboard) {
                        HStack {
                            Image(systemName: "clipboard")
                            Text("Paste")
                        }
                    }
                    .buttonStyle(PasteButtonStyle())
                    .disabled(isConverting)
                    
                    if isConverting {
                        ProgressView("Converting...")
                            .padding(.top, 10)
                    }
                }
                
                Divider()
                
                // Quick Settings Section
                VStack(alignment: .leading, spacing: 20) {
                    HStack {
                        Text("Quick Settings")
                            .font(.headline)
                            .fontWeight(.semibold)
                        
                        Spacer()
                        
                        Button("Advanced") {
                            showingAdvancedSettings = true
                        }
                        .font(.caption)
                        .foregroundColor(.blue)
                    }
                    
                    // Image Handling
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Image Handling")
                            .font(.subheadline)
                            .fontWeight(.medium)
                        
                        Picker("Image handling", selection: $settings.imageHandling) {
                            ForEach(ImageHandling.allCases, id: \.self) { handling in
                                Text(handling.displayName).tag(handling)
                            }
                        }
                        .pickerStyle(SegmentedPickerStyle())
                        .onChange(of: settings.imageHandling) {  oldValue, newValue in
                            print("\(oldValue) -> \(newValue)")
                            settings.saveSettings()
                        }
                        
                        if settings.imageHandling == .saveToFolder {
                            VStack(alignment: .leading, spacing: 4) {
                                TextField("Folder path", text: $settings.imageFolderPath)
                                    .textFieldStyle(RoundedBorderTextFieldStyle())
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 8)
                                            .stroke(settings.isValidImagePath() ? Color.clear : Color.red, lineWidth: 2)
                                    )
                                    .onChange(of: settings.imageFolderPath) { oldValue, newValue in
                                        print("\(oldValue) -> \(newValue)")
                                        settings.saveSettings()
                                    }
                                
                                Text("Variables: {time}, {date}, {clipboard_preview}")
                                    .font(.caption2)
                                    .foregroundColor(.secondary)
                                
                                // Preview
                                if settings.isValidImagePath() {
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text("Preview:")
                                            .font(.caption2)
                                            .fontWeight(.medium)
                                            .foregroundColor(.secondary)
                                        Text(settings.generateImagePathPreview())
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
                            // Preview for base64 and ignore
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Preview:")
                                    .font(.caption2)
                                    .fontWeight(.medium)
                                    .foregroundColor(.secondary)
                                Text(settings.generateImageHandlingPreview())
                                    .font(.caption2)
                                    .foregroundColor(.blue)
                                    .padding(.horizontal, 6)
                                    .padding(.vertical, 2)
                                    .background((Color.blue).opacity(0.1))
                                    .cornerRadius(4)
                            }
                        }
                    }
                    
                    // Alt Text Generation
                    VStack(alignment: .leading, spacing: 8) {
                        if settings.imageHandling != .ignore {
                            HStack {
                                Text("Alt Text Generation")
                                    .font(.subheadline)
                                    .fontWeight(.medium)
                                
                                Spacer()
                                
                                Toggle("", isOn: $settings.enableAutoAlt)
                                    .onChange(of: settings.enableAutoAlt) { oldValue, newValue in
                                        print("\(oldValue) -> \(newValue)")
                                        settings.saveSettings()
                                    }
                            }
                            if settings.enableAutoAlt {
                            Picker("Template", selection: $settings.altTextTemplate) {
                                ForEach(AltTextTemplate.allCases, id: \.self) { template in
                                    Text(template.displayName).tag(template)
                                }
                            }
                            .pickerStyle(MenuPickerStyle())
                            .onChange(of: settings.altTextTemplate) {  oldValue, newValue in
                                print("\(oldValue) -> \(newValue)")
                                settings.saveSettings()
                            }
                        }
                        }
                    }
                    
                    // Output Filename
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Output Filename")
                            .font(.subheadline)
                            .fontWeight(.medium)
                        
                        TextField("Filename format (without .md)", text: $settings.outputFilenameFormat)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .overlay(
                                RoundedRectangle(cornerRadius: 8)
                                    .stroke(settings.isValidOutputFilename() ? Color.clear : Color.red, lineWidth: 2)
                            )
                            .onChange(of: settings.outputFilenameFormat) {  oldValue, newValue in
                                print("\(oldValue) -> \(newValue)")
                                settings.saveSettings()
                            }
                        
                        Text("Variables: {clipboard_preview}, {date}, {time}")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                        
                        // Filename Preview
                        if settings.isValidOutputFilename() {
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Preview:")
                                    .font(.caption2)
                                    .fontWeight(.medium)
                                    .foregroundColor(.secondary)
                                Text(settings.generateOutputFilenamePreview())
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
                    
                    // Front Matter Preview
                    if !settings.frontMatterFields.isEmpty {
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Text("Front Matter Fields")
                                    .font(.subheadline)
                                    .fontWeight(.medium)
                                
                                Spacer()
                                
                                Text("\(settings.frontMatterFields.count) fields")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 8) {
                                    ForEach(settings.frontMatterFields.prefix(3)) { field in
                                        Text(field.name.isEmpty ? "unnamed" : field.name)
                                            .font(.caption)
                                            .padding(.horizontal, 8)
                                            .padding(.vertical, 4)
                                            .background(Color.blue.opacity(0.1))
                                            .foregroundColor(.blue)
                                            .cornerRadius(4)
                                    }
                                    
                                    if settings.frontMatterFields.count > 3 {
                                        Text("+\(settings.frontMatterFields.count - 3) more")
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                    }
                                }
                                .padding(.horizontal, 2)
                            }
                        }
                    }
                }
                .padding()
                .background(Color.gray.opacity(0.05))
                .cornerRadius(12)
            }
        }
    }
}