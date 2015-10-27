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
