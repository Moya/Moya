import Foundation
import Result

/// Logs network activity (outgoing requests and incoming responses).
public final class NetworkLoggerPlugin: PluginType {
    fileprivate let loggerId = "Moya_Logger"
    fileprivate let dateFormatString = "dd/MM/yyyy HH:mm:ss"
    fileprivate let dateFormatter = DateFormatter()
    fileprivate let separator = ", "
    fileprivate let terminator = "\n"
    fileprivate let cURLTerminator = "\\\n"
    fileprivate let output: (_ seperator: String, _ terminator: String, _ items: Any...) -> Void
    fileprivate let responseDataFormatter: ((Data) -> (Data))?

    /// If true, also logs response body data.
    public let verbose: Bool
    public let cURL: Bool

    public init(verbose: Bool = false, cURL: Bool = false, output: @escaping (_ seperator: String, _ terminator: String, _ items: Any...) -> Void = NetworkLoggerPlugin.reversedPrint, responseDataFormatter: ((Data) -> (Data))? = nil) {
        self.cURL = cURL
        self.verbose = verbose
        self.output = output
        self.responseDataFormatter = responseDataFormatter
    }

    public func willSendRequest(_ request: RequestType, target: TargetType) {
        if let request = request as? CustomDebugStringConvertible, cURL {
            output(separator, terminator, request.debugDescription)
            return
        }
        outputItems(logNetworkRequest(request.request as URLRequest?))
    }

    public func didReceiveResponse(_ result: Result<Moya.Response, Moya.Error>, target: TargetType) {
        if case .success(let response) = result {
            outputItems(logNetworkResponse(response.response, data: response.data, target: target))
        } else {
            outputItems(logNetworkResponse(nil, data: nil, target: target))
        }
    }

    fileprivate func outputItems(_ items: [String]) {
        if verbose {
            items.forEach { output(separator, terminator, $0) }
        } else {
            output(separator, terminator, items)
        }
    }
}

private extension NetworkLoggerPlugin {

    var date: String {
        dateFormatter.dateFormat = dateFormatString
        dateFormatter.locale = Locale(identifier: "en_US_POSIX")
        return dateFormatter.string(from: Date())
    }

    func format(_ loggerId: String, date: String, identifier: String, message: String) -> String {
        return "\(loggerId): [\(date)] \(identifier): \(message)"
    }

    func logNetworkRequest(_ request: URLRequest?) -> [String] {

        var output = [String]()

        output += [format(loggerId, date: date, identifier: "Request", message: request?.description ?? "(invalid request)")]

        if let headers = request?.allHTTPHeaderFields {
            output += [format(loggerId, date: date, identifier: "Request Headers", message: headers.description)]
        }

        if let bodyStream = request?.httpBodyStream {
            output += [format(loggerId, date: date, identifier: "Request Body Stream", message: bodyStream.description)]
        }

        if let httpMethod = request?.httpMethod {
            output += [format(loggerId, date: date, identifier: "HTTP Request Method", message: httpMethod)]
        }

        if let body = request?.httpBody, verbose == true {
            if let stringOutput = NSString(data: body, encoding: String.Encoding.utf8.rawValue) as? String {
                output += [format(loggerId, date: date, identifier: "Request Body", message: stringOutput)]
            }
        }

        return output
    }

    func logNetworkResponse(_ response: URLResponse?, data: Data?, target: TargetType) -> [String] {
        guard let response = response else {
           return [format(loggerId, date: date, identifier: "Response", message: "Received empty network response for \(target).")]
        }

        var output = [String]()

        output += [format(loggerId, date: date, identifier: "Response", message: response.description)]

        if let data = data, verbose == true {
            if let stringData = String(data: responseDataFormatter?(data) ?? data, encoding: String.Encoding.utf8) {
                output += [stringData]
            }
        }

        return output
    }
}

fileprivate extension NetworkLoggerPlugin {
    static func reversedPrint(seperator: String, terminator: String, items: Any...) {
        print(items, separator: seperator, terminator: terminator)
    }
}
