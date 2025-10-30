// Starting page
// InitialViewWithSetting.swift
import SwiftUI


struct InitialViewWithSettings: View {
    @Binding var isConverting: Bool
    @Binding var showingAdvancedSettings: Bool
    @ObservedObject var settings: SettingsStore
    var pasteFromClipboard: () -> Void

    @State private var showingEditTemplate = false
    @State private var showingTemplateManagement = false
    @State private var showingAppSettings = false

    var body: some View {
        VStack(spacing: AppSpacing.xl) {
            // Header section
            VStack(spacing: AppSpacing.lg) {
                VStack(spacing: AppSpacing.sm) {
                    Image("pastedown")
                        .resizable()
                        .frame(width: 60, height: 60)
                        .foregroundColor(.theme.info)

                    Text("Paste Down")
                        .font(.app.display)
                        .foregroundColor(.theme.textPrimary)

                    Text("Convert clipboard rich text to Markdown")
                        .font(.app.callout)
                        .foregroundColor(.theme.textSecondary)
                        .multilineTextAlignment(.center)
                }
            }

            // Template Selection and Actions
            HStack(spacing: AppSpacing.sm) {
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
                .secondaryPickerStyle()

                // Edit template
                Button(action: {
                    showingEditTemplate = true
                }) {
                    Image(systemName: "pencil")
                        .font(.app.title)
                }
                .buttonStyle(.tertiary)
            }

            // Main Action Button
            Button(action: pasteFromClipboard) {
                HStack(spacing: AppSpacing.sm) {
                    Image(systemName: "clipboard")
                        .font(.app.title)
                    Text("Paste Clipboard Content")
                        .font(.app.bodyMedium)
                }
            }
            .buttonStyle(.secondary(fullWidth: true))
            .disabled(isConverting)
            .opacity(isConverting ? 0.6 : 1.0)

            if isConverting {
                ProgressView("Converting...")
                    .font(.app.callout)
                    .foregroundColor(.theme.textSecondary)
                    .padding(.top, AppSpacing.sm)
            }
        }
        .padding(AppSpacing.lg)
        .sheet(isPresented: $showingEditTemplate) {
            if let currentTemplate = settings.currentTemplate {
                TemplateSettingsView(settings: settings, isPresented: $showingEditTemplate, template: currentTemplate)
            }
        }
        .sheet(isPresented: $showingTemplateManagement) {
            TemplateManagementListView(settings: settings, isPresented: $showingTemplateManagement)
        }
        .sheet(isPresented: $showingAppSettings) {
            AppSettingsView(isPresented: $showingAppSettings)
        }
        .frame(maxHeight: .infinity) // make VStack take full height
        .padding(AppSpacing.lg)
    }
}


struct InitialViewWithSettings_Previews: PreviewProvider {
    struct PreviewWrapper: View {
        @State private var isConverting = false
        @State private var showingAdvancedSettings = false
        @StateObject private var settings = SettingsStore() // 測試用假資料

        var body: some View {
            InitialViewWithSettings(
                isConverting: $isConverting,
                showingAdvancedSettings: $showingAdvancedSettings,
                settings: settings,
                pasteFromClipboard: {
                    print("Pretend to paste from clipboard")
                }
            )
        }
    }

    static var previews: some View {
        PreviewWrapper()
            .previewDisplayName("Initial View With Settings")
    }
}
