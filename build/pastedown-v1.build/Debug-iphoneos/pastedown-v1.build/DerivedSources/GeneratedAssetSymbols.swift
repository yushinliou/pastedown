import Foundation
#if canImport(AppKit)
import AppKit
#endif
#if canImport(UIKit)
import UIKit
#endif
#if canImport(SwiftUI)
import SwiftUI
#endif
#if canImport(DeveloperToolsSupport)
import DeveloperToolsSupport
#endif

#if SWIFT_PACKAGE
private let resourceBundle = Foundation.Bundle.module
#else
private class ResourceBundleClass {}
private let resourceBundle = Foundation.Bundle(for: ResourceBundleClass.self)
#endif

// MARK: - Color Symbols -

@available(iOS 17.0, macOS 14.0, tvOS 17.0, watchOS 10.0, *)
extension DeveloperToolsSupport.ColorResource {

    /// The "backgroundColour" asset catalog color resource.
    static let backgroundColour = DeveloperToolsSupport.ColorResource(name: "backgroundColour", bundle: resourceBundle)

    /// The "errorColor" asset catalog color resource.
    static let error = DeveloperToolsSupport.ColorResource(name: "errorColor", bundle: resourceBundle)

    /// The "infoColor" asset catalog color resource.
    static let info = DeveloperToolsSupport.ColorResource(name: "infoColor", bundle: resourceBundle)

    /// The "primaryColour" asset catalog color resource.
    static let primaryColour = DeveloperToolsSupport.ColorResource(name: "primaryColour", bundle: resourceBundle)

    /// The "secondaryColour" asset catalog color resource.
    static let secondaryColour = DeveloperToolsSupport.ColorResource(name: "secondaryColour", bundle: resourceBundle)

    /// The "successColor" asset catalog color resource.
    static let success = DeveloperToolsSupport.ColorResource(name: "successColor", bundle: resourceBundle)

    /// The "surfaceBorder" asset catalog color resource.
    static let surfaceBorder = DeveloperToolsSupport.ColorResource(name: "surfaceBorder", bundle: resourceBundle)

    /// The "surfaceCard" asset catalog color resource.
    static let surfaceCard = DeveloperToolsSupport.ColorResource(name: "surfaceCard", bundle: resourceBundle)

    /// The "textPrimary" asset catalog color resource.
    static let textPrimary = DeveloperToolsSupport.ColorResource(name: "textPrimary", bundle: resourceBundle)

    /// The "textSecondary" asset catalog color resource.
    static let textSecondary = DeveloperToolsSupport.ColorResource(name: "textSecondary", bundle: resourceBundle)

    /// The "textTertiary" asset catalog color resource.
    static let textTertiary = DeveloperToolsSupport.ColorResource(name: "textTertiary", bundle: resourceBundle)

    /// The "warningColor" asset catalog color resource.
    static let warning = DeveloperToolsSupport.ColorResource(name: "warningColor", bundle: resourceBundle)

    
}

// MARK: - Image Symbols -

@available(iOS 17.0, macOS 14.0, tvOS 17.0, watchOS 10.0, *)
extension DeveloperToolsSupport.ImageResource {

    /// The "pastedown" asset catalog image resource.
    static let pastedown = DeveloperToolsSupport.ImageResource(name: "pastedown", bundle: resourceBundle)

}

// MARK: - Color Symbol Extensions -

#if canImport(AppKit)
@available(macOS 14.0, *)
@available(macCatalyst, unavailable)
extension AppKit.NSColor {

    /// The "backgroundColour" asset catalog color.
    static var backgroundColour: AppKit.NSColor {
#if !targetEnvironment(macCatalyst)
        .init(resource: .backgroundColour)
#else
        .init()
#endif
    }

    /// The "errorColor" asset catalog color.
    static var error: AppKit.NSColor {
#if !targetEnvironment(macCatalyst)
        .init(resource: .error)
#else
        .init()
#endif
    }

    /// The "infoColor" asset catalog color.
    static var info: AppKit.NSColor {
#if !targetEnvironment(macCatalyst)
        .init(resource: .info)
#else
        .init()
#endif
    }

