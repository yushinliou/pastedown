//
//  TemplateSettingsView 2.swift
//  pastedown-v1
//
//  Created by liuyuxin on 2025/10/30.
//

import SwiftUI

#if DEBUG
struct TemplateSettingsView_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            // New Template Preview - Light Mode
            NewTemplatePreview()
                .preferredColorScheme(.light)
                .previewDisplayName("New Template - Light")

            // New Template Preview - Dark Mode
            NewTemplatePreview()
                .preferredColorScheme(.dark)
                .previewDisplayName("New Template - Dark")

            // Edit Template Preview - Light Mode
            EditTemplatePreview()
                .preferredColorScheme(.light)
                .previewDisplayName("Edit Template - Light")

            // Edit Template Preview - Dark Mode
            EditTemplatePreview()
                .preferredColorScheme(.dark)
                .previewDisplayName("Edit Template - Dark")
        }
    }

    // MARK: - New Template Preview
    struct NewTemplatePreview: View {
        @StateObject private var settings = SettingsStore()
        @State private var isPresented = true

        var body: some View {
            TemplateSettingsView(
                settings: settings,
                isPresented: $isPresented
            )
        }
    }

    // MARK: - Edit Template Preview
    struct EditTemplatePreview: View {
        @StateObject private var settings: SettingsStore
        @State private var isPresented = true

        init() {
            let store = SettingsStore()

            // Create a sample template with some configured values
            var sampleTemplate = Template(name: "Blog Post", settingsStore: store)
            sampleTemplate.outputFilenameFormat = "{date}-{clipboard_preview}"
            sampleTemplate.imageHandling = .saveToFolder
            sampleTemplate.imageFolderPath = "images/{date}"
            sampleTemplate.enableAutoAlt = true
            sampleTemplate.altTextTemplate = .imageOf
            sampleTemplate.enableFrontMatter = true
            sampleTemplate.frontMatterFields = [
                FrontMatterField(name: "title", type: .string, value: ""),
                FrontMatterField(name: "date", type: .date, value: ""),
            ]

            store.templates.append(sampleTemplate)
            _settings = StateObject(wrappedValue: store)
        }

        var body: some View {
            if let template = settings.templates.first(where: { $0.name == "Blog Post" }) {
                TemplateSettingsView(
                    settings: settings,
                    isPresented: $isPresented,
                    template: template
                )
            } else {
                Text("Template not found")
            }
        }
    }
}
#endif
