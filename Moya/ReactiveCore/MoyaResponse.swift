import Foundation
import Moya

public class MoyaResponse: NSObject, Printable {
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
