#if os(iOS) || os(watchOS) || os(tvOS)
    import UIKit.UIImage
    public typealias ImageType = UIImage
#elseif os(macOS)
    import AppKit.NSImage
    public typealias ImageType = NSImage
#endif

/// An alias for the SDK's image type.
public typealias Image = ImageType
