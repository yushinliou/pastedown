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
            return .theme.inputFieldBorderFocus
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
            return 1
        } else if !text.isEmpty || isFocused {
            return 0.5
        } else {
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
            return .theme.inputFieldBorderFocus
        } else {
            return .theme.surfaceBorder
        }
    }

    private var borderWidth: CGFloat {
        if isError || isFocused {
            return 1.5
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

// MARK: - Focused Field Style Modifier
struct FocusedFieldStyle: ViewModifier {
    let isFocused: Bool

    func body(content: Content) -> some View {
        content
            .padding(AppSpacing.sm)
            .background(isFocused ? Color.theme.inputFieldSurfaceFocus : Color.theme.surfaceCard)
            .cornerRadius(AppRadius.sm)
            .overlay(
                RoundedRectangle(cornerRadius: AppRadius.sm)
                    .stroke(isFocused ? Color.theme.inputFieldBorderFocus : .clear, lineWidth: 2)
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

    /// Apply focused field style with border and background
    /// - Parameter isFocused: Whether the field is currently focused
    func focusedFieldStyle(isFocused: Bool) -> some View {
        self.modifier(FocusedFieldStyle(isFocused: isFocused))
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


// MARK: - Preview
#if DEBUG
struct AppInputStyles_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: AppSpacing.xl) {
                    // Text Fields
                    Group {
                        Text("Text Fields")
                            .font(.app.heading)

                        // VStack(alignment: .leading, spacing: AppSpacing.sm) {
                        //     Text("Normal")
                        //         .font(.app.callout)
                        //     TextField("Normal state", text: .constant(""))
                        //         .textFieldStyle()
                        // }

                        // VStack(alignment: .leading, spacing: AppSpacing.sm) {
                        //     Text("Error")
                        //         .font(.app.callout)
                        //     TextField("Error state", text: .constant("Invalid"))
                        //         .textFieldStyle(isError: true)
                        // }

                        // VStack(alignment: .leading, spacing: AppSpacing.sm) {
                        //     Text("Disabled")
                        //         .font(.app.callout)
                        //     TextField("Disabled state", text: .constant("Read only"))
                        //         .textFieldStyle()
                        //         .disabled(true)
                        //         .opacity(0.6)
                        // }
                    }

                    // Divider()

                    // // Text Editor
                    // Group {
                    //     Text("Text Editor")
                    //         .font(.app.heading)

                    //     VStack(alignment: .leading, spacing: AppSpacing.sm) {
                    //         Text("Normal")
                    //             .font(.app.callout)
                    //         TextEditor(text: .constant("Sample text content..."))
                    //             .textEditorStyle(minHeight: 120)
                    //     }

                    //     VStack(alignment: .leading, spacing: AppSpacing.sm) {
                    //         Text("Error")
                    //             .font(.app.callout)
                    //         TextEditor(text: .constant("Too short"))
                    //             .textEditorStyle(isError: true, minHeight: 100)
                    //     }
                    // }

                    Divider()

                    // Preview Text
                    Group {
                        Text("Preview Text")
                            .font(.app.heading)

                        PreviewText(preview: "example-file-name.md")
                        PreviewText(preview: "![alt text](images/example.png)")
                    }

                    Divider()

                    // Custom Menu
                    Group {
                        Text("Custom Menu")
                            .font(.app.heading)

                        CustomMenuLabel(text: "Select an option")
                    }
                }
                .padding(AppSpacing.lg)
            }
            .navigationTitle("Input Styles")
        }
    }
}
#endif
