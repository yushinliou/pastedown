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

/// The "primaryColour" asset catalog color resource.
static NSString * const ACColorNamePrimaryColour AC_SWIFT_PRIVATE = @"primaryColour";

/// The "secondaryColour" asset catalog color resource.
static NSString * const ACColorNameSecondaryColour AC_SWIFT_PRIVATE = @"secondaryColour";

/// The "pastedown" asset catalog image resource.
static NSString * const ACImageNamePastedown AC_SWIFT_PRIVATE = @"pastedown";

#undef AC_SWIFT_PRIVATE
