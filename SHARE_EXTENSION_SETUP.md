# Share Extension Setup Instructions

This guide will help you add a Share Extension to your Pastedown app, allowing users to share content from Apple Notes (and other apps) directly to your app for automatic markdown conversion.

## 1. Add Share Extension Target in Xcode

1. **Open your project** in Xcode (`pastedown-v1.xcodeproj`)

2. **Add a new target:**
   - File → New → Target...
   - Choose "Share Extension" from the Application Extension section
   - Click "Next"

3. **Configure the extension:**
   - Product Name: `PastedownShareExtension`
   - Bundle Identifier: `Yu-shin.pastedown-v1.PastedownShareExtension`
   - Language: Swift
   - Use Storyboard: Yes
   - Click "Finish"
   - When asked about activating scheme, click "Cancel" (we'll configure manually)

## 2. Replace Generated Files

After creating the target, replace the generated files with the ones I've created:

1. **Replace `ShareViewController.swift`** with the file at:
   `/Users/liuyuxin/Programming/pastedown-v1/PastedownShareExtension/ShareViewController.swift`

2. **Replace `MainInterface.storyboard`** with the file at:
   `/Users/liuyuxin/Programming/pastedown-v1/PastedownShareExtension/MainInterface.storyboard`

3. **Replace `Info.plist`** with the file at:
   `/Users/liuyuxin/Programming/pastedown-v1/PastedownShareExtension/Info.plist`

4. **Add `SharedSettingsManager.swift`** to both targets:
   - Add the file at `/Users/liuyuxin/Programming/pastedown-v1/PastedownShareExtension/SharedSettingsManager.swift`
   - In Target Membership, check both "pastedown-v1" and "PastedownShareExtension"

## 3. Add Shared Files to Extension Target

The Share Extension needs access to your existing model and utility classes. In Xcode:

1. **Select these files** and add them to the Share Extension target (check the target membership):

   **Models (Required):**
   - `FrontMatterField.swift`
   - `FrontMatterType.swift`
   - `ImageHandling.swift`
   - `AltTextTemplate.swift`

   **ViewModels (Required):**
   - `SettingsStore.swift`
   - `RichTextProcessor.swift`
   - `ImageAnalyzer.swift`

   **Utilities (Required):**
   - `MarkdownUtilities.swift`
   - `ListUtilities.swift`
   - `TableUtilities.swift`
   - `ImageUtilities.swift`

2. **For each file:**
   - Select the file in Project Navigator
   - In File Inspector (right panel), under "Target Membership"
   - Check the box for "PastedownShareExtension"

## 4. Configure App Groups

App Groups allow the main app and Share Extension to share data.

### 4.1 Enable App Groups Capability

1. **For Main App:**
   - Select your main target "pastedown-v1"
   - Go to "Signing & Capabilities" tab
   - Click "+ Capability" → "App Groups"
   - Click "+" and add: `group.Yu-shin.pastedown`

2. **For Share Extension:**
   - Select "PastedownShareExtension" target
   - Go to "Signing & Capabilities" tab
   - Click "+ Capability" → "App Groups"
   - Click "+" and add: `group.Yu-shin.pastedown`

### 4.2 Configure Apple Developer Account

You'll need to configure this in your Apple Developer account:
1. Go to [developer.apple.com](https://developer.apple.com)
2. Certificates, Identifiers & Profiles → Identifiers
3. Create/edit your main app identifier
4. Enable "App Groups" capability
5. Create/edit your share extension identifier (`Yu-shin.pastedown-v1.PastedownShareExtension`)
6. Enable "App Groups" capability
7. Go to App Groups section and create a new group: `group.Yu-shin.pastedown`

## 5. Update Build Settings

### 5.1 Set iOS Deployment Target
- Select "PastedownShareExtension" target
- Build Settings → iOS Deployment Target: 18.5 (match your main app)

### 5.2 Set Bundle Display Name
- In the Share Extension's `Info.plist`, ensure:
  - `CFBundleDisplayName` is set to "Convert to Markdown"

## 6. Test the Implementation

### 6.1 Build and Run
1. Select the main app scheme "pastedown-v1"
2. Build and run on a device (Share Extensions don't work well in simulator)

### 6.2 Test from Apple Notes
1. Open Apple Notes app
2. Create a note with rich content (text formatting, images, tables)
3. Tap the Share button
4. Look for "Convert to Markdown" in the share sheet
5. Tap it to test the conversion

### 6.3 Test from Safari
1. Open a webpage in Safari
2. Select some text or the entire page
3. Share → "Convert to Markdown"

## 7. Troubleshooting

### Common Issues:

**Share Extension doesn't appear:**
- Verify App Groups are configured correctly
- Check that bundle identifiers match
- Ensure both targets have the same App Group identifier

**Build errors:**
- Make sure all required files are added to Share Extension target
- Check that iOS deployment targets match
- Verify import statements are correct

**Extension crashes:**
- Check that all required model files are included
- Verify shared container access is working
- Check console logs for specific errors

**Content not converting:**
- Verify RichTextProcessor and utilities are working
- Check that content types are supported in Info.plist
- Test with different apps (Notes, Safari, Pages, etc.)

## 8. Advanced Configuration

### 8.1 Customize Supported Content Types

In the Share Extension's `Info.plist`, you can modify `NSExtensionActivationRule` to support different content types:

- `NSExtensionActivationSupportsText`: Text content
- `NSExtensionActivationSupportsWebPageWithMaxCount`: Web pages
- `NSExtensionActivationSupportsImageWithMaxCount`: Images
- `NSExtensionActivationSupportsFileWithMaxCount`: Files

### 8.2 Add Custom Handling

You can extend `ShareViewController.swift` to:
- Add custom UI elements
- Support additional content types
- Provide conversion options in the extension
- Show conversion preview before saving

## 9. App Store Submission Notes

When submitting to the App Store:
- Both main app and extension need valid bundle identifiers
- App Groups must be properly configured in your developer account
- Share Extension will be included automatically with your main app
- Users will see the extension appear in share sheets after installing your app

## Files Created

The following files have been created for your Share Extension:

1. `PastedownShareExtension/ShareViewController.swift` - Main extension logic
2. `PastedownShareExtension/MainInterface.storyboard` - Extension UI
3. `PastedownShareExtension/Info.plist` - Extension configuration
4. `PastedownShareExtension/SharedSettingsManager.swift` - Shared data management
5. Updated `SettingsStore.swift` - Added shared container support

Follow these steps carefully, and you'll have a fully functional Share Extension that allows users to convert content from Apple Notes and other apps directly to Markdown!