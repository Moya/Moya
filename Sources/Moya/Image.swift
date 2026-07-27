#if canImport(UIKit)
    import UIKit.UIImage
    public typealias Image = UIImage
#elseif canImport(AppKit)
    import AppKit.NSImage
    public typealias Image = NSImage
#endif
