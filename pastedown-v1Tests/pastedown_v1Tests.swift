//
//  pastedown_v1Tests.swift
//  pastedown-v1Tests
//
//  Created by on 2025/6/30.
//

import Testing
import UIKit
@testable import pastedown_v1

struct MarkdownUtilitiesTests {
    
    // MARK: - Helper Methods
    private func createTestSettingsStore(
        imageHandling: ImageHandling = .saveLocal,
        customImageFolder: String = "custom_images",
        frontMatterFields: [FrontMatterField] = []
    ) -> SettingsStore {
        let settings = SettingsStore()
        settings.imageHandling = imageHandling
        settings.customImageFolder = customImageFolder
        settings.frontMatterFields = frontMatterFields
        return settings
    }
    
    private func createTestImage() -> UIImage {
        let size = CGSize(width: 100, height: 100)
        UIGraphicsBeginImageContext(size)
        let context = UIGraphicsGetCurrentContext()
        context?.setFillColor(UIColor.red.cgColor)
        context?.fill(CGRect(origin: .zero, size: size))
        let image = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return image ?? UIImage()
    }
    
    // MARK: - Text Conversion Tests
    
    @Test func testConvertTextWithSimpleText() {
        let text = "Hello World"
        let attributes: [NSAttributedString.Key: Any] = [:]
        
        let result = MarkdownUtilities.convertTextWithAttributes(text, attributes: attributes)
        
        #expect(result == "Hello World")
    }
    
    @Test func testConvertTextWithBold() {
        let text = "Bold Text"
        let font = UIFont.boldSystemFont(ofSize: 16)
        let attributes: [NSAttributedString.Key: Any] = [.font: font]
        
        let result = MarkdownUtilities.convertTextWithAttributes(text, attributes: attributes)
        
        #expect(result == "**Bold Text**")
    }
    
    @Test func testConvertTextWithItalic() {
        let text = "Italic Text"
        let font = UIFont.italicSystemFont(ofSize: 16)
        let attributes: [NSAttributedString.Key: Any] = [.font: font]
        
        let result = MarkdownUtilities.convertTextWithAttributes(text, attributes: attributes)
        
        #expect(result == "*Italic Text*")
    }
    
    @Test func testConvertTextWithBoldItalic() {
        let text = "Bold Italic Text"
        let descriptor = UIFont.systemFont(ofSize: 16).fontDescriptor
            .withSymbolicTraits([.traitBold, .traitItalic])!
        let font = UIFont(descriptor: descriptor, size: 16)
        let attributes: [NSAttributedString.Key: Any] = [.font: font]
        
        let result = MarkdownUtilities.convertTextWithAttributes(text, attributes: attributes)
        
        #expect(result == "***Bold Italic Text***")
    }
    
    @Test func testConvertTextWithUnderline() {
        let text = "Underlined Text"
        let attributes: [NSAttributedString.Key: Any] = [
            .underlineStyle: NSNumber(value: NSUnderlineStyle.single.rawValue)
        ]
        
        let result = MarkdownUtilities.convertTextWithAttributes(text, attributes: attributes)
        
        #expect(result == "<u>Underlined Text</u>")
    }
    
    @Test func testConvertTextWithStrikethrough() {
        let text = "Strikethrough Text"
        let attributes: [NSAttributedString.Key: Any] = [
            .strikethroughStyle: NSNumber(value: NSUnderlineStyle.single.rawValue)
        ]
        
        let result = MarkdownUtilities.convertTextWithAttributes(text, attributes: attributes)
        
        #expect(result == "~~Strikethrough Text~~")
    }
    
    @Test func testConvertTextWithLink() {
        let text = "Click here"
        let url = URL(string: "https://example.com")!
        let attributes: [NSAttributedString.Key: Any] = [.link: url]
        
        let result = MarkdownUtilities.convertTextWithAttributes(text, attributes: attributes)
        
        #expect(result == "[Click here](https://example.com)")
    }
    
