#import <Foundation/Foundation.h>

#if __has_attribute(swift_private)
#define AC_SWIFT_PRIVATE __attribute__((swift_private))
#else
#define AC_SWIFT_PRIVATE
#endif

/// The resource bundle ID.
static NSString * const ACBundleID AC_SWIFT_PRIVATE = @"com.gu.Yashika.RSMS";

/// The "beige" asset catalog color resource.
static NSString * const ACColorNameBeige AC_SWIFT_PRIVATE = @"beige";

/// The "darkRed" asset catalog color resource.
static NSString * const ACColorNameDarkRed AC_SWIFT_PRIVATE = @"darkRed";

/// The "lightBrown" asset catalog color resource.
static NSString * const ACColorNameLightBrown AC_SWIFT_PRIVATE = @"lightBrown";

/// The "magenta" asset catalog color resource.
static NSString * const ACColorNameMagenta AC_SWIFT_PRIVATE = @"magenta";

#undef AC_SWIFT_PRIVATE