    /// The "primaryColour" asset catalog color.
    static var primaryColour: AppKit.NSColor {
#if !targetEnvironment(macCatalyst)
        .init(resource: .primaryColour)
#else
        .init()
#endif
    }

    /// The "secondaryColour" asset catalog color.
    static var secondaryColour: AppKit.NSColor {
#if !targetEnvironment(macCatalyst)
        .init(resource: .secondaryColour)
#else
        .init()
#endif
    }

    /// The "successColor" asset catalog color.
    static var success: AppKit.NSColor {
#if !targetEnvironment(macCatalyst)
        .init(resource: .success)
#else
        .init()
#endif
    }

    /// The "surfaceBorder" asset catalog color.
    static var surfaceBorder: AppKit.NSColor {
#if !targetEnvironment(macCatalyst)
        .init(resource: .surfaceBorder)
#else
        .init()
#endif
    }

    /// The "surfaceCard" asset catalog color.
    static var surfaceCard: AppKit.NSColor {
#if !targetEnvironment(macCatalyst)
        .init(resource: .surfaceCard)
#else
        .init()
#endif
    }

    /// The "textPrimary" asset catalog color.
    static var textPrimary: AppKit.NSColor {
#if !targetEnvironment(macCatalyst)
        .init(resource: .textPrimary)
#else
        .init()
#endif
    }

    /// The "textSecondary" asset catalog color.
    static var textSecondary: AppKit.NSColor {
#if !targetEnvironment(macCatalyst)
        .init(resource: .textSecondary)
#else
        .init()
#endif
    }

    /// The "textTertiary" asset catalog color.
    static var textTertiary: AppKit.NSColor {
#if !targetEnvironment(macCatalyst)
        .init(resource: .textTertiary)
#else
        .init()
#endif
    }

    /// The "warningColor" asset catalog color.
    static var warning: AppKit.NSColor {
#if !targetEnvironment(macCatalyst)
        .init(resource: .warning)
#else
        .init()
#endif
    }

}
#endif

#if canImport(UIKit)
@available(iOS 17.0, tvOS 17.0, *)
@available(watchOS, unavailable)
extension UIKit.UIColor {

    /// The "backgroundColour" asset catalog color.
    static var backgroundColour: UIKit.UIColor {
#if !os(watchOS)
        .init(resource: .backgroundColour)
#else
        .init()
#endif
    }

    /// The "errorColor" asset catalog color.
    static var error: UIKit.UIColor {
#if !os(watchOS)
        .init(resource: .error)
#else
        .init()
#endif
    }

    /// The "infoColor" asset catalog color.
    static var info: UIKit.UIColor {
#if !os(watchOS)
        .init(resource: .info)
#else
        .init()
#endif
    }

    /// The "primaryColour" asset catalog color.
    static var primaryColour: UIKit.UIColor {
#if !os(watchOS)
        .init(resource: .primaryColour)
#else
        .init()
#endif
    }

    /// The "secondaryColour" asset catalog color.
    static var secondaryColour: UIKit.UIColor {
#if !os(watchOS)
        .init(resource: .secondaryColour)
#else
        .init()
#endif
    }

    /// The "successColor" asset catalog color.
    static var success: UIKit.UIColor {
#if !os(watchOS)
        .init(resource: .success)
#else
        .init()
#endif
    }

    /// The "surfaceBorder" asset catalog color.
    static var surfaceBorder: UIKit.UIColor {
#if !os(watchOS)
        .init(resource: .surfaceBorder)
#else
        .init()
#endif
    }

    /// The "surfaceCard" asset catalog color.
    static var surfaceCard: UIKit.UIColor {
#if !os(watchOS)
        .init(resource: .surfaceCard)
#else
        .init()
#endif
    }

    /// The "textPrimary" asset catalog color.
    static var textPrimary: UIKit.UIColor {
#if !os(watchOS)
        .init(resource: .textPrimary)
#else
        .init()
#endif
    }

    /// The "textSecondary" asset catalog color.
    static var textSecondary: UIKit.UIColor {
#if !os(watchOS)
        .init(resource: .textSecondary)
#else
        .init()
#endif
    }

    /// The "textTertiary" asset catalog color.
    static var textTertiary: UIKit.UIColor {
#if !os(watchOS)
        .init(resource: .textTertiary)
#else
        .init()
#endif
    }