    @Test func testConvertTextWithHeading1() {
        let text = "Large Heading"
        let font = UIFont.systemFont(ofSize: 30)
        let attributes: [NSAttributedString.Key: Any] = [.font: font]
        
        let result = MarkdownUtilities.convertTextWithAttributes(text, attributes: attributes)
        
        #expect(result == "# Large Heading")
    }
    
    @Test func testConvertTextWithHeading2() {
        let text = "Medium Heading"
        let font = UIFont.systemFont(ofSize: 22)
        let attributes: [NSAttributedString.Key: Any] = [.font: font]
        
        let result = MarkdownUtilities.convertTextWithAttributes(text, attributes: attributes)
        
        #expect(result == "## Medium Heading")
    }
    
    @Test func testConvertTextWithTodoListItem() {
        let text = "◦\tTodo item"
        let attributes: [NSAttributedString.Key: Any] = [:]
        
        let result = MarkdownUtilities.convertTextWithAttributes(text, attributes: attributes)
        
        #expect(result == "- [ ] Todo item")
    }
    
    @Test func testConvertTextWithBulletListItem() {
        let text = "•\tBullet item"
        let attributes: [NSAttributedString.Key: Any] = [:]
        
        let result = MarkdownUtilities.convertTextWithAttributes(text, attributes: attributes)
        
        #expect(result == "- Bullet item")
    }
    
    @Test func testConvertTextWithDashListItem() {
        let text = "⁃\tDash item"
        let attributes: [NSAttributedString.Key: Any] = [:]
        
        let result = MarkdownUtilities.convertTextWithAttributes(text, attributes: attributes)
        
        #expect(result == "- Dash item")
    }
    
    // MARK: - Image Markdown Tests
    
    @Test func testGenerateImageMarkdownIgnore() {
        let settings = createTestSettingsStore(imageHandling: .ignore)
        let altText = "Test image"
        
        let result = MarkdownUtilities.generateImageMarkdown(altText: altText, settings: settings)
        
        #expect(result == "<!-- Image ignored -->")
    }
    
    @Test func testGenerateImageMarkdownSaveLocal() {
        let settings = createTestSettingsStore(imageHandling: .saveLocal)
        let altText = "Test image"
        
        let result = MarkdownUtilities.generateImageMarkdown(altText: altText, settings: settings)
        
        #expect(result == "![Test image](./images/image.png)")
    }
    
    @Test func testGenerateImageMarkdownSaveCustom() {
        let settings = createTestSettingsStore(imageHandling: .saveCustom, customImageFolder: "my_images")
        let altText = "Test image"
        
        let result = MarkdownUtilities.generateImageMarkdown(altText: altText, settings: settings)
        
        #expect(result == "![Test image](.//my_images/image.png)")
    }
    
    @Test func testGenerateImageMarkdownWithBase64Ignore() {
        let settings = createTestSettingsStore(imageHandling: .ignore)
        let image = createTestImage()
        let altText = "Test image"
        
        let result = MarkdownUtilities.generateImageMarkdownWithBase64(image: image, altText: altText, settings: settings)
        
        #expect(result == "<!-- Image ignored -->")
    }
    
    @Test func testGenerateImageMarkdownWithBase64SaveLocal() {
        let settings = createTestSettingsStore(imageHandling: .saveLocal)
        let image = createTestImage()
        let altText = "Test image"
        
        let result = MarkdownUtilities.generateImageMarkdownWithBase64(image: image, altText: altText, settings: settings)
        
        #expect(result.hasPrefix("![image](data:image/png;base64,"))
        #expect(result.contains("iVBORw0KGgo")) // PNG header in base64
    }
    
    @Test func testGenerateImageMarkdownWithBase64SaveCustom() {
        let settings = createTestSettingsStore(imageHandling: .saveCustom, customImageFolder: "custom_folder")
        let image = createTestImage()
        let altText = "Test image"
        
        let result = MarkdownUtilities.generateImageMarkdownWithBase64(image: image, altText: altText, settings: settings)
        
        #expect(result.hasPrefix("![image](data:image/png;base64,"))
        #expect(result.contains("iVBORw0KGgo")) // PNG header in base64
    }
    
