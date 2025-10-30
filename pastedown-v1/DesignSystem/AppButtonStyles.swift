//
//  AppButtonStyles.swift
//  pastedown-v1
//
//  Design System - Button Styles
//  5 button styles: Primary, Secondary, Tertiary, Destructive, Ghost
//

import SwiftUI

// MARK: - Primary Button Style
/// Main call-to-action buttons
/// Filled background with primary color, prominent appearance
struct PrimaryButtonStyle: ButtonStyle {
    var isFullWidth: Bool = false

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.app.bodyMedium)
            .foregroundColor(.white)
            .padding(.vertical, AppSpacing.sm)
            .padding(.horizontal, AppSpacing.lg)
            .frame(maxWidth: isFullWidth ? .infinity : nil)
            .background(
                RoundedRectangle(cornerRadius: AppRadius.lg)
                    .fill(Color.theme.primary)
            )
            .shadow(
                color: .black.opacity(configuration.isPressed ? 0.15 : 0.25),
                radius: configuration.isPressed ? 4 : 8,
                x: 0,
                y: configuration.isPressed ? 2 : 4
            )
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
            .animation(.easeInOut(duration: 0.2), value: configuration.isPressed)
    }
}

// MARK: - Secondary Button Style
/// Alternative action buttons
/// Light mode: Black bg, white text | Dark mode: White bg, black text
struct SecondaryButtonStyle: ButtonStyle {
    var isFullWidth: Bool = false
    @Environment(\.colorScheme) var colorScheme

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.app.bodyMedium)
            .foregroundColor(colorScheme == .dark ? Color.theme.neutralBlack : Color.theme.neutralWhite)
            .padding(.vertical, AppSpacing.sm)
            .padding(.horizontal, AppSpacing.lg)
            .frame(maxWidth: isFullWidth ? .infinity : nil)
            .background(
                RoundedRectangle(cornerRadius: AppRadius.lg)
                    .fill(colorScheme == .dark ? Color.theme.neutralWhite : Color.theme.neutralBlack)
            )
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
            .animation(.easeInOut(duration: 0.2), value: configuration.isPressed)
    }
}

// MARK: - Tertiary Button Style
/// Material Design-inspired elevated buttons
/// Light mode: White bg with shadows | Dark mode: Dark gray bg with subtle shadows
struct TertiaryButtonStyle: ButtonStyle {
    var isFullWidth: Bool = false
    @Environment(\.colorScheme) var colorScheme

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.app.callout)
            .foregroundColor(colorScheme == .dark ? Color.theme.neutralWhite : Color.theme.neutralBlack)
            .padding(.vertical, AppSpacing.md)
            .padding(.horizontal, AppSpacing.lg)
            .frame(maxWidth: isFullWidth ? .infinity : nil)
            .background(
                RoundedRectangle(cornerRadius: AppRadius.lg)
                    .fill(backgroundColor)
            )
            .shadow(
                color: shadowColor1,
                radius: configuration.isPressed ? 2 : 4,
                x: 0,
                y: configuration.isPressed ? 2 : 4
            )
            .scaleEffect(configuration.isPressed ? 0.98 : 1.0)
            .animation(.easeInOut(duration: 0.2), value: configuration.isPressed)

    }

    private var backgroundColor: Color {
        if colorScheme == .dark {
            return Color(white: 0.2) // Dark gray for dark mode
        } else {
            return Color.theme.neutralWhite
        }
    }

    private var shadowColor1: Color {
        if colorScheme == .dark {
            return Color.black.opacity(0.4)
        } else {
            return Color.black.opacity(0.2)
        }
    }

    private var shadowColor2: Color {
        if colorScheme == .dark {
            return Color.black.opacity(0.3)
        } else {
            return Color.black.opacity(0.14)
        }
    }
}

// MARK: - Destructive Button Style
/// Delete, remove, or warning actions
/// Red/error color, filled background
struct DestructiveButtonStyle: ButtonStyle {
    var isFullWidth: Bool = false

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.app.bodyMedium)
            .foregroundColor(.white)
            .padding(.vertical, AppSpacing.sm)
            .padding(.horizontal, AppSpacing.lg)
            .frame(maxWidth: isFullWidth ? .infinity : nil)
            .background(
                RoundedRectangle(cornerRadius: AppRadius.lg)
                    .fill(Color.theme.error)
            )
            .shadow(
                color: Color.theme.error.opacity(configuration.isPressed ? 0.2 : 0.3),
                radius: configuration.isPressed ? 4 : 8,
                x: 0,
                y: configuration.isPressed ? 2 : 4
            )
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
            .animation(.easeInOut(duration: 0.2), value: configuration.isPressed)
    }
}

// MARK: - Ghost Button Style
/// Minimal, transparent buttons
/// Text only with subtle press state
struct GhostButtonStyle: ButtonStyle {
    var color: Color = .theme.textSecondary
    var isFullWidth: Bool = false

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.app.callout)
            .foregroundColor(color)
            .padding(.vertical, AppSpacing.xs)
            .padding(.horizontal, AppSpacing.sm)
            .frame(maxWidth: isFullWidth ? .infinity : nil)
            .background(
                RoundedRectangle(cornerRadius: AppRadius.sm)
                    .fill(configuration.isPressed ? color.opacity(0.1) : Color.clear)
            )
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
            .animation(.easeInOut(duration: 0.2), value: configuration.isPressed)
    }
}