    /// The "warningColor" asset catalog color.
    static var warning: UIKit.UIColor {
#if !os(watchOS)
        .init(resource: .warning)
#else
        .init()
#endif
    }

}
#endif

#if canImport(SwiftUI)
@available(iOS 17.0, macOS 14.0, tvOS 17.0, watchOS 10.0, *)
extension SwiftUI.Color {

    /// The "backgroundColour" asset catalog color.
    static var backgroundColour: SwiftUI.Color { .init(.backgroundColour) }

    /// The "errorColor" asset catalog color.
    static var error: SwiftUI.Color { .init(.error) }

    /// The "infoColor" asset catalog color.
    static var info: SwiftUI.Color { .init(.info) }

    /// The "primaryColour" asset catalog color.
    static var primaryColour: SwiftUI.Color { .init(.primaryColour) }

    /// The "secondaryColour" asset catalog color.
    static var secondaryColour: SwiftUI.Color { .init(.secondaryColour) }

    /// The "successColor" asset catalog color.
    static var success: SwiftUI.Color { .init(.success) }

    /// The "surfaceBorder" asset catalog color.
    static var surfaceBorder: SwiftUI.Color { .init(.surfaceBorder) }

    /// The "surfaceCard" asset catalog color.
    static var surfaceCard: SwiftUI.Color { .init(.surfaceCard) }

    /// The "textPrimary" asset catalog color.
    static var textPrimary: SwiftUI.Color { .init(.textPrimary) }

    /// The "textSecondary" asset catalog color.
    static var textSecondary: SwiftUI.Color { .init(.textSecondary) }

    /// The "textTertiary" asset catalog color.
    static var textTertiary: SwiftUI.Color { .init(.textTertiary) }

    /// The "warningColor" asset catalog color.
    static var warning: SwiftUI.Color { .init(.warning) }

}

@available(iOS 17.0, macOS 14.0, tvOS 17.0, watchOS 10.0, *)
extension SwiftUI.ShapeStyle where Self == SwiftUI.Color {

    /// The "backgroundColour" asset catalog color.
    static var backgroundColour: SwiftUI.Color { .init(.backgroundColour) }

    /// The "errorColor" asset catalog color.
    static var error: SwiftUI.Color { .init(.error) }

    /// The "infoColor" asset catalog color.
    static var info: SwiftUI.Color { .init(.info) }

    /// The "primaryColour" asset catalog color.
    static var primaryColour: SwiftUI.Color { .init(.primaryColour) }

    /// The "secondaryColour" asset catalog color.
    static var secondaryColour: SwiftUI.Color { .init(.secondaryColour) }

    /// The "successColor" asset catalog color.
    static var success: SwiftUI.Color { .init(.success) }

    /// The "surfaceBorder" asset catalog color.
    static var surfaceBorder: SwiftUI.Color { .init(.surfaceBorder) }

    /// The "surfaceCard" asset catalog color.
    static var surfaceCard: SwiftUI.Color { .init(.surfaceCard) }

    /// The "textPrimary" asset catalog color.
    static var textPrimary: SwiftUI.Color { .init(.textPrimary) }

    /// The "textSecondary" asset catalog color.
    static var textSecondary: SwiftUI.Color { .init(.textSecondary) }

    /// The "textTertiary" asset catalog color.
    static var textTertiary: SwiftUI.Color { .init(.textTertiary) }

    /// The "warningColor" asset catalog color.
    static var warning: SwiftUI.Color { .init(.warning) }

}
#endif

// MARK: - Image Symbol Extensions -

#if canImport(AppKit)
@available(macOS 14.0, *)
@available(macCatalyst, unavailable)
extension AppKit.NSImage {

    /// The "pastedown" asset catalog image.
    static var pastedown: AppKit.NSImage {
#if !targetEnvironment(macCatalyst)
        .init(resource: .pastedown)
#else
        .init()
#endif
    }

}
#endif

#if canImport(UIKit)
@available(iOS 17.0, tvOS 17.0, *)
@available(watchOS, unavailable)
extension UIKit.UIImage {

