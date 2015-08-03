import Foundation
import Moya

public class MoyaResponse: NSObject, Equatable, Printable {
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

public func == (lhs: MoyaResponse, rhs: MoyaResponse) -> Bool {
    return (lhs.statusCode == rhs.statusCode) && (lhs.data.length == rhs.data.length)
}
