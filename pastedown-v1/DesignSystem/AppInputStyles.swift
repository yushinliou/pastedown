//
//  AppInputStyles.swift
//  pastedown-v1
//
//  Design System - Input Styles
//  Consistent TextField and TextEditor styles with focus and error states
//

import SwiftUI

// MARK: - Text Field Style Modifier
struct StandardTextFieldStyle: ViewModifier {
    @FocusState private var isFocused: Bool
    let isError: Bool

    func body(content: Content) -> some View {
        content
            .font(.app.body)
            .foregroundColor(.theme.textPrimary)
            .padding(AppSpacing.sm)
            .background(Color.theme.surfaceCard)
            .cornerRadius(AppRadius.sm)
            .overlay(
                RoundedRectangle(cornerRadius: AppRadius.sm)
                    .stroke(borderColor, lineWidth: borderWidth)
            )
            .focused($isFocused)
    }

    private var borderColor: Color {
        if isError {
            return .theme.error
        } else if isFocused {
            return .theme.primary
        } else {
            return .theme.surfaceBorder
        }
    }

    private var borderWidth: CGFloat {
        if isError || isFocused {
            return 2
        } else {
            return 1
        }
    }
}




// MARK: - Subtle Text Field Style (for Template Name)
struct SubtleTextFieldStyle: ViewModifier {
    @Binding var text: String
    let isError: Bool
    @State private var isFocused: Bool = false

    func body(content: Content) -> some View {
        content
            .font(.app.body)
            .foregroundColor(.theme.textPrimary)
            .padding(AppSpacing.sm)
            .background(Color.theme.surfaceCard)
            .cornerRadius(AppRadius.sm)
            .overlay(
                RoundedRectangle(cornerRadius: AppRadius.sm)
                    .stroke(borderColor, lineWidth: borderWidth)
            )
            .onTapGesture {
                isFocused = true
            }
            .onChange(of: text) { _ in
                isFocused = true
            }
    }

    private var borderColor: Color {
        if isError {
            return .theme.error
        } else if !text.isEmpty {
            return Color.gray.opacity(0.3)
        } else {
            return .clear
        }
    }

    private var borderWidth: CGFloat {
        if isError {
            print("Error state border width 2")
            return 2
        } else if !text.isEmpty || isFocused {
            print("Non-empty state border width 1")
            return 1
        } else {
            print("Empty state border width 0")
            return 0
        }
    }
}

// MARK: - Text Editor Style Modifier
struct StandardTextEditorStyle: ViewModifier {
    @FocusState private var isFocused: Bool
    let isError: Bool
    let minHeight: CGFloat

    func body(content: Content) -> some View {
        content
            .font(.app.body)
            .foregroundColor(.theme.textPrimary)
            .padding(AppSpacing.sm)
            .frame(minHeight: minHeight)
            .background(Color.theme.surfaceCard)
            .cornerRadius(AppRadius.sm)
            .overlay(
                RoundedRectangle(cornerRadius: AppRadius.sm)
                    .stroke(borderColor, lineWidth: borderWidth)
            )
            .focused($isFocused)
    }

    private var borderColor: Color {
        if isError {
            return .theme.error
        } else if isFocused {
            return .theme.primary
        } else {
            return .theme.surfaceBorder
        }
    }

    private var borderWidth: CGFloat {
        if isError || isFocused {
            return 2
        } else {
            return 1
        }
    }
}

// MARK: - View Extensions for Input Styles
extension View {
    /// Apply standard text field style
    /// - Parameter isError: Show error state with red border
    func textFieldStyle(isError: Bool = false) -> some View {
        self.modifier(StandardTextFieldStyle(isError: isError))
    }

    /// Apply subtle text field style (no border when empty, grey border when typing)
    /// - Parameters:
    ///   - text: Binding to the text value
    ///   - isError: Show error state with red border
    func subtleTextFieldStyle(text: Binding<String>, isError: Bool = false) -> some View {
        self.modifier(SubtleTextFieldStyle(text: text, isError: isError))
    }

    /// Apply standard text editor style
    /// - Parameters:
    ///   - isError: Show error state with red border
    ///   - minHeight: Minimum height (default: 100pt)
    func textEditorStyle(isError: Bool = false, minHeight: CGFloat = 100) -> some View {
        self.modifier(StandardTextEditorStyle(isError: isError, minHeight: minHeight))
    }
}

// MARK: - Styled Form Field Component
struct FormField<Content: View>: View {
    let label: String
    let isRequired: Bool
    let errorMessage: String?
    let helperText: String?
    let content: Content

