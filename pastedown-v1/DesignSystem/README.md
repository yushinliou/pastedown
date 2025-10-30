# Pastedown Design System

A comprehensive, modular design system for the Pastedown iOS app with full dark/light mode support.

## 📁 Structure

```
DesignSystem/
├── AppColors.swift          # Color palette and semantic colors
├── AppTypography.swift      # Font system with semantic naming
├── AppSpacing.swift         # Spacing and corner radius values
├── AppButtonStyles.swift    # 5 button style variants
├── AppCardStyles.swift      # Card/container styles
├── AppInputStyles.swift     # Text field and editor styles
└── README.md               # This file
```

## 🎨 Colors

### Usage

```swift
// Access via Color.theme.*
Text("Hello")
    .foregroundColor(.theme.primary)
    .background(.theme.background)
```

### Available Colors

#### Brand Colors
- `.theme.primary` - Primary brand color (adaptive)
- `.theme.secondary` - Secondary brand color
- `.theme.background` - Main background

#### Semantic Colors
- `.theme.success` - Success states (green)
- `.theme.warning` - Warning states (orange)
- `.theme.error` - Error states (red)
- `.theme.info` - Informational (blue)

#### Text Colors
- `.theme.textPrimary` - Main text
- `.theme.textSecondary` - Secondary text (60% opacity)
- `.theme.textTertiary` - Tertiary text (40% opacity)

#### Surface Colors
- `.theme.surfaceCard` - Card backgrounds
- `.theme.surfaceBorder` - Border colors

#### Background Colors (with opacity)
- `.theme.successBackground` - Light green background
- `.theme.warningBackground` - Light orange background
- `.theme.errorBackground` - Light red background
- `.theme.infoBackground` - Light blue background

## 🔤 Typography

### Usage

```swift
// Via Font.app.*
Text("Display Text")
    .font(.app.display)

// Via view modifiers
Text("Heading")
    .headingStyle()  // Includes color

// With custom color
Text("Custom")
    .titleStyle(color: .theme.secondary)
```

### Font Scale

| Style | Size | Weight | Usage |
|-------|------|--------|-------|
| `display` | 28pt | Bold | Large titles, hero text |
| `heading` | 22pt | Semibold | Section headers |
| `title` | 18pt | Semibold | Card titles |
| `body` | 16pt | Regular | Paragraph text |
| `callout` | 14pt | Medium | Labels, emphasized info |
| `caption` | 12pt | Regular | Small text, hints |
| `monoBody` | 16pt | Regular (Mono) | Code display |

### Weight Variants

Each style has weight variants (e.g., `.app.bodyMedium`, `.app.bodySemibold`)

## 📏 Spacing & Layout

### Spacing Values

```swift
AppSpacing.xxs  // 4pt
AppSpacing.xs   // 8pt
AppSpacing.sm   // 12pt
AppSpacing.md   // 16pt (default)
AppSpacing.lg   // 24pt
AppSpacing.xl   // 32pt
AppSpacing.xxl  // 48pt
```

### Usage

```swift
// Direct values
VStack(spacing: AppSpacing.lg) { }

// View extensions
Text("Hello")
    .paddingMD()       // 16pt all sides
    .paddingLG()       // 24pt all sides
```

### Corner Radius

```swift
AppRadius.xs    // 4pt
AppRadius.sm    // 8pt
AppRadius.md    // 12pt (default)
AppRadius.lg    // 16pt
AppRadius.xl    // 24pt
AppRadius.full  // Pill shape
```

### Usage

```swift
// Direct values
.cornerRadius(AppRadius.md)

// View extensions
Rectangle()
    .cornerRadiusMD()
```

## 🔘 Button Styles

### 1. Primary Button

Main call-to-action buttons with filled background.

```swift
Button("Save Changes") { }
    .buttonStyle(.primary)

// Full width
Button("Continue") { }
    .buttonStyle(.primary(fullWidth: true))

// With icon
Button(action: {}) {
    HStack {
        Image(systemName: "checkmark")
        Text("Confirm")
    }
}
.buttonStyle(.primary)
```

### 2. Secondary Button

Alternative actions with outlined style.

```swift
Button("Learn More") { }
    .buttonStyle(.secondary)

Button("Options") { }
    .buttonStyle(.secondary(fullWidth: true))
```

### 3. Tertiary Button

Subtle actions with minimal background.

```swift
Button("Cancel") { }
    .buttonStyle(.tertiary)

HStack {
    Button("Skip") { }.buttonStyle(.tertiary)
    Button("Next") { }.buttonStyle(.tertiary)
}
```

### 4. Destructive Button

Delete or warning actions with error color.

```swift
Button("Delete Item") { }
    .buttonStyle(.destructive)

Button("Remove All") { }
    .buttonStyle(.destructive(fullWidth: true))
```

### 5. Ghost Button

Minimal, transparent buttons.

```swift
Button("Dismiss") { }
    .buttonStyle(.ghost)

// With custom color
Button("Info") { }
    .buttonStyle(.ghost(color: .theme.info))
```

## 🎴 Card Styles

### Basic Card Variants

```swift
// Standard card (subtle shadow)
VStack { /* content */ }
    .cardStandard()

// Bordered card (no shadow)
VStack { /* content */ }
    .cardBordered()

// Elevated card (prominent shadow)
VStack { /* content */ }
    .cardElevated()

// Flat card (no shadow or border)
VStack { /* content */ }
    .cardFlat()

// Custom card
VStack { /* content */ }
    .cardStyle(.standard, padding: AppSpacing.lg, cornerRadius: AppRadius.lg)
```

