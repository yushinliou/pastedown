//
//  AppColors.swift
//  pastedown-v1
//
//  Design System - Colors
//  Centralized color definitions with automatic dark/light mode support
//

import SwiftUI

// MARK: - Theme Colors Extension
extension Color {
    /// Access theme colors via Color.theme.*
    static let theme = AppThemeColors()
}

// MARK: - App Theme Colors
struct AppThemeColors {

    // MARK: - Brand Colors
    /// Primary brand color (consistent across light and dark modes)
    /// Both modes: Dark blue (#0A2363)
    let primary = Color("primaryColour")

    /// Secondary brand color
    /// Both modes: Orange/rust (#549CD5)
    let secondary = Color("secondaryColour")

    /// Main background color
    /// Light: White (#FFFCF9), Dark: Dark brown (#0A2363)
    let background = Color("backgroundColour")

    // MARK: - Semantic Colors
    /// Success state color (green)
    /// Light: #34C93D, Dark: #48E55A
    let success = Color("successColor")

    /// Warning state color (orange)
    /// Light: #FF9900, Dark: #FFAA1A
    let warning = Color("warningColor")

    /// Error state color (red)
    /// Light: #FF3B38, Dark: #FF5252
    let error = Color("errorColor")

    /// Informational color (black)
    /// Both modes: #000000
    let info = Color("infoColor")

    // MARK: - Text Colors
    /// Primary text color (adaptive)
    /// Light: Black, Dark: White
    let textPrimary = Color("textPrimary")

    /// Secondary text color (adaptive, 60% opacity)
    /// Light: Black 60%, Dark: White 60%
    let textSecondary = Color("textSecondary")

    /// Tertiary text color (adaptive, 40% opacity)
    /// Light: Black 40%, Dark: White 40%
    let textTertiary = Color("textTertiary")

    // MARK: - Surface Colors
    /// Card/container background color
    /// Light: White, Dark: Dark gray (#2D2D2D)
    let surfaceCard = Color("surfaceCard")

    /// Border color for UI elements
    /// Light: Black 20%, Dark: White 30%
    let surfaceBorder = Color("surfaceBorder")
    
    // MARK: - Neutral Colors (for UI elements, buttons, etc.)
    /// Universal black and white colors
    /// Use these for button backgrounds, icons, or neutral UI areas
    let neutralBlack = Color.black
    let neutralWhite = Color.white

    /// Optional mid-gray for disabled states or dividers
    let neutralGray = Color.gray.opacity(0.6)

    // MARK: - Semantic Background Colors with Opacity
    /// Success background (for alerts, badges, etc.)
    var successBackground: Color {
        success.opacity(0.1)
    }

    /// Warning background (for alerts, badges, etc.)
    var warningBackground: Color {
        warning.opacity(0.1)
    }

    /// Error background (for alerts, badges, etc.)
    var errorBackground: Color {
        error.opacity(0.1)
    }

    /// Info background (for alerts, badges, etc.)
    var infoBackground: Color {
        info.opacity(0.1)
    }
}

// MARK: - Preview Helper
#if DEBUG
extension AppThemeColors {
    /// Preview all theme colors in a list
    static var allColors: [(String, Color)] {
        let theme = Color.theme
        return [
            ("Primary", theme.primary),
            ("Secondary", theme.secondary),
            ("Background", theme.background),
            ("Success", theme.success),
            ("Warning", theme.warning),
            ("Error", theme.error),
            ("Info", theme.info),
            ("Text Primary", theme.textPrimary),
            ("Text Secondary", theme.textSecondary),
            ("Text Tertiary", theme.textTertiary),
            ("Surface Card", theme.surfaceCard),
            ("Surface Border", theme.surfaceBorder),
            ("Neutral Black", theme.neutralBlack),
            ("Neutral White", theme.neutralWhite),
            ("Neutral Gray", theme.neutralGray)
        ]
    }
}

// MARK: - Color Preview
struct AppColors_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            List {
                Section("Brand Colors") {
                    ColorRow(name: "Primary", color: .theme.primary)
                    ColorRow(name: "Secondary", color: .theme.secondary)
                    ColorRow(name: "Background", color: .theme.background)
                }

                Section("Semantic Colors") {
                    ColorRow(name: "Success", color: .theme.success)
                    ColorRow(name: "Warning", color: .theme.warning)
                    ColorRow(name: "Error", color: .theme.error)
                    ColorRow(name: "Info", color: .theme.info)
                }

                Section("Text Colors") {
                    ColorRow(name: "Text Primary", color: .theme.textPrimary)
                    ColorRow(name: "Text Secondary", color: .theme.textSecondary)
                    ColorRow(name: "Text Tertiary", color: .theme.textTertiary)
                }

                Section("Surface Colors") {
                    ColorRow(name: "Surface Card", color: .theme.surfaceCard)
                    ColorRow(name: "Surface Border", color: .theme.surfaceBorder)
                }
                
                Section("Neutral Colors") {
                    ColorRow(name: "Neutral Black", color: .theme.neutralBlack)
                    ColorRow(name: "Neutral White", color: .theme.neutralWhite)
                    ColorRow(name: "Neutral Gray", color: .theme.neutralGray)
                }
            }
            .navigationTitle("Color System")
        }
        .environment(\.colorScheme, .light)
        .previewDisplayName("Light Mode")


        NavigationView {
            List {
                
                Section("Brand Colors (Dark Mode)") {
                    ColorRow(name: "Primary", color: .theme.primary)
                    ColorRow(name: "Secondary", color: .theme.secondary)
                    ColorRow(name: "Background", color: .theme.background)
                }

                Section("Semantic Colors (Dark Mode)") {
                    ColorRow(name: "Success", color: .theme.success)
                    ColorRow(name: "Warning", color: .theme.warning)
                    ColorRow(name: "Error", color: .theme.error)
                    ColorRow(name: "Info", color: .theme.info)
                }

                Section("Text Colors (Dark Mode)") {
                    ColorRow(name: "Text Primary", color: .theme.textPrimary)
                    ColorRow(name: "Text Secondary", color: .theme.textSecondary)
                    ColorRow(name: "Text Tertiary", color: .theme.textTertiary)
                }

                Section("Surface Colors (Dark Mode)") {
                    ColorRow(name: "Surface Card", color: .theme.surfaceCard)
                    ColorRow(name: "Surface Border", color: .theme.surfaceBorder)
                }
                
                Section("Neutral Colors (Dark Mode)") {
                    ColorRow(name: "Neutral Black", color: .theme.neutralBlack)
                    ColorRow(name: "Neutral White", color: .theme.neutralWhite)
                    ColorRow(name: "Neutral Gray", color: .theme.neutralGray)
                }
            }
            .navigationTitle("Color System - Dark")
        }
        .environment(\.colorScheme, .dark)
        .previewDisplayName("Dark Mode")
        
    }

    
    
    struct ColorRow: View {
        let name: String
        let color: Color

        var body: some View {
            HStack {
                RoundedRectangle(cornerRadius: 8)
                    .fill(color)
                    .frame(width: 50, height: 50)
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(Color.theme.surfaceBorder, lineWidth: 1)
                    )

                Text(name)
                    .font(.body)

                Spacer()
            }
            .padding(.vertical, 4)
        }
    }
}
#endif
