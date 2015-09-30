
//  Created by Alexander Karaberov on 9/30/15.
//
//

import Foundation


public protocol Logger {
    
    func logNetworkRequest(request: NSURLRequest) -> Void
    
    func logNetworkResponse(response: NSHTTPURLResponse?) -> Void
    
    func logNetworkResponseData(data: NSData) -> Void
    
}