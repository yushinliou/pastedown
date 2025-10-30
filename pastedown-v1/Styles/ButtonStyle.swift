//
//  ButtonStyle.swift
//  pastedown-v1
//
//  Created by 劉羽芯 on 2025/7/6.
//  Updated to use Design System
//

import SwiftUI

// MARK: - Legacy Button Style (Updated to use Design System)
/// Custom paste button style - now using design system colors and spacing
/// Consider using PrimaryButtonStyle from AppButtonStyles.swift instead
struct PasteButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.app.bodyMedium)  // Updated to use design system typography
            .foregroundColor(.theme.primary)  // Updated to use design system colors
            .padding(.vertical, AppSpacing.sm + 2)  // Updated to use design system spacing
            .padding(.horizontal, AppSpacing.lg)
            .background(
                RoundedRectangle(cornerRadius: AppRadius.xl)  // Updated to use design system radius
                    .fill(Color.theme.background)
                    .shadow(color: .black.opacity(configuration.isPressed ? 0.2 : 0.3),
                            radius: configuration.isPressed ? 6 : 10,
                            x: 0,
                            y: configuration.isPressed ? 4 : 6)
            )
            .scaleEffect(configuration.isPressed ? 0.8 : 1.0)
            .animation(.easeInOut(duration: 0.3), value: configuration.isPressed)
    }
}

// MARK: - Migration Guide
/*
 To migrate from PasteButtonStyle to the new design system button styles:

 OLD:
 Button("Paste") { }
     .buttonStyle(PasteButtonStyle())

 NEW (Recommended):
 Button("Paste") { }
     .buttonStyle(.primary)

 Other available styles:
 - .primary          - Main call-to-action buttons
 - .secondary        - Alternative actions
 - .tertiary         - Subtle actions
 - .destructive      - Delete/warning actions
 - .ghost            - Minimal style

 Full-width option:
 Button("Paste") { }
     .buttonStyle(.primary(fullWidth: true))
 */