    // MARK: - Front Matter Tests
    
    @Test func testGenerateFrontMatterEmpty() {
        let settings = createTestSettingsStore(frontMatterFields: [])
        
        let result = MarkdownUtilities.generateFrontMatter(settings: settings)
        
        #expect(result == "")
    }
    
    @Test func testGenerateFrontMatterString() {
        let field = FrontMatterField(name: "title", type: .string, value: "My Article")
        let settings = createTestSettingsStore(frontMatterFields: [field])
        
        let result = MarkdownUtilities.generateFrontMatter(settings: settings)
        
        let expected = """
        ---
        title: "My Article"
        ---
        """
        #expect(result == expected)
    }
    
    @Test func testGenerateFrontMatterNumber() {
        let field = FrontMatterField(name: "rating", type: .number, value: "5")
        let settings = createTestSettingsStore(frontMatterFields: [field])
        
        let result = MarkdownUtilities.generateFrontMatter(settings: settings)
        
        let expected = """
        ---
        rating: 5
        ---
        """
        #expect(result == expected)
    }
    
    @Test func testGenerateFrontMatterBoolean() {
        let field = FrontMatterField(name: "published", type: .boolean, value: "true")
        let settings = createTestSettingsStore(frontMatterFields: [field])
        
        let result = MarkdownUtilities.generateFrontMatter(settings: settings)
        
        let expected = """
        ---
        published: true
        ---
        """
        #expect(result == expected)
    }
    
    @Test func testGenerateFrontMatterBooleanFalse() {
        let field = FrontMatterField(name: "draft", type: .boolean, value: "false")
        let settings = createTestSettingsStore(frontMatterFields: [field])
        
        let result = MarkdownUtilities.generateFrontMatter(settings: settings)
        
        let expected = """
        ---
        draft: false
        ---
        """
        #expect(result == expected)
    }
    
    @Test func testGenerateFrontMatterList() {
        let field = FrontMatterField(name: "categories", type: .list, value: "tech, programming, swift")
        let settings = createTestSettingsStore(frontMatterFields: [field])
        
        let result = MarkdownUtilities.generateFrontMatter(settings: settings)
        
        let expected = """
        ---
        categories: ["tech", "programming", "swift"]
        ---
        """
        #expect(result == expected)
    }
    
    @Test func testGenerateFrontMatterTag() {
        let field = FrontMatterField(name: "tags", type: .tag, value: "ios, swift, testing")
        let settings = createTestSettingsStore(frontMatterFields: [field])
        
        let result = MarkdownUtilities.generateFrontMatter(settings: settings)
        
        let expected = """
        ---
        tags:
          - "ios"
          - "swift"
          - "testing"
        ---
        """
        #expect(result == expected)
    }
    
    @Test func testGenerateFrontMatterMultiline() {
        let field = FrontMatterField(name: "description", type: .multiline, value: "Line 1\nLine 2\nLine 3")
        let settings = createTestSettingsStore(frontMatterFields: [field])
        
        let result = MarkdownUtilities.generateFrontMatter(settings: settings)
        
        let expected = """
        ---
        description: >-
          Line 1
          Line 2
          Line 3
        ---
        """
        #expect(result == expected)
    }
    
    @Test func testGenerateFrontMatterUUID() {
        let field = FrontMatterField(name: "id", type: .uuid, value: "")
        let settings = createTestSettingsStore(frontMatterFields: [field])
        
        let result = MarkdownUtilities.generateFrontMatter(settings: settings)
        
        #expect(result.contains("---"))
        #expect(result.contains("id: \""))
        // UUID should be 36 characters long (including hyphens)
        let uuidRegex = try! NSRegularExpression(pattern: "id: \"[0-9A-F]{8}-[0-9A-F]{4}-[0-9A-F]{4}-[0-9A-F]{4}-[0-9A-F]{12}\"", options: .caseInsensitive)
        let matches = uuidRegex.matches(in: result, options: [], range: NSRange(location: 0, length: result.count))
        #expect(matches.count == 1)
    }
    