    init(
        label: String,
        isRequired: Bool = false,
        errorMessage: String? = nil,
        helperText: String? = nil,
        @ViewBuilder content: () -> Content
    ) {
        self.label = label
        self.isRequired = isRequired
        self.errorMessage = errorMessage
        self.helperText = helperText
        self.content = content()
    }

    var body: some View {
        VStack(alignment: .leading, spacing: AppSpacing.xs) {
            // Label
            HStack(spacing: AppSpacing.xxs) {
                Text(label)
                    .font(.app.calloutSemibold)
                    .foregroundColor(.theme.textPrimary)

                if isRequired {
                    Text("*")
                        .font(.app.calloutSemibold)
                        .foregroundColor(.theme.error)
                }
            }

            // Content (TextField or TextEditor)
            content

            // Error or Helper Text
            if let errorMessage = errorMessage {
                HStack(spacing: AppSpacing.xxs) {
                    Image(systemName: "exclamationmark.circle.fill")
                        .font(.app.caption)
                    Text(errorMessage)
                        .font(.app.caption)
                }
                .foregroundColor(.theme.error)
            } else if let helperText = helperText {
                Text(helperText)
                    .font(.app.caption)
                    .foregroundColor(.theme.textSecondary)
            }
        }
    }
}

struct SecondaryMenuPickerStyle: ViewModifier {
    @Environment(\.colorScheme) var colorScheme
    @State private var isPressed = false

    func body(content: Content) -> some View {
        content
            .tint(Color.theme.neutralBlack)
            .font(.app.bodyMedium)
            .foregroundColor(Color.theme.neutralBlack)
            .padding(.horizontal, AppSpacing.sm)
            .padding(.vertical, AppSpacing.xs)
            .background(
                RoundedRectangle(cornerRadius: AppRadius.lg)
                    .fill(Color.theme.neutralWhite)
                    .shadow(color: .black.opacity(isPressed ? 0.1 : 0.15),
                            radius: isPressed ? 2 : 4,
                            x: isPressed ? -1 : 4,
                            y: isPressed ? -1 : 4)
            )
            .scaleEffect(isPressed ? 0.97 : 1.0)
            .animation(.easeInOut(duration: 0.2), value: isPressed)
            .onLongPressGesture(minimumDuration: 0.01, pressing: { pressing in
                withAnimation(.easeInOut(duration: 0.15)) {
                    isPressed = pressing
                }
            }, perform: {})
    }
}

// MARK: - Full Width Picker Style
struct FullWidthPickerStyle: ViewModifier {
    @Environment(\.colorScheme) var colorScheme

    func body(content: Content) -> some View {
        content
            .tint(Color.theme.textPrimary)
            .font(.app.body)
            .foregroundColor(Color.theme.textPrimary)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, AppSpacing.xs)
            .padding(.vertical, AppSpacing.xs)
            .background(
                RoundedRectangle(cornerRadius: AppRadius.sm)
                    .fill(colorScheme == .dark ? Color.gray.opacity(0.3) : Color.gray.opacity(0.15))
            )
    }
}

// MARK: - Custom Menu Button Label
struct CustomMenuLabel: View {
    let text: String
    @Environment(\.colorScheme) var colorScheme

    var body: some View {
        HStack {
            Text(text)
                .font(.app.body)
                .foregroundColor(.theme.textPrimary)
                .frame(maxWidth: .infinity, alignment: .leading)

            Image(systemName: "chevron.up.chevron.down")
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(.theme.textSecondary)
        }
        .padding(.horizontal, AppSpacing.sm)
        .padding(.vertical, AppSpacing.sm)
        .background(
            RoundedRectangle(cornerRadius: AppRadius.sm)
                .fill(colorScheme == .dark ? Color.gray.opacity(0.3) : Color.gray.opacity(0.15))
        )
    }
}


extension View {
    /// Apply secondary menu picker style to match button appearance
    func secondaryPickerStyle() -> some View {
        self.modifier(SecondaryMenuPickerStyle())
    }

    /// Apply full-width picker style with light/dark mode support
    func fullWidthPickerStyle() -> some View {
        self.modifier(FullWidthPickerStyle())
    }
}

// MARK: - Preview Text Component
struct PreviewText: View {
    let label: String
    let preview: String
    @Environment(\.colorScheme) var colorScheme

    init(label: String = "", preview: String) {
        self.label = label
        self.preview = preview
    }

