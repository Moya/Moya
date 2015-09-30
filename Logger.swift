import Foundation


public protocol Logger {
    
    func logNetworkRequest(request: NSURLRequest) -> Void
    
    func logNetworkResponse(response: NSHTTPURLResponse?) -> Void
    
    func logNetworkResponseData(data: NSData) -> Void
    
}