    @Test func testGenerateFrontMatterMultipleFields() {
        let fields = [
            FrontMatterField(name: "title", type: .string, value: "Test Post"),
            FrontMatterField(name: "published", type: .boolean, value: "true"),
            FrontMatterField(name: "rating", type: .number, value: "5")
        ]
        let settings = createTestSettingsStore(frontMatterFields: fields)
        
        let result = MarkdownUtilities.generateFrontMatter(settings: settings)
        
        #expect(result.contains("title: \"Test Post\""))
        #expect(result.contains("published: true"))
        #expect(result.contains("rating: 5"))
        #expect(result.hasPrefix("---\n"))
        #expect(result.hasSuffix("---"))
    }
    
    // MARK: - Field Value Processing Tests
    
    @Test func testProcessFieldValueCurrentDate() {
        let field = FrontMatterField(name: "date", type: .string, value: "{current_date}")
        
        let result = MarkdownUtilities.processFieldValue(field)
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        let expectedDate = dateFormatter.string(from: Date())
        
        #expect(result == expectedDate)
    }
    
    @Test func testProcessFieldValueCurrentTime() {
        let field = FrontMatterField(name: "time", type: .string, value: "{current_time}")
        
        let result = MarkdownUtilities.processFieldValue(field)
        
        // Check format HH:mm:ss
        let timeRegex = try! NSRegularExpression(pattern: "\\d{2}:\\d{2}:\\d{2}")
        let matches = timeRegex.matches(in: result, options: [], range: NSRange(location: 0, length: result.count))
        
        #expect(matches.count == 1)
    }
    
    @Test func testProcessFieldValueMixedPlaceholders() {
        let field = FrontMatterField(name: "timestamp", type: .string, value: "Created on {current_date} at {current_time}")
        
        let result = MarkdownUtilities.processFieldValue(field)
        
        #expect(result.contains("Created on"))
        #expect(result.contains("at"))
        #expect(result.contains("-")) // Date separator
        #expect(result.contains(":")) // Time separator
    }
    
    @Test func testProcessFieldValueNoPlaceholders() {
        let field = FrontMatterField(name: "static", type: .string, value: "Static Value")
        
        let result = MarkdownUtilities.processFieldValue(field)
        
        #expect(result == "Static Value")
    }
    
    // MARK: - Edge Cases and Complex Scenarios
    
    @Test func testConvertTextWithComplexFormatting() {
        let text = "Complex Text"
        let descriptor = UIFont.systemFont(ofSize: 16).fontDescriptor
            .withSymbolicTraits([.traitBold, .traitItalic])!
        let font = UIFont(descriptor: descriptor, size: 16)
        let attributes: [NSAttributedString.Key: Any] = [
            .font: font,
            .underlineStyle: NSNumber(value: NSUnderlineStyle.single.rawValue),
            .strikethroughStyle: NSNumber(value: NSUnderlineStyle.single.rawValue)
        ]
        
        let result = MarkdownUtilities.convertTextWithAttributes(text, attributes: attributes)
        
        #expect(result == "**~~<u>*Complex Text*</u>~~**")
    }
    
    @Test func testGenerateFrontMatterCurrentDateTime() {
        let field = FrontMatterField(name: "created", type: .current_datetime, value: "")
        let settings = createTestSettingsStore(frontMatterFields: [field])
        
        let result = MarkdownUtilities.generateFrontMatter(settings: settings)
        
        #expect(result.contains("created: \""))
        #expect(result.contains("---"))
    }
    
    @Test func testGenerateFrontMatterCurrentDate() {
        let field = FrontMatterField(name: "date", type: .current_date, value: "")
        let settings = createTestSettingsStore(frontMatterFields: [field])
        
        let result = MarkdownUtilities.generateFrontMatter(settings: settings)
        
        #expect(result.contains("date: \""))
        #expect(result.contains("---"))
    }
}
