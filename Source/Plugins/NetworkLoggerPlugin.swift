import Foundation
import Result

/// Logs network activity (outgoing requests and incoming responses).
public final class NetworkLoggerPlugin: PluginType {
    private let loggerId = "Moya_Logger"
    private let dateFormatString = "dd/MM/yyyy HH:mm:ss"
    private let dateFormatter = NSDateFormatter()
    private let separator = ", "
    private let terminator = "\n"
    private let output: (items: Any..., separator: String, terminator: String) -> Void
    
    /// If true, also logs response body data.
    public let verbose: Bool

    public init(verbose: Bool = false, output: (items: Any..., separator: String, terminator: String) -> Void = print) {
        self.verbose = verbose
        self.output = output
    }

    public func willSendRequest(request: RequestType, target: TargetType) {
        output(items: logNetworkRequest(request.request), separator: separator, terminator: terminator)
    }

    public func didReceiveResponse(result: Result<Moya.Response, Moya.Error>, target: TargetType) {
        if case .Success(let response) = result {
            output(items: logNetworkResponse(response.response, data: response.data, target: target), separator: separator, terminator: terminator)
        } else {
            output(items: logNetworkResponse(nil, data: nil, target: target), separator: separator, terminator: terminator)
        }
    }
}

private extension NetworkLoggerPlugin {

    private var date: String {
        dateFormatter.dateFormat = dateFormatString
        dateFormatter.locale = NSLocale(localeIdentifier: "en_US_POSIX")
        return dateFormatter.stringFromDate(NSDate())
    }

    private func format(loggerId: String, date: String, identifier: String, message: String) -> String {
        return "\(loggerId): [\(date)] \(identifier): \(message)"
    }
    
    func logNetworkRequest(request: NSURLRequest?) -> [String] {

        var output = [String]()

        output += [format(loggerId, date: date, identifier: "Request", message: request?.description ?? "(invalid request)")]

        if let headers = request?.allHTTPHeaderFields {
            output += [format(loggerId, date: date, identifier: "Request Headers", message: headers.description)]
        }

        if let bodyStream = request?.HTTPBodyStream {
            output += [format(loggerId, date: date, identifier: "Request Body Stream", message: bodyStream.description)]
        }

        if let httpMethod = request?.HTTPMethod {
            output += [format(loggerId, date: date, identifier: "HTTP Request Method", message: httpMethod)]
        }

        if let body = request?.HTTPBody where verbose == true {
            if let stringOutput = NSString(data: body, encoding: NSUTF8StringEncoding) as? String {
                output += [format(loggerId, date: date, identifier: "Request Body", message: stringOutput)]
            }
        }

        return output
    }

    func logNetworkResponse(response: NSURLResponse?, data: NSData?, target: TargetType) -> [String] {
        guard let response = response else {
           return [format(loggerId, date: date, identifier: "Response", message: "Received empty network response for \(target).")]
        }

        var output = [String]()

        output += [format(loggerId, date: date, identifier: "Response", message: response.description)]

        if let data = data, let stringData = NSString(data: data, encoding: NSUTF8StringEncoding) as? String where verbose == true {
            output += [stringData]
        }

        return output
    }
}
