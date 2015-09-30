import Foundation


public struct MoyaLogger: Logger {
    
    private let loggerId = "Moya_Logger"
    private let dateFormatString = "dd/MM/yyyy HH:mm:ss"
    private let dateFormatter = NSDateFormatter()
    
    private var date: String {
        
        dateFormatter.dateFormat = dateFormatString
        dateFormatter.locale = NSLocale(localeIdentifier: "en_US_POSIX")
        return dateFormatter.stringFromDate(NSDate())
    }
    
    public func logNetworkRequest(request: NSURLRequest) {
        
        let requestOutput = String(format: "%@: [%@] Request:  %@", loggerId, date, request.description)
        print(requestOutput)
        
        if let headers = request.allHTTPHeaderFields {
            let requestHeadersOutput = String(format: "%@ [%@] Request Headers:  %@", loggerId, date, headers)
            print(requestHeadersOutput)
        }
        
        if let bodyStream = request.HTTPBodyStream {
            let bodyStreamOutput = String(format: "%@: [%@] Request Body Stream:  %@", loggerId, date, bodyStream.description)
            print(bodyStreamOutput)
        }
        
        if let httpMethod = request.HTTPMethod {
            let httpMethodOutput = String(format: "%@: [%@] HTTP Request Method:  %@", loggerId, date, httpMethod)
            print(httpMethodOutput)
        }
        
        if let body = request.HTTPBody {
            
            if let stringOutput = NSString(data: body, encoding: NSUTF8StringEncoding) {
                
                let bodyOutput = String(format: "%@: [%@] Request Body:  %@", loggerId, date, stringOutput)
                print(bodyOutput)
            }
        }
        
    }
    
    public func logNetworkResponse(response: NSHTTPURLResponse?) {
        
        if let response = response {
            let responseOutput = String(format: "%@: [%@] Response:  %@", loggerId, date, response.description)
            print(responseOutput)
        }
    }
    
    public func logNetworkResponseData(data: NSData) {
        
        let stringRepresentation = NSString(data: data, encoding: NSUTF8StringEncoding)
        
        if let stringRepresentation = stringRepresentation {
            let stringRepresentationOutput = String(format: "%@: [%@] Response Data:  %@", loggerId, date, stringRepresentation)
            print(stringRepresentationOutput)
            
        }
        
    }
}
