#if os(iOS) || os(watchOS) || os(tvOS)
    import UIKit.UIImage
    public typealias ImageType = UIImage
#elseif os(OSX)
    import AppKit.NSImage
    public typealias ImageType = NSImage
#endif

public typealias Image = ImageType
