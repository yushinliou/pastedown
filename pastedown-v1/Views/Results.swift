import SwiftUI

struct ResultView: View {
    @Binding var convertedMarkdown: String
    @Binding var showingAlert: Bool
    @Binding var alertMessage: String
    @Binding var showingAdvancedSettings: Bool
    @ObservedObject var settings: SettingsStore

    var body: some View {
        VStack(spacing: 20) {
            // Quick settings in result view
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Text("Settings")
                        .font(.headline)
                        .fontWeight(.semibold)
                    
                    Spacer()
                    
                    Button("Advanced") {
                        showingAdvancedSettings = true
                    }
                    .font(.caption)
                    .foregroundColor(.blue)
                }
                
                HStack(spacing: 15) {
                    // Image handling quick toggle
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Images")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        Picker("", selection: $settings.imageHandling) {
                            Text("Ignore").tag(ImageHandling.ignore)
                            Text("Local").tag(ImageHandling.saveLocal)
                            Text("Custom").tag(ImageHandling.saveCustom)
                        }
                        .pickerStyle(MenuPickerStyle())
                        .onChange(of: settings.imageHandling) {  oldValue, newValue in
                            print("\(oldValue) -> \(newValue)")
                            settings.saveSettings()
                        }
                    }
                    
                    // Alt text toggle
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Alt Text")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        Toggle("", isOn: $settings.enableAutoAlt)
                            .onChange(of: settings.enableAutoAlt) {  oldValue, newValue in
                                print("\(oldValue) -> \(newValue)")
                                settings.saveSettings()
                            }
                    }
                    
                    Spacer()
                }
            }
            .padding()
            .background(Color.gray.opacity(0.05))
            .cornerRadius(12)
            
            // Editor
            VStack(alignment: .leading, spacing: 8) {
                Text("Markdown Output")
                    .font(.headline)
                    .fontWeight(.semibold)
                
                TextEditor(text: $convertedMarkdown)
                    .font(.system(.body, design: .monospaced))
                    .padding()
                    .background(Color.gray.opacity(0.05))
                    .cornerRadius(8)
                    .frame(minHeight: 300)
            }
            
            // Bottom buttons
            HStack {
                Button("Done") {
                    convertedMarkdown = ""
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 10)
                .background(Color.gray.opacity(0.2))
                .cornerRadius(8)
                
                Spacer()
                
                Button("Copy Markdown") {
                    UIPasteboard.general.string = convertedMarkdown
                    alertMessage = "Markdown copied to clipboard!"
                    showingAlert = true
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 10)
                .background(Color("primaryColour"))
                .foregroundColor(Color("backgroundColour"))
                .cornerRadius(8)
            }
        }
   }
}
