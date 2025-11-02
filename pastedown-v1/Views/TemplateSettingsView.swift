//
//  TemplateSettingsView.swift
//  pastedown-v1
//
//  Last modify by Yu Shin on 2025/09/22
//  Refactored into modular components
//

import SwiftUI

struct TemplateSettingsView: View {
    @ObservedObject var settings: SettingsStore
    @Binding var isPresented: Bool
    @StateObject private var viewModel: TemplateSettingsViewModel

    init(settings: SettingsStore, isPresented: Binding<Bool>, template: Template? = nil) {
        self.settings = settings
        self._isPresented = isPresented
        self._viewModel = StateObject(wrappedValue: TemplateSettingsViewModel(settings: settings, template: template))
    }

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: AppSpacing.lg) {
                TemplateNameSection(viewModel: viewModel)
                FileNameSection(viewModel: viewModel)
                ImageHandlingSection(viewModel: viewModel)
                FrontMatterSection(viewModel: viewModel)
                }
                .padding(.horizontal, AppSpacing.xl)
            }
            .navigationTitle(viewModel.isEditing ? "Edit Template" : "New Template")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        isPresented = false
                    }
                }

                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(viewModel.isEditing ? "Update" : "Save") {
                        viewModel.saveTemplate {
                            isPresented = false
                        }
                    }
                    .disabled(!viewModel.canSave())
                }
            }
            .onAppear {
                viewModel.loadTemplateData()
                // Initialize cached settings: Using Task to avoid SwiftUI state update warnings
                Task { @MainActor in
                    viewModel.updateCachedSettings()
                }
            }
            .onChange(of: viewModel.frontMatterFields) { _, _ in
                // Update cached settings when front matter fields change
                // Defer to avoid "modifying state during view update" warning
                Task { @MainActor in
                    viewModel.updateCachedSettings()
                }
            }
        }
        .alert("Error", isPresented: $viewModel.showingAlert) {
            Button("OK") { }
        } message: {
            Text(viewModel.alertMessage)
        }
    }
}
