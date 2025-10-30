// Starting page
// InitialViewWithSetting.swift
import SwiftUI


struct InitialViewWithSettings: View {
    @Binding var isConverting: Bool
    @Binding var showingAdvancedSettings: Bool
    @ObservedObject var settings: SettingsStore
    var pasteFromClipboard: () -> Void

    @State private var showingNewTemplate = false
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

            // Template Selection Picker
            VStack(spacing: AppSpacing.xs) {
                Text("Active Template")
                    .font(.app.calloutSemibold)
                    .foregroundColor(.theme.textSecondary)

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
                .padding(.horizontal, AppSpacing.md)
                .padding(.vertical, AppSpacing.xs)
                .background(Color.theme.infoBackground)
                .cornerRadius(AppRadius.md)
            }

            // Four Main Buttons
            VStack(spacing: AppSpacing.md) {
                // Paste button (primary action)
                Button(action: pasteFromClipboard) {
                    HStack(spacing: AppSpacing.sm) {
                        Image(systemName: "clipboard")
                            .font(.app.title)
                        Text("Paste Clipboard Content")
                            .font(.app.bodyMedium)
                    }
                }
                .buttonStyle(.primary(fullWidth: true))
                .disabled(isConverting)
                .opacity(isConverting ? 0.6 : 1.0)

                // Template action buttons - only 2 now since selection is handled by picker
                HStack(spacing: AppSpacing.sm) {
                    // Add new template
                    Button(action: {
                        showingNewTemplate = true
                    }) {
                        VStack(spacing: AppSpacing.xxs) {
                            Image(systemName: "plus")
                                .font(.app.title)
                            Text("Add Template")
                                .font(.app.caption)
                        }
                        .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.secondary)

                    // Edit template
                    Button(action: {
                        showingEditTemplate = true
                    }) {
                        VStack(spacing: AppSpacing.xxs) {
                            Image(systemName: "pencil")
                                .font(.app.title)
                            Text("Edit Template")
                                .font(.app.caption)
                        }
                        .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.secondary)
                }
            }

            if isConverting {
                ProgressView("Converting...")
                    .font(.app.callout)
                    .foregroundColor(.theme.textSecondary)
                    .padding(.top, AppSpacing.sm)
            }

            Spacer()
        }
        .padding(AppSpacing.lg)
        .sheet(isPresented: $showingNewTemplate) {
            TemplateSettingsView(settings: settings, isPresented: $showingNewTemplate)
        }
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