### Semantic Cards

```swift
// Info card
InfoCard(icon: "info.circle.fill", iconColor: .theme.info) {
    Text("Information message")
}

// Success card
SuccessCard {
    Text("Operation successful!")
}

// Warning card
WarningCard {
    Text("Please review")
}

// Error card
ErrorCard {
    Text("Something went wrong")
}
```

## ✏️ Input Styles

### Text Fields

```swift
// Basic text field
TextField("Username", text: $username)
    .textFieldStyle()

// Error state
TextField("Email", text: $email)
    .textFieldStyle(isError: true)
```

### Text Editor

```swift
// Basic text editor
TextEditor(text: $notes)
    .textEditorStyle(minHeight: 120)

// Error state
TextEditor(text: $content)
    .textEditorStyle(isError: true, minHeight: 100)
```

### Form Field Component

```swift
// With label and helper text
FormField(
    label: "Username",
    isRequired: true,
    helperText: "Choose a unique username"
) {
    TextField("Enter username", text: $username)
        .textFieldStyle()
}

// With error message
FormField(
    label: "Email",
    errorMessage: "Invalid email format"
) {
    TextField("Enter email", text: $email)
        .textFieldStyle(isError: true)
}
```

### Search Field

```swift
SearchField(text: $searchQuery) {
    print("Search cleared")
}

// Custom placeholder
SearchField(text: $searchQuery, placeholder: "Search templates...")
```

## 📱 Example Usage

### Complete Form Example

```swift
VStack(spacing: AppSpacing.lg) {
    Text("Settings")
        .font(.app.display)
        .foregroundColor(.theme.textPrimary)

    FormField(label: "Name", isRequired: true) {
        TextField("Your name", text: $name)
            .textFieldStyle()
    }

    FormField(label: "Bio", helperText: "Tell us about yourself") {
        TextEditor(text: $bio)
            .textEditorStyle(minHeight: 100)
    }

    HStack(spacing: AppSpacing.md) {
        Button("Cancel") { }
            .buttonStyle(.tertiary)

        Button("Save") { }
            .buttonStyle(.primary(fullWidth: true))
    }
}
.padding(AppSpacing.lg)
```

### Card with Content Example

```swift
VStack(alignment: .leading, spacing: AppSpacing.md) {
    Text("Template")
        .font(.app.title)

    Text("Convert clipboard content to markdown format")
        .font(.app.callout)
        .foregroundColor(.theme.textSecondary)

    Button("Use Template") { }
        .buttonStyle(.secondary)
}
.cardStandard()
```

## 🌓 Dark Mode Support

All colors automatically adapt to dark/light mode:
- Colors defined in Assets.xcassets with appearance variants
- No code changes needed for dark mode
- Preview both modes in Xcode with environment overrides

## 🔄 Migration from Old Code

### Colors

```swift
// OLD
.foregroundColor(Color("primaryColour"))
.background(Color.blue)

// NEW
.foregroundColor(.theme.primary)
.background(.theme.info)
```

### Typography

```swift
// OLD
.font(.system(size: 16, weight: .medium))

// NEW
.font(.app.bodyMedium)
// or
.bodyStyle()
```

### Spacing

```swift
// OLD
.padding(16)
.padding(.vertical, 12)

// NEW
.padding(AppSpacing.md)
.padding(.vertical, AppSpacing.sm)
// or
.paddingMD()
```

### Buttons

```swift
// OLD
Button("Action") { }
    .foregroundColor(.blue)
    .padding()
    .background(Color.blue.opacity(0.1))
    .cornerRadius(8)

// NEW
Button("Action") { }
    .buttonStyle(.secondary)
```

## 📋 Best Practices

1. **Always use design system values** instead of hardcoded numbers
2. **Prefer semantic colors** over hardcoded colors
3. **Use view modifiers** for consistent styling
4. **Test in both light and dark mode**
5. **Use spacing constants** for consistent layouts
6. **Leverage button styles** instead of custom styling
7. **Use card styles** for grouped content

## 🎯 Quick Reference

```swift
// Colors
.theme.primary, .secondary, .background
.theme.success, .warning, .error, .info
.theme.textPrimary, .textSecondary, .textTertiary

// Typography
.app.display, .heading, .title, .body, .callout, .caption
.displayStyle(), .headingStyle(), .bodyStyle()

// Spacing
AppSpacing.xs(8), .sm(12), .md(16), .lg(24), .xl(32)
.paddingMD(), .paddingLG()

// Radius
AppRadius.sm(8), .md(12), .lg(16), .xl(24)
.cornerRadiusMD()

// Buttons
.primary, .secondary, .tertiary, .destructive, .ghost

// Cards
.cardStandard(), .cardBordered(), .cardElevated()

// Inputs
.textFieldStyle(), .textEditorStyle()
FormField, SearchField
```

## 🔍 Previews

Each design system file includes SwiftUI previews for visual reference:
- `AppColors_Previews` - View all colors
- `AppTypography_Previews` - View all font styles
- `AppSpacing_Previews` - View spacing scale
- `AppButtonStyles_Previews` - View all button styles
- `AppCardStyles_Previews` - View all card variants
- `AppInputStyles_Previews` - View all input styles

Open these files in Xcode and use the Preview pane to explore the design system visually.
