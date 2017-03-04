import Foundation

public final class Response: CustomDebugStringConvertible, Equatable {
    public let statusCode: Int
    public let data: Data
    public let request: URLRequest?
    public let response: URLResponse?

    public init(statusCode: Int, data: Data, request: URLRequest? = nil, response: URLResponse? = nil) {
        self.statusCode = statusCode
        self.data = data
        self.request = request
        self.response = response
    }

    public var description: String {
        return "Status Code: \(statusCode), Data Length: \(data.count)"
    }

    public var debugDescription: String {
        return description
    }
}

public func == (lhs: Response, rhs: Response) -> Bool {
    return lhs.statusCode == rhs.statusCode
        && lhs.data == rhs.data
        && lhs.response == rhs.response
}

public extension Response {

    /// Filters out responses that don't fall within the given range, generating errors when others are encountered.
    public func filterStatusCodes(_ range: ClosedRange<Int>) throws -> Response {
        guard range.contains(statusCode) else {
            throw Error.statusCode(self)
        }
        return self
    }

    public func filterStatusCode(_ code: Int) throws -> Response {
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
            throw Error.imageMapping(self)
        }
        return image
    }

    /// Maps data received from the signal into a JSON object.
    func mapJSON(failsOnEmptyData: Bool = true) throws -> Any {
        do {
            return try JSONSerialization.jsonObject(with: data, options: .allowFragments)
        } catch {
            if data.count < 1 && !failsOnEmptyData {
                return NSNull()
            }
            throw Error.jsonMapping(self)
        }
    }

    /// Maps data received from the signal into a String.
    func mapString() throws -> String {
        guard let string = NSString(data: data, encoding: String.Encoding.utf8.rawValue) else {
            throw Error.stringMapping(self)
        }
        return string as String
    }
}
