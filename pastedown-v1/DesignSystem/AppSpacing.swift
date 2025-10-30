//
//  AppSpacing.swift
//  pastedown-v1
//
//  Design System - Spacing
//  Standardized spacing values for consistent layouts
//

import SwiftUI

// MARK: - Spacing Values
struct AppSpacing {
    /// Extra extra small: 4pt
    /// Usage: Tight element spacing, icon padding
    static let xxs: CGFloat = 4

    /// Extra small: 8pt
    /// Usage: Small gaps, compact layouts
    static let xs: CGFloat = 8

    /// Small: 12pt
    /// Usage: Form field spacing, list items
    static let sm: CGFloat = 12

    /// Medium: 16pt
    /// Usage: Default padding, standard gaps
    static let md: CGFloat = 16

    /// Large: 24pt
    /// Usage: Section spacing, card padding
    static let lg: CGFloat = 24

    /// Extra large: 32pt
    /// Usage: Major section gaps, page padding
    static let xl: CGFloat = 32

    /// Extra extra large: 48pt
    /// Usage: Large dividers, major layout spacing
    static let xxl: CGFloat = 48
}

// MARK: - Corner Radius Values
struct AppRadius {
    /// Extra small: 4pt
    /// Usage: Small buttons, badges
    static let xs: CGFloat = 4

    /// Small: 8pt
    /// Usage: Input fields, small cards
    static let sm: CGFloat = 8

    /// Medium: 12pt
    /// Usage: Buttons, standard cards
    static let md: CGFloat = 12

    /// Large: 16pt
    /// Usage: Large cards, modals
    static let lg: CGFloat = 16

    /// Extra large: 24pt
    /// Usage: Prominent buttons, special components
    static let xl: CGFloat = 24

    /// Full: 999pt (pill shape)
    /// Usage: Pills, fully rounded elements
    static let full: CGFloat = 999
}

// MARK: - View Extensions for Easy Spacing
extension View {
    // MARK: - Padding Extensions

    /// Apply extra extra small padding (4pt) to all edges
    func paddingXXS() -> some View {
        self.padding(AppSpacing.xxs)
    }

    /// Apply extra small padding (8pt) to all edges
    func paddingXS() -> some View {
        self.padding(AppSpacing.xs)
    }

    /// Apply small padding (12pt) to all edges
    func paddingSM() -> some View {
        self.padding(AppSpacing.sm)
    }

    /// Apply medium padding (16pt) to all edges
    func paddingMD() -> some View {
        self.padding(AppSpacing.md)
    }

    /// Apply large padding (24pt) to all edges
    func paddingLG() -> some View {
        self.padding(AppSpacing.lg)
    }

    /// Apply extra large padding (32pt) to all edges
    func paddingXL() -> some View {
        self.padding(AppSpacing.xl)
    }

    /// Apply extra extra large padding (48pt) to all edges
    func paddingXXL() -> some View {
        self.padding(AppSpacing.xxl)
    }

    // MARK: - Corner Radius Extensions

    /// Apply extra small corner radius (4pt)
    func cornerRadiusXS() -> some View {
        self.cornerRadius(AppRadius.xs)
    }

    /// Apply small corner radius (8pt)
    func cornerRadiusSM() -> some View {
        self.cornerRadius(AppRadius.sm)
    }

    /// Apply medium corner radius (12pt)
    func cornerRadiusMD() -> some View {
        self.cornerRadius(AppRadius.md)
    }

    /// Apply large corner radius (16pt)
    func cornerRadiusLG() -> some View {
        self.cornerRadius(AppRadius.lg)
    }

    /// Apply extra large corner radius (24pt)
    func cornerRadiusXL() -> some View {
        self.cornerRadius(AppRadius.xl)
    }

    /// Apply full corner radius (pill shape)
    func cornerRadiusFull() -> some View {
        self.cornerRadius(AppRadius.full)
    }
}

// MARK: - Spacing Stack Extensions
extension VStack {
    /// Create a VStack with standardized spacing
    init(spacing: AppSpacing.Type, alignment: HorizontalAlignment = .center, @ViewBuilder content: () -> Content) {
        self.init(alignment: alignment, spacing: AppSpacing.md, content: content)
    }
}

extension HStack {
    /// Create an HStack with standardized spacing
    init(spacing: AppSpacing.Type, alignment: VerticalAlignment = .center, @ViewBuilder content: () -> Content) {
        self.init(alignment: alignment, spacing: AppSpacing.md, content: content)
    }
}

// MARK: - Preview
#if DEBUG
struct AppSpacing_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: AppSpacing.lg) {
                    // Spacing examples
                    Group {
                        Text("Spacing Scale")
                            .font(.app.heading)

                        VStack(alignment: .leading, spacing: AppSpacing.sm) {
                            SpacingRow(name: "XXS", value: AppSpacing.xxs)
                            SpacingRow(name: "XS", value: AppSpacing.xs)
                            SpacingRow(name: "SM", value: AppSpacing.sm)
                            SpacingRow(name: "MD", value: AppSpacing.md)
                            SpacingRow(name: "LG", value: AppSpacing.lg)
                            SpacingRow(name: "XL", value: AppSpacing.xl)
                            SpacingRow(name: "XXL", value: AppSpacing.xxl)
                        }
                    }

                    Divider()

                    // Corner radius examples
                    Group {
                        Text("Corner Radius")
                            .font(.app.heading)

                        VStack(alignment: .leading, spacing: AppSpacing.sm) {
                            RadiusRow(name: "XS", radius: AppRadius.xs)
                            RadiusRow(name: "SM", radius: AppRadius.sm)
                            RadiusRow(name: "MD", radius: AppRadius.md)
                            RadiusRow(name: "LG", radius: AppRadius.lg)
                            RadiusRow(name: "XL", radius: AppRadius.xl)
                            RadiusRow(name: "Full", radius: AppRadius.full)
                        }
                    }
                }
                .padding(AppSpacing.lg)
            }
            .navigationTitle("Spacing System")
        }
    }

    struct SpacingRow: View {
        let name: String
        let value: CGFloat

        var body: some View {
            HStack {
                Text(name)
                    .font(.app.bodyMedium)
                    .frame(width: 60, alignment: .leading)

                Text("\(Int(value))pt")
                    .font(.app.callout)
                    .foregroundColor(.theme.textSecondary)
                    .frame(width: 50, alignment: .leading)

                Rectangle()
                    .fill(Color.theme.info)
                    .frame(width: value, height: 20)
                    .cornerRadius(4)
            }
        }
    }

    struct RadiusRow: View {
        let name: String
        let radius: CGFloat

        var body: some View {
            HStack {
                Text(name)
                    .font(.app.bodyMedium)
                    .frame(width: 60, alignment: .leading)

                Text("\(radius == AppRadius.full ? "Full" : "\(Int(radius))pt")")
                    .font(.app.callout)
                    .foregroundColor(.theme.textSecondary)
                    .frame(width: 60, alignment: .leading)

                Rectangle()
                    .fill(Color.theme.secondary)
                    .frame(width: 80, height: 40)
                    .cornerRadius(radius == AppRadius.full ? 20 : radius)
            }
        }
    }
}
#endif