    /// The "pastedown" asset catalog image.
    static var pastedown: UIKit.UIImage {
#if !os(watchOS)
        .init(resource: .pastedown)
#else
        .init()
#endif
    }

}
#endif

// MARK: - Thinnable Asset Support -

@available(iOS 17.0, macOS 14.0, tvOS 17.0, watchOS 10.0, *)
@available(watchOS, unavailable)
extension DeveloperToolsSupport.ColorResource {

    private init?(thinnableName: Swift.String, bundle: Foundation.Bundle) {
#if canImport(AppKit) && os(macOS)
        if AppKit.NSColor(named: NSColor.Name(thinnableName), bundle: bundle) != nil {
            self.init(name: thinnableName, bundle: bundle)
        } else {
            return nil
        }
#elseif canImport(UIKit) && !os(watchOS)
        if UIKit.UIColor(named: thinnableName, in: bundle, compatibleWith: nil) != nil {
            self.init(name: thinnableName, bundle: bundle)
        } else {
            return nil
        }
#else
        return nil
#endif
    }

}

#if canImport(AppKit)
@available(macOS 14.0, *)
@available(macCatalyst, unavailable)
extension AppKit.NSColor {

    private convenience init?(thinnableResource: DeveloperToolsSupport.ColorResource?) {
#if !targetEnvironment(macCatalyst)
        if let resource = thinnableResource {
            self.init(resource: resource)
        } else {
            return nil
        }
#else
        return nil
#endif
    }

}
#endif

#if canImport(UIKit)
@available(iOS 17.0, tvOS 17.0, *)
@available(watchOS, unavailable)
extension UIKit.UIColor {

    private convenience init?(thinnableResource: DeveloperToolsSupport.ColorResource?) {
#if !os(watchOS)
        if let resource = thinnableResource {
            self.init(resource: resource)
        } else {
            return nil
        }
#else
        return nil
#endif
    }

}
#endif

#if canImport(SwiftUI)
@available(iOS 17.0, macOS 14.0, tvOS 17.0, watchOS 10.0, *)
extension SwiftUI.Color {

    private init?(thinnableResource: DeveloperToolsSupport.ColorResource?) {
        if let resource = thinnableResource {
            self.init(resource)
        } else {
            return nil
        }
    }

}

@available(iOS 17.0, macOS 14.0, tvOS 17.0, watchOS 10.0, *)
extension SwiftUI.ShapeStyle where Self == SwiftUI.Color {

    private init?(thinnableResource: DeveloperToolsSupport.ColorResource?) {
        if let resource = thinnableResource {
            self.init(resource)
        } else {
            return nil
        }
    }

}
#endif

@available(iOS 17.0, macOS 14.0, tvOS 17.0, watchOS 10.0, *)
@available(watchOS, unavailable)
extension DeveloperToolsSupport.ImageResource {

    private init?(thinnableName: Swift.String, bundle: Foundation.Bundle) {
#if canImport(AppKit) && os(macOS)
        if bundle.image(forResource: NSImage.Name(thinnableName)) != nil {
            self.init(name: thinnableName, bundle: bundle)
        } else {
            return nil
        }
#elseif canImport(UIKit) && !os(watchOS)
        if UIKit.UIImage(named: thinnableName, in: bundle, compatibleWith: nil) != nil {
            self.init(name: thinnableName, bundle: bundle)
        } else {
            return nil
        }
#else
        return nil
#endif
    }

}

#if canImport(AppKit)
@available(macOS 14.0, *)
@available(macCatalyst, unavailable)
extension AppKit.NSImage {

    private convenience init?(thinnableResource: DeveloperToolsSupport.ImageResource?) {
#if !targetEnvironment(macCatalyst)
        if let resource = thinnableResource {
            self.init(resource: resource)
        } else {
            return nil
        }
#else
        return nil
#endif
    }

}
#endif

#if canImport(UIKit)
@available(iOS 17.0, tvOS 17.0, *)
@available(watchOS, unavailable)
extension UIKit.UIImage {

    private convenience init?(thinnableResource: DeveloperToolsSupport.ImageResource?) {
#if !os(watchOS)
        if let resource = thinnableResource {
            self.init(resource: resource)
        } else {
            return nil
        }
#else
        return nil
#endif
    }

}
#endif

