import Foundation

public final class Response: CustomDebugStringConvertible, Equatable {
    public let statusCode: Int
    public let data: NSData
    public let response: NSURLResponse?

    public init(statusCode: Int, data: NSData, response: NSURLResponse? = nil) {
        self.statusCode = statusCode
        self.data = data
        self.response = response
    }

    public var description: String {
        return "Status Code: \(statusCode), Data Length: \(data.length)"
    }

    public var debugDescription: String {
        return description
    }
}

public func ==(lhs: Response, rhs: Response) -> Bool {
    return lhs.statusCode == rhs.statusCode
        && lhs.data == rhs.data
        && lhs.response == rhs.response
}

public extension Response {

    /// Filters out responses that don't fall within the given range, generating errors when others are encountered.
    public func filterStatusCodes(range: ClosedInterval<Int>) throws -> Response {
        guard range.contains(statusCode) else {
            throw Error.StatusCode(self)
        }
        return self
    }

    public func filterStatusCode(code: Int) throws -> Response {
        return try filterStatusCodes(code...code)
    }

    public func filterSuccessfulStatusCodes() throws -> Response {
        return try filterStatusCodes(200...299)
    }

    public func filterSuccessfulStatusAndRedirectCodes() throws -> Response {
        return try filterStatusCodes(200...399)
    }

    /// Maps data received from the signal into a UIImage.
    func mapImage() throws -> Image {
        guard let image = Image(data: data) else {
            throw Error.ImageMapping(self)
        }
        return image
    }

    /// Maps data received from the signal into a JSON object.
    func mapJSON() throws -> AnyObject {
        do {
            return try NSJSONSerialization.JSONObjectWithData(data, options: .AllowFragments)
        } catch {
            throw Error.Underlying(error)
        }
    }

    /// Maps data received from the signal into a String.
    func mapString() throws -> String {
        guard let string = NSString(data: data, encoding: NSUTF8StringEncoding) else {
            throw Error.StringMapping(self)
        }
        return string as String
    }
}
