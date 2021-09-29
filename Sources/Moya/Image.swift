#if canImport(UIKit)
    import UIKit.UIImage
    public typealias ImageType = UIImage
#elseif canImport(AppKit)
    import AppKit.NSImage
    public typealias ImageType = NSImage
#endif

/// An alias for the SDK's image type.
@available(*, deprecated, renamed: "ImageType")
public typealias Image = ImageType

/// An alias for the SDK's image type.
public typealias PlatformImage = ImageType
