//
//  AppCardStyles.swift
//  pastedown-v1
//
//  Design System - Card Styles
//  Reusable card/container styles with consistent padding, radius, and shadows
//

import SwiftUI

// MARK: - Card Style Variants
enum CardVariant {
    case standard    // Basic card with subtle shadow
    case bordered    // Card with border, no shadow
    case elevated    // Card with prominent shadow
    case flat        // Card with no shadow or border
}

// MARK: - Card Style Modifier
struct CardStyle: ViewModifier {
    let variant: CardVariant
    let padding: CGFloat
    let cornerRadius: CGFloat

    func body(content: Content) -> some View {
        switch variant {
        case .standard:
            content
                .padding(padding)
                .background(Color.theme.surfaceCard)
                .cornerRadius(cornerRadius)
                .shadow(color: .black.opacity(0.08), radius: 8, x: 0, y: 2)

        case .bordered:
            content
                .padding(padding)
                .background(Color.theme.surfaceCard)
                .cornerRadius(cornerRadius)
                .overlay(
                    RoundedRectangle(cornerRadius: cornerRadius)
                        .stroke(Color.theme.surfaceBorder, lineWidth: 1)
                )

        case .elevated:
            content
                .padding(padding)
                .background(Color.theme.surfaceCard)
                .cornerRadius(cornerRadius)
                .shadow(color: .black.opacity(0.12), radius: 16, x: 0, y: 4)
                .shadow(color: .black.opacity(0.06), radius: 8, x: 0, y: 2)

        case .flat:
            content
                .padding(padding)
                .background(Color.theme.surfaceCard)
                .cornerRadius(cornerRadius)
        }
    }
}

// MARK: - View Extension for Card Styles
extension View {
    /// Apply standard card style
    /// - Parameters:
    ///   - padding: Inner padding (default: 16pt)
    ///   - cornerRadius: Corner radius (default: 12pt)
    func cardStyle(
        _ variant: CardVariant = .standard,
        padding: CGFloat = AppSpacing.md,
        cornerRadius: CGFloat = AppRadius.md
    ) -> some View {
        self.modifier(CardStyle(variant: variant, padding: padding, cornerRadius: cornerRadius))
    }

    /// Apply standard card with default values
    func cardStandard() -> some View {
        self.cardStyle(.standard)
    }

    /// Apply bordered card
    func cardBordered() -> some View {
        self.cardStyle(.bordered)
    }

    /// Apply elevated card
    func cardElevated() -> some View {
        self.cardStyle(.elevated)
    }

    /// Apply flat card (no shadow)
    func cardFlat() -> some View {
        self.cardStyle(.flat)
    }
}

// MARK: - Semantic Card Components

/// Info Card with icon and content
struct InfoCard<Content: View>: View {
    let icon: String
    let iconColor: Color
    let content: Content

    init(
        icon: String,
        iconColor: Color = .theme.info,
        @ViewBuilder content: () -> Content
    ) {
        self.icon = icon
        self.iconColor = iconColor
        self.content = content()
    }

    var body: some View {
        HStack(alignment: .top, spacing: AppSpacing.sm) {
            Image(systemName: icon)
                .font(.app.title)
                .foregroundColor(iconColor)

            content
        }
        .cardStyle(.bordered)
    }
}

/// Success Card
struct SuccessCard<Content: View>: View {
    let content: Content

    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    var body: some View {
        HStack(spacing: AppSpacing.sm) {
            Image(systemName: "checkmark.circle.fill")
                .font(.app.title)
                .foregroundColor(.theme.success)

            content
        }
        .padding(AppSpacing.md)
        .background(Color.theme.successBackground)
        .cornerRadius(AppRadius.md)
        .overlay(
            RoundedRectangle(cornerRadius: AppRadius.md)
                .stroke(Color.theme.success.opacity(0.3), lineWidth: 1)
        )
    }
}

