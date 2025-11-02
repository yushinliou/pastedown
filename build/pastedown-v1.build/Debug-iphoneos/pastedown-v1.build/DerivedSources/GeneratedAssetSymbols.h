#import <Foundation/Foundation.h>

#if __has_attribute(swift_private)
#define AC_SWIFT_PRIVATE __attribute__((swift_private))
#else
#define AC_SWIFT_PRIVATE
#endif

/// The resource bundle ID.
static NSString * const ACBundleID AC_SWIFT_PRIVATE = @"Yu-shin.pastedown-v1";

/// The "backgroundColour" asset catalog color resource.
static NSString * const ACColorNameBackgroundColour AC_SWIFT_PRIVATE = @"backgroundColour";

/// The "errorColor" asset catalog color resource.
static NSString * const ACColorNameErrorColor AC_SWIFT_PRIVATE = @"errorColor";

/// The "infoColor" asset catalog color resource.
static NSString * const ACColorNameInfoColor AC_SWIFT_PRIVATE = @"infoColor";

/// The "primaryColour" asset catalog color resource.
static NSString * const ACColorNamePrimaryColour AC_SWIFT_PRIVATE = @"primaryColour";

/// The "secondaryColour" asset catalog color resource.
static NSString * const ACColorNameSecondaryColour AC_SWIFT_PRIVATE = @"secondaryColour";

/// The "successColor" asset catalog color resource.
static NSString * const ACColorNameSuccessColor AC_SWIFT_PRIVATE = @"successColor";

/// The "surfaceBorder" asset catalog color resource.
static NSString * const ACColorNameSurfaceBorder AC_SWIFT_PRIVATE = @"surfaceBorder";

/// The "surfaceCard" asset catalog color resource.
static NSString * const ACColorNameSurfaceCard AC_SWIFT_PRIVATE = @"surfaceCard";

/// The "textPrimary" asset catalog color resource.
static NSString * const ACColorNameTextPrimary AC_SWIFT_PRIVATE = @"textPrimary";

/// The "textSecondary" asset catalog color resource.
static NSString * const ACColorNameTextSecondary AC_SWIFT_PRIVATE = @"textSecondary";

/// The "textTertiary" asset catalog color resource.
static NSString * const ACColorNameTextTertiary AC_SWIFT_PRIVATE = @"textTertiary";

/// The "warningColor" asset catalog color resource.
static NSString * const ACColorNameWarningColor AC_SWIFT_PRIVATE = @"warningColor";

/// The "pastedown" asset catalog image resource.
static NSString * const ACImageNamePastedown AC_SWIFT_PRIVATE = @"pastedown";

#undef AC_SWIFT_PRIVATE
