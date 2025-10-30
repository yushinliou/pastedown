//
//  AppTypography.swift
//  pastedown-v1
//
//  Design System - Typography
//  Centralized font definitions with semantic naming
//

import SwiftUI

// MARK: - Font Extension
extension Font {
    /// Access typography via Font.app.*
    static let app = AppTypography()
}

// MARK: - App Typography
struct AppTypography {

    // MARK: - Display
    /// Large titles, hero text
    /// Size: 28pt, Weight: Bold
    /// Usage: Main page headers, hero sections
    let display = Font.system(size: 28, weight: .bold)

    /// Display with regular weight
    let displayRegular = Font.system(size: 28, weight: .regular)

    // MARK: - Heading
    /// Section headers, card titles
    /// Size: 22pt, Weight: Semibold
    /// Usage: Section headers, important titles
    let heading = Font.system(size: 22, weight: .semibold)

    /// Heading with regular weight
    let headingRegular = Font.system(size: 22, weight: .regular)

    // MARK: - Title
    /// Card titles, list item headers
    /// Size: 18pt, Weight: Semibold
    /// Usage: Card titles, list headers
    let title = Font.system(size: 18, weight: .semibold)

    /// Title with regular weight
    let titleRegular = Font.system(size: 18, weight: .regular)

    /// Title with medium weight
    let titleMedium = Font.system(size: 18, weight: .medium)

    // MARK: - Body
    /// Regular paragraph text
    /// Size: 16pt, Weight: Regular
    /// Usage: Body text, descriptions
    let body = Font.system(size: 16, weight: .regular)

    /// Body with medium weight
    let bodyMedium = Font.system(size: 16, weight: .medium)

    /// Body with semibold weight
    let bodySemibold = Font.system(size: 16, weight: .semibold)

    // MARK: - Callout
    /// Emphasized smaller text
    /// Size: 14pt, Weight: Medium
    /// Usage: Labels, emphasized info
    let callout = Font.system(size: 14, weight: .medium)

    /// Callout with regular weight
    let calloutRegular = Font.system(size: 14, weight: .regular)

    /// Callout with semibold weight
    let calloutSemibold = Font.system(size: 14, weight: .semibold)

    // MARK: - Caption
    /// Small text, hints, metadata
    /// Size: 12pt, Weight: Regular
    /// Usage: Hints, timestamps, secondary info
    let caption = Font.system(size: 12, weight: .regular)

    /// Caption with medium weight
    let captionMedium = Font.system(size: 12, weight: .medium)

    /// Caption with semibold weight
    let captionSemibold = Font.system(size: 12, weight: .semibold)

    // MARK: - Monospace Fonts (for code/markdown)
    /// Monospace body font (for code display)
    let monoBody = Font.system(size: 16, weight: .regular, design: .monospaced)

    /// Monospace caption font
    let monoCaption = Font.system(size: 12, weight: .regular, design: .monospaced)
}

// MARK: - Text Style Modifiers
extension View {
    /// Apply display text style
    func displayStyle(color: Color = .theme.textPrimary) -> some View {
        self.font(.app.display)
            .foregroundColor(color)
    }

    /// Apply heading text style
    func headingStyle(color: Color = .theme.textPrimary) -> some View {
        self.font(.app.heading)
            .foregroundColor(color)
    }

    /// Apply title text style
    func titleStyle(color: Color = .theme.textPrimary) -> some View {
        self.font(.app.title)
            .foregroundColor(color)
    }

    /// Apply body text style
    func bodyStyle(color: Color = .theme.textPrimary) -> some View {
        self.font(.app.body)
            .foregroundColor(color)
    }

    /// Apply callout text style
    func calloutStyle(color: Color = .theme.textSecondary) -> some View {
        self.font(.app.callout)
            .foregroundColor(color)
    }

    /// Apply caption text style
    func captionStyle(color: Color = .theme.textSecondary) -> some View {
        self.font(.app.caption)
            .foregroundColor(color)
    }
}

// MARK: - Preview
#if DEBUG
struct AppTypography_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    // Display
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Display Text")
                            .font(.app.display)
                        Text("Large titles and hero text - 28pt Bold")
                            .font(.app.caption)
                            .foregroundColor(.theme.textSecondary)
                    }

                    Divider()

                    // Heading
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Heading Text")
                            .font(.app.heading)
                        Text("Section headers and important titles - 22pt Semibold")
                            .font(.app.caption)
                            .foregroundColor(.theme.textSecondary)
                    }

                    Divider()

                    // Title
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Title Text")
                            .font(.app.title)
                        Text("Card titles and list headers - 18pt Semibold")
                            .font(.app.caption)
                            .foregroundColor(.theme.textSecondary)
                    }

                    Divider()

                    // Body
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Body Text")
                            .font(.app.body)
                        Text("Regular paragraph text and descriptions - 16pt Regular")
                            .font(.app.caption)
                            .foregroundColor(.theme.textSecondary)
                        Text("This is body text with medium weight for emphasis")
                            .font(.app.bodyMedium)
                    }

                    Divider()

                    // Callout
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Callout Text")
                            .font(.app.callout)
                        Text("Labels and emphasized information - 14pt Medium")
                            .font(.app.caption)
                            .foregroundColor(.theme.textSecondary)
                    }

                    Divider()

                    // Caption
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Caption Text")
                            .font(.app.caption)
                        Text("Small text, hints, timestamps - 12pt Regular")
                            .font(.app.caption)
                            .foregroundColor(.theme.textSecondary)
                    }

                    Divider()

                    // Monospace
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Monospace Text")
                            .font(.app.monoBody)
                        Text("Code display and technical content - 16pt Monospaced")
                            .font(.app.caption)
                            .foregroundColor(.theme.textSecondary)
                    }
                }
                .padding()
            }
            .navigationTitle("Typography System")
        }
    }
}
#endif
