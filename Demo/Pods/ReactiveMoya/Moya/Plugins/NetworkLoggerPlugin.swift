import Foundation

/// Logs network activity (outgoing requests and incoming responses).
public class NetworkLoggerPlugin<Target: MoyaTarget>: Plugin<Target> {
    private let loggerId = "Moya_Logger"
    private let dateFormatString = "dd/MM/yyyy HH:mm:ss"
    private let dateFormatter = NSDateFormatter()

    /// If true, also logs response body data.
    public let verbose: Bool

    public init(verbose: Bool = false) {
        self.verbose = verbose
    }

    public override func willSendRequest(request: MoyaRequest, provider: MoyaProvider<Target>, target: Target) {
        logNetworkRequest(request.request)
    }

    public override func didReceiveResponse(data: NSData?, statusCode: Int?, response: NSURLResponse?, error: ErrorType?, provider: MoyaProvider<Target>, target: Target) {
        logNetworkResponse(response, data: data, target: target)
    }

}

private extension NetworkLoggerPlugin {

    private var date: String {
        dateFormatter.dateFormat = dateFormatString
        dateFormatter.locale = NSLocale(localeIdentifier: "en_US_POSIX")
        return dateFormatter.stringFromDate(NSDate())
    }

    func logNetworkRequest(request: NSURLRequest?) {

        var output = ""

        output += String(format: "%@: [%@] Request:  %@", loggerId, date, request?.description ?? "(invalid request)")

        if let headers = request?.allHTTPHeaderFields {
            output += String(format: "%@ [%@] Request Headers:  %@", loggerId, date, headers)
        }

        if let bodyStream = request?.HTTPBodyStream {
            output += String(format: "%@: [%@] Request Body Stream:  %@", loggerId, date, bodyStream.description)
        }

        if let httpMethod = request?.HTTPMethod {
            output += String(format: "%@: [%@] HTTP Request Method:  %@", loggerId, date, httpMethod)
        }

        if let body = request?.HTTPBody where verbose == true {
            if let stringOutput = NSString(data: body, encoding: NSUTF8StringEncoding) {
                output += String(format: "%@: [%@] Request Body:  %@", loggerId, date, stringOutput)
            }
        }

        print(output)
    }

    func logNetworkResponse(response: NSURLResponse?, data: NSData?, target: Target) {
        guard let response = response else {
            print("Received empty network response for \(target).")
            return
        }

        var output = ""

        output += String(format: "%@: [%@] Response:  %@", loggerId, date, response.description)

        if let data = data,
            let stringData = NSString(data: data, encoding: NSUTF8StringEncoding) as? String
            where verbose == true {
            output += stringData
        }

        print(output)
    }
}
