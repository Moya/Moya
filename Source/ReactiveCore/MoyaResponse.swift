import Foundation

public class MoyaResponse: NSObject, CustomDebugStringConvertible {
    public let statusCode: Int
    public let data: NSData
    public let response: NSURLResponse?
    
    public init(statusCode: Int, data: NSData, response: NSURLResponse?) {
        self.statusCode = statusCode
        self.data = data
        self.response = response
    }
    
    override public var description: String {
        return "Status Code: \(statusCode), Data Length: \(data.length)"
    }
    
    override public var debugDescription: String {
        return description
    }
}

public extension MoyaResponse {
    
    /// Filters out responses that don't fall within the given range, generating errors when others are encountered.
    public func filterStatusCodes(range: ClosedInterval<Int>) throws -> MoyaResponse {
        guard range.contains(self.statusCode) else {
            throw NSError(domain: MoyaErrorDomain, code: MoyaErrorCode.StatusCode.rawValue, userInfo: ["data": self])
        }
        return self
    }
    
    public func filterStatusCode(code: Int) throws -> MoyaResponse {
        return try filterStatusCodes(code...code)
    }
    
    public func filterSuccessfulStatusCodes() throws -> MoyaResponse {
        return try filterStatusCodes(200...299)
    }
    
    public func filterSuccessfulStatusAndRedirectCodes() throws -> MoyaResponse {
        return try filterStatusCodes(200...399)
    }
    
    /// Maps data received from the signal into a UIImage.
    func mapImage() throws -> Image {
        guard let image = Image(data: self.data) else {
            throw NSError(domain: MoyaErrorDomain, code: MoyaErrorCode.ImageMapping.rawValue, userInfo: ["data": self])
        }
        return image
    }
    
    /// Maps data received from the signal into a JSON object.
    func mapJSON() throws -> AnyObject {
        return try NSJSONSerialization.JSONObjectWithData(self.data, options: .AllowFragments)
    }
    
    /// Maps data received from the signal into a String.
    func mapString() throws -> String {
        guard let string = NSString(data: self.data, encoding: NSUTF8StringEncoding) else {
            throw NSError(domain: MoyaErrorDomain, code: MoyaErrorCode.StringMapping.rawValue, userInfo: ["data": self])
        }
        return string as String
    }
}

/// Required for making Endpoint conform to Equatable.
public func ==<T>(lhs: Endpoint<T>, rhs: Endpoint<T>) -> Bool {
    return lhs.urlRequest.isEqual(rhs.urlRequest)
}

/// Required for using Endpoint as a key type in a Dictionary.
extension Endpoint: Equatable, Hashable {
    public var hashValue: Int {
        return urlRequest.hash
    }
}
