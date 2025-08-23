# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

Pastedown-v1 is a SwiftUI iOS application that converts rich text content (including images and tables) from the clipboard into Markdown format. The app processes RTF/RTFD content, handles complex table structures, generates alt text for images, and provides configurable front matter fields.

## Development Commands

### Building and Testing

```bash
# Build the project
xcodebuild -project pastedown-v1.xcodeproj -scheme pastedown-v1 -configuration Debug build

# Run tests
xcodebuild test -project pastedown-v1.xcodeproj -scheme pastedown-v1 -destination 'platform=iOS Simulator,name=iPhone 15'

# Build for release
xcodebuild -project pastedown-v1.xcodeproj -scheme pastedown-v1 -configuration Release build
```

### Running the App

- Open `pastedown-v1.xcodeproj` in Xcode
- Select a simulator or device target
- Press Cmd+R to build and run

## Architecture Overview

### Core Components

**ViewModels**

- `SettingsStore`: Manages app configuration and user preferences with UserDefaults persistence
- `RichTextProcessor`: Main processing engine that converts NSAttributedString to Markdown with table and image support
- `ClipboardService`: Handles clipboard data extraction (RTF, RTFD, HTML, plain text)
- `ImageAnalyzer`: Generates alt text for images using Vision framework

**Models**

- `FrontMatterField`, `FrontMatterType`: Configuration for YAML front matter
- `ImageHandling`, `AltTextTemplate`: Image processing options

**Utilities**

- `MarkdownUtilities`: Text formatting, links, lists, headings, and front matter generation
- `TableUtilities`: Complex RTF table structure parsing and Markdown conversion

**Views**

- `ContentView`: Main app interface with conditional rendering
- `InitialViewWithSettings`: Landing page with paste action
- `Results`: Displays converted Markdown with copy/share options
- `AdvancedSettingsView`: Configuration interface

### Key Technical Features

**Table Processing**: The app uses a sophisticated two-phase approach:

1. RTF structure extraction via `RTFTableStructureParser` 
2. Content extraction from NSAttributedString via `AttributedStringTableContentExtractor`
3. Placeholder insertion and final Markdown replacement

**Image Handling**: Supports multiple modes (ignore, save local, custom folder) with automatic alt text generation using Vision framework

**Rich Text Processing**: Handles complex formatting including bold, italic, links, lists, headings, and maintains nested structure

## Development Guidelines

### Code Organization
- Follow the existing MVVM pattern
- ViewModels should be marked `@MainActor` and conform to `ObservableObject`
- Use dependency injection for ViewModels (see ContentView initialization)
- Utilities should be stateless struct types with static methods

### Table Processing
- When modifying table detection, test with both Apple RTF format and fallback methods
- The `TableUtilities.detectTablesWithPlaceholders` method is the main entry point
- Table content and structure are processed separately for better accuracy

### Settings and Persistence
- All settings are managed through `SettingsStore` with UserDefaults
- New settings require both property declaration and save/load methods
- Settings are automatically saved when modified

### Testing Considerations
- Test table processing with various RTF sources (Pages, Word, etc.)
- Verify image alt text generation works with different image types
- Check front matter generation with different field configurations
- Test clipboard handling with different pasteboard content types

### Performance Notes
- Image alt text generation uses Vision framework and should be async
- Table processing can be CPU intensive for large documents
- RTF parsing is done synchronously but should be fast for typical content

## Target Configuration
- iOS Deployment Target: 18.5
- Swift Version: 5.0
- Development Team: B3699PGRBJ
- Bundle Identifier: Yu-shin.pastedown-v1