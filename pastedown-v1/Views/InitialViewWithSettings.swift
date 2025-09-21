import SwiftUI


struct InitialViewWithSettings: View {
    @Binding var isConverting: Bool
    @Binding var showingAdvancedSettings: Bool
    @ObservedObject var settings: SettingsStore
    var pasteFromClipboard: () -> Void

    @State private var showingNewTemplate = false
    @State private var showingEditTemplate = false

    var body: some View {
        VStack(spacing: 30) {
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
            }

            // Template Selection Picker
            VStack(spacing: 8) {
                Text("Active Template")
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.secondary)

                Picker("Select Template", selection: Binding(
                    get: { settings.currentTemplateID ?? UUID() },
                    set: { newID in
                        if let template = settings.templates.first(where: { $0.id == newID }) {
                            settings.applyTemplate(template)
                        }
                    }
                )) {
                    ForEach(settings.templates) { template in
                        Text(template.name).tag(template.id)
                    }
                }
                .pickerStyle(MenuPickerStyle())
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(Color.blue.opacity(0.1))
                .cornerRadius(8)
            }

            // Four Main Buttons
            VStack(spacing: 16) {
                // Paste button (primary action)
                Button(action: pasteFromClipboard) {
                    HStack {
                        Image(systemName: "clipboard")
                            .font(.title2)
                        Text("Paste Clipboard Content")
                            .font(.headline)
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(12)
                }
                .disabled(isConverting)

                // Template action buttons - only 2 now since selection is handled by picker
                HStack(spacing: 12) {
                    // Add new template
                    Button(action: {
                        showingNewTemplate = true
                    }) {
                        VStack(spacing: 4) {
                            Image(systemName: "plus")
                                .font(.title2)
                            Text("Add Template")
                                .font(.caption)
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.green.opacity(0.1))
                        .foregroundColor(.green)
                        .cornerRadius(8)
                    }

                    // Edit template
                    Button(action: {
                        showingEditTemplate = true
                    }) {
                        VStack(spacing: 4) {
                            Image(systemName: "pencil")
                                .font(.title2)
                            Text("Edit Template")
                                .font(.caption)
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.purple.opacity(0.1))
                        .foregroundColor(.purple)
                        .cornerRadius(8)
                    }
                }
            }

            if isConverting {
                ProgressView("Converting...")
                    .padding(.top, 10)
            }

            Spacer()
        }
        .padding()
        .sheet(isPresented: $showingNewTemplate) {
            TemplateSettingsView(settings: settings, isPresented: $showingNewTemplate)
        }
        .sheet(isPresented: $showingEditTemplate) {
            if let currentTemplate = settings.currentTemplate {
                TemplateSettingsView(settings: settings, isPresented: $showingEditTemplate, template: currentTemplate)
            }
        }
    }
}