    var body: some View {
        VStack(alignment: .leading) {
            // Text(label)
            //     .font(.app.captionMedium)
            //     .foregroundColor(.theme.textSecondary)
            Text(preview)
                .font(.app.caption)
                .foregroundColor(colorScheme == .dark ? .white : .black)
                .padding(.horizontal, AppSpacing.xs) // for text grey bg
                .padding(.vertical, AppSpacing.xxs) // for text grey bg 
                .background(colorScheme == .dark ? Color.gray.opacity(0.3) : Color.gray.opacity(0.15))
                .cornerRadius(AppRadius.lg)
        }
        .padding(.bottom, AppSpacing.sm)
    }
}

// MARK: - Search Field Component
struct SearchField: View {
    @Binding var text: String
    let placeholder: String
    let onClear: (() -> Void)?

    init(
        text: Binding<String>,
        placeholder: String = "Search...",
        onClear: (() -> Void)? = nil
    ) {
        self._text = text
        self.placeholder = placeholder
        self.onClear = onClear
    }

    var body: some View {
        HStack(spacing: AppSpacing.xs) {
            Image(systemName: "magnifyingglass")
                .foregroundColor(.theme.textSecondary)
                .font(.app.body)

            TextField(placeholder, text: $text)
                .font(.app.body)
                .foregroundColor(.theme.textPrimary)

            if !text.isEmpty {
                Button(action: {
                    text = ""
                    onClear?()
                }) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.theme.textSecondary)
                        .font(.app.body)
                }
            }
        }
        .padding(AppSpacing.sm)
        .background(Color.theme.surfaceCard)
        .cornerRadius(AppRadius.md)
        .overlay(
            RoundedRectangle(cornerRadius: AppRadius.md)
                .stroke(Color.theme.surfaceBorder, lineWidth: 1)
        )
    }
}

// MARK: - Preview
#if DEBUG
struct AppInputStyles_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: AppSpacing.xl) {
                    // Basic Text Fields
                    Group {
                        Text("Text Fields")
                            .font(.app.heading)

                        FormField(label: "Username", isRequired: true, helperText: "Enter your username") {
                            TextField("Enter username", text: .constant(""))
                                .textFieldStyle()
                        }

                        FormField(label: "Email", errorMessage: "Invalid email format") {
                            TextField("Enter email", text: .constant("invalid@"))
                                .textFieldStyle(isError: true)
                        }

                        FormField(label: "Optional Field") {
                            TextField("Optional input", text: .constant(""))
                                .textFieldStyle()
                        }
                    }

                    Divider()

                    // Text Editor
                    Group {
                        Text("Text Editor")
                            .font(.app.heading)

                        FormField(
                            label: "Description",
                            isRequired: true,
                            helperText: "Provide a detailed description"
                        ) {
                            TextEditor(text: .constant("Sample text content..."))
                                .textEditorStyle(minHeight: 120)
                        }

                        FormField(
                            label: "Notes",
                            errorMessage: "Content is too short"
                        ) {
                            TextEditor(text: .constant("Too short"))
                                .textEditorStyle(isError: true, minHeight: 100)
                        }
                    }

                    Divider()

                    // Search Field
                    Group {
                        Text("Search Field")
                            .font(.app.heading)

                        SearchFieldExample()
                    }

                    Divider()

                    // Different States
                    Group {
                        Text("Input States")
                            .font(.app.heading)

                        VStack(alignment: .leading, spacing: AppSpacing.sm) {
                            Text("Normal")
                                .font(.app.callout)
                            TextField("Normal state", text: .constant(""))
                                .textFieldStyle()
                        }

                        VStack(alignment: .leading, spacing: AppSpacing.sm) {
                            Text("Error")
                                .font(.app.callout)
                            TextField("Error state", text: .constant("Invalid"))
                                .textFieldStyle(isError: true)
                        }

                        VStack(alignment: .leading, spacing: AppSpacing.sm) {
                            Text("Disabled")
                                .font(.app.callout)
                            TextField("Disabled state", text: .constant("Read only"))
                                .textFieldStyle()
                                .disabled(true)
                                .opacity(0.6)
                        }
                    }
                }
                .padding(AppSpacing.lg)
            }
            .navigationTitle("Input Styles")
        }
    }

    struct SearchFieldExample: View {
        @State private var searchText = ""

        var body: some View {
            VStack(alignment: .leading, spacing: AppSpacing.sm) {
                SearchField(text: $searchText) {
                    print("Search cleared")
                }

                if !searchText.isEmpty {
                    Text("Searching for: \(searchText)")
                        .font(.app.caption)
                        .foregroundColor(.theme.textSecondary)
                }
            }
        }
    }
}
#endif