// MARK: - Button Style Extensions for Easy Access
extension ButtonStyle where Self == PrimaryButtonStyle {
    static var primary: PrimaryButtonStyle {
        PrimaryButtonStyle()
    }

    static func primary(fullWidth: Bool) -> PrimaryButtonStyle {
        PrimaryButtonStyle(isFullWidth: fullWidth)
    }
}

extension ButtonStyle where Self == SecondaryButtonStyle {
    static var secondary: SecondaryButtonStyle {
        SecondaryButtonStyle()
    }

    static func secondary(fullWidth: Bool) -> SecondaryButtonStyle {
        SecondaryButtonStyle(isFullWidth: fullWidth)
    }
}

extension ButtonStyle where Self == TertiaryButtonStyle {
    static var tertiary: TertiaryButtonStyle {
        TertiaryButtonStyle()
    }

    static func tertiary(fullWidth: Bool) -> TertiaryButtonStyle {
        TertiaryButtonStyle(isFullWidth: fullWidth)
    }
}

extension ButtonStyle where Self == DestructiveButtonStyle {
    static var destructive: DestructiveButtonStyle {
        DestructiveButtonStyle()
    }

    static func destructive(fullWidth: Bool) -> DestructiveButtonStyle {
        DestructiveButtonStyle(isFullWidth: fullWidth)
    }
}

extension ButtonStyle where Self == GhostButtonStyle {
    static var ghost: GhostButtonStyle {
        GhostButtonStyle()
    }

    static func ghost(color: Color = .theme.textSecondary, fullWidth: Bool = false) -> GhostButtonStyle {
        GhostButtonStyle(color: color, isFullWidth: fullWidth)
    }
}

// MARK: - Preview
#if DEBUG
struct AppButtonStyles_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            // Light Mode
            buttonStylesContent
                .preferredColorScheme(.light)
                .previewDisplayName("Light Mode")

            // Dark Mode
            buttonStylesContent
                .preferredColorScheme(.dark)
                .previewDisplayName("Dark Mode")
        }
    }

    @ViewBuilder
    static var buttonStylesContent: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: AppSpacing.xl) {
                    // Primary Buttons
                    Group {
                        Text("Primary Button")
                            .font(.app.heading)

                        VStack(spacing: AppSpacing.md) {
                            Button("Primary Action") {}
                                .buttonStyle(.primary)

                            Button("Full Width Primary") {}
                                .buttonStyle(.primary(fullWidth: true))

                            Button(action: {}) {
                                HStack {
                                    Image(systemName: "checkmark.circle.fill")
                                    Text("With Icon")
                                }
                            }
                            .buttonStyle(.primary)
                        }
                    }

                    Divider()

                    // Secondary Buttons
                    Group {
                        Text("Secondary Button")
                            .font(.app.heading)

                        VStack(spacing: AppSpacing.md) {
                            Button("Secondary Action") {}
                                .buttonStyle(.secondary)

                            Button("Full Width Secondary") {}
                                .buttonStyle(.secondary(fullWidth: true))

                            Button(action: {}) {
                                HStack {
                                    Image(systemName: "star")
                                    Text("With Icon")
                                }
                            }
                            .buttonStyle(.secondary)
                        }
                    }

                    Divider()

                    // Tertiary Buttons
                    Group {
                        Text("Tertiary Button")
                            .font(.app.heading)

                        VStack(spacing: AppSpacing.md) {
                            Button("Tertiary Action") {}
                                .buttonStyle(.tertiary)

                            Button("Full Width Tertiary") {}
                                .buttonStyle(.tertiary(fullWidth: true))

                            HStack(spacing: AppSpacing.sm) {
                                Button("Cancel") {}
                                    .buttonStyle(.tertiary)
                                Button("Save") {}
                                    .buttonStyle(.tertiary)
                            }
                        }
                    }

                    Divider()

                    // Destructive Buttons
                    Group {
                        Text("Destructive Button")
                            .font(.app.heading)

                        VStack(spacing: AppSpacing.md) {
                            Button("Delete Item") {}
                                .buttonStyle(.destructive)

                            Button("Full Width Delete") {}
                                .buttonStyle(.destructive(fullWidth: true))

                            Button(action: {}) {
                                HStack {
                                    Image(systemName: "trash")
                                    Text("Remove")
                                }
                            }
                            .buttonStyle(.destructive)
                        }
                    }

                    Divider()

                    // Ghost Buttons
                    Group {
                        Text("Ghost Button")
                            .font(.app.heading)

                        VStack(spacing: AppSpacing.md) {
                            Button("Ghost Action") {}
                                .buttonStyle(.ghost)

                            Button("Colored Ghost") {}
                                .buttonStyle(.ghost(color: .theme.info))

                            HStack(spacing: AppSpacing.md) {
                                Button("Option 1") {}
                                    .buttonStyle(.ghost)
                                Button("Option 2") {}
                                    .buttonStyle(.ghost)
                                Button("Option 3") {}
                                    .buttonStyle(.ghost)
                            }
                        }
                    }
                }
                .padding(AppSpacing.lg)
            }
            .navigationTitle("Button Styles")
        }
    }
}
#endif
