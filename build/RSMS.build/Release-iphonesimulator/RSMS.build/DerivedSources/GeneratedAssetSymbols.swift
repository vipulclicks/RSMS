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

    /// The "beige" asset catalog color resource.
    static let beige = DeveloperToolsSupport.ColorResource(name: "beige", bundle: resourceBundle)

    /// The "darkRed" asset catalog color resource.
    static let darkRed = DeveloperToolsSupport.ColorResource(name: "darkRed", bundle: resourceBundle)

    /// The "lightBrown" asset catalog color resource.
    static let lightBrown = DeveloperToolsSupport.ColorResource(name: "lightBrown", bundle: resourceBundle)

    /// The "magenta" asset catalog color resource.
    static let magenta = DeveloperToolsSupport.ColorResource(name: "magenta", bundle: resourceBundle)

}

// MARK: - Image Symbols -

@available(iOS 17.0, macOS 14.0, tvOS 17.0, watchOS 10.0, *)
extension DeveloperToolsSupport.ImageResource {

}

// MARK: - Color Symbol Extensions -

#if canImport(AppKit)
@available(macOS 14.0, *)
@available(macCatalyst, unavailable)
extension AppKit.NSColor {

    /// The "beige" asset catalog color.
    static var beige: AppKit.NSColor {
#if !targetEnvironment(macCatalyst)
        .init(resource: .beige)
#else
        .init()
#endif
    }

    /// The "darkRed" asset catalog color.
    static var darkRed: AppKit.NSColor {
#if !targetEnvironment(macCatalyst)
        .init(resource: .darkRed)
#else
        .init()
#endif
    }

    /// The "lightBrown" asset catalog color.
    static var lightBrown: AppKit.NSColor {
#if !targetEnvironment(macCatalyst)
        .init(resource: .lightBrown)
#else
        .init()
#endif
    }

    #warning("The \"magenta\" color asset name resolves to a conflicting NSColor symbol \"magenta\". Try renaming the asset.")

}
#endif

#if canImport(UIKit)
@available(iOS 17.0, tvOS 17.0, *)
@available(watchOS, unavailable)
extension UIKit.UIColor {

    /// The "beige" asset catalog color.
    static var beige: UIKit.UIColor {
#if !os(watchOS)
        .init(resource: .beige)
#else
        .init()
#endif
    }

    /// The "darkRed" asset catalog color.
    static var darkRed: UIKit.UIColor {
#if !os(watchOS)
        .init(resource: .darkRed)
#else
        .init()
#endif
    }

    /// The "lightBrown" asset catalog color.
    static var lightBrown: UIKit.UIColor {
#if !os(watchOS)
        .init(resource: .lightBrown)
#else
        .init()
#endif
    }

    #warning("The \"magenta\" color asset name resolves to a conflicting UIColor symbol \"magenta\". Try renaming the asset.")

}
#endif

#if canImport(SwiftUI)
@available(iOS 17.0, macOS 14.0, tvOS 17.0, watchOS 10.0, *)
extension SwiftUI.Color {

    /// The "beige" asset catalog color.
    static var beige: SwiftUI.Color { .init(.beige) }

    /// The "darkRed" asset catalog color.
    static var darkRed: SwiftUI.Color { .init(.darkRed) }

    /// The "lightBrown" asset catalog color.
    static var lightBrown: SwiftUI.Color { .init(.lightBrown) }

    /// The "magenta" asset catalog color.
    static var magenta: SwiftUI.Color { .init(.magenta) }

}

@available(iOS 17.0, macOS 14.0, tvOS 17.0, watchOS 10.0, *)
extension SwiftUI.ShapeStyle where Self == SwiftUI.Color {

    /// The "beige" asset catalog color.
    static var beige: SwiftUI.Color { .init(.beige) }

    /// The "darkRed" asset catalog color.
    static var darkRed: SwiftUI.Color { .init(.darkRed) }

    /// The "lightBrown" asset catalog color.
    static var lightBrown: SwiftUI.Color { .init(.lightBrown) }

    /// The "magenta" asset catalog color.
    static var magenta: SwiftUI.Color { .init(.magenta) }

}
#endif

// MARK: - Image Symbol Extensions -

#if canImport(AppKit)
@available(macOS 14.0, *)
@available(macCatalyst, unavailable)
extension AppKit.NSImage {

}
#endif

#if canImport(UIKit)
@available(iOS 17.0, tvOS 17.0, *)
@available(watchOS, unavailable)
extension UIKit.UIImage {

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