/// Warning Card
struct WarningCard<Content: View>: View {
    let content: Content

    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    var body: some View {
        HStack(spacing: AppSpacing.sm) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.app.title)
                .foregroundColor(.theme.warning)

            content
        }
        .padding(AppSpacing.md)
        .background(Color.theme.warningBackground)
        .cornerRadius(AppRadius.md)
        .overlay(
            RoundedRectangle(cornerRadius: AppRadius.md)
                .stroke(Color.theme.warning.opacity(0.3), lineWidth: 1)
        )
    }
}

/// Error Card
struct ErrorCard<Content: View>: View {
    let content: Content

    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    var body: some View {
        HStack(spacing: AppSpacing.sm) {
            Image(systemName: "xmark.circle.fill")
                .font(.app.title)
                .foregroundColor(.theme.error)

            content
        }
        .padding(AppSpacing.md)
        .background(Color.theme.errorBackground)
        .cornerRadius(AppRadius.md)
        .overlay(
            RoundedRectangle(cornerRadius: AppRadius.md)
                .stroke(Color.theme.error.opacity(0.3), lineWidth: 1)
        )
    }
}

// MARK: - Preview
#if DEBUG
struct AppCardStyles_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: AppSpacing.lg) {
                    // Standard Cards
                    Group {
                        Text("Card Variants")
                            .font(.app.heading)

                        VStack(alignment: .leading, spacing: AppSpacing.md) {
                            Text("Standard Card")
                                .font(.app.title)
                            Text("Basic card with subtle shadow for general use.")
                                .font(.app.callout)
                                .foregroundColor(.theme.textSecondary)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .cardStandard()

                        VStack(alignment: .leading, spacing: AppSpacing.md) {
                            Text("Bordered Card")
                                .font(.app.title)
                            Text("Card with border, no shadow. Good for grouped content.")
                                .font(.app.callout)
                                .foregroundColor(.theme.textSecondary)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .cardBordered()

                        VStack(alignment: .leading, spacing: AppSpacing.md) {
                            Text("Elevated Card")
                                .font(.app.title)
                            Text("Prominent shadow for important content or modals.")
                                .font(.app.callout)
                                .foregroundColor(.theme.textSecondary)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .cardElevated()

                        VStack(alignment: .leading, spacing: AppSpacing.md) {
                            Text("Flat Card")
                                .font(.app.title)
                            Text("No shadow or border. Minimal style.")
                                .font(.app.callout)
                                .foregroundColor(.theme.textSecondary)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .cardFlat()
                    }

                    Divider()

                    // Semantic Cards
                    Group {
                        Text("Semantic Cards")
                            .font(.app.heading)

                        InfoCard(icon: "info.circle.fill") {
                            VStack(alignment: .leading, spacing: AppSpacing.xxs) {
                                Text("Info Card")
                                    .font(.app.titleMedium)
                                Text("Informational message with icon")
                                    .font(.app.callout)
                                    .foregroundColor(.theme.textSecondary)
                            }
                        }

                        SuccessCard {
                            VStack(alignment: .leading, spacing: AppSpacing.xxs) {
                                Text("Success")
                                    .font(.app.titleMedium)
                                Text("Operation completed successfully")
                                    .font(.app.callout)
                                    .foregroundColor(.theme.textSecondary)
                            }
                        }

                        WarningCard {
                            VStack(alignment: .leading, spacing: AppSpacing.xxs) {
                                Text("Warning")
                                    .font(.app.titleMedium)
                                Text("Please review before proceeding")
                                    .font(.app.callout)
                                    .foregroundColor(.theme.textSecondary)
                            }
                        }

                        ErrorCard {
                            VStack(alignment: .leading, spacing: AppSpacing.xxs) {
                                Text("Error")
                                    .font(.app.titleMedium)
                                Text("Something went wrong")
                                    .font(.app.callout)
                                    .foregroundColor(.theme.textSecondary)
                            }
                        }
                    }
                }
                .padding(AppSpacing.lg)
            }
            .navigationTitle("Card Styles")
        }
    }
}
#endif
