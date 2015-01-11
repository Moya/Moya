/**
    An object encapsulating the file and line number at which
    a particular example is defined.
*/
@objc public class Callsite {
    /**
        The absolute path of the file in which an example is defined.
    */
    public let file: String

    /**
        The line number on which an example is defined.
    */
    public let line: Int

    internal init(file: String, line: Int) {
        self.file = file
        self.line = line
    }
}
