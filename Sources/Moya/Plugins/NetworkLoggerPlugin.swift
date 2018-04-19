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
    fileprivate let output: (_ separator: String, _ terminator: String, _ items: Any...) -> Void
    fileprivate let outputFormat: (_ loggerId: String, _ date: String, _ identifier: String, _ message: String) -> String
    fileprivate let requestDataFormatter: ((Data) -> (String))?
    fileprivate let responseDataFormatter: ((Data) -> (Data))?

    /// A Boolean value determing whether response body data should be logged.
    public let isVerbose: Bool
    public let cURL: Bool

    /// Initializes a NetworkLoggerPlugin.
    public init(verbose: Bool = false,
                cURL: Bool = false,
                output: ((_ separator: String, _ terminator: String, _ items: Any...) -> Void)? = nil,
                outputFormat: ((_ loggerId: String, _ date: String, _ identifier: String, _ message: String) -> String)? = nil,
                requestDataFormatter: ((Data) -> (String))? = nil,
                responseDataFormatter: ((Data) -> (Data))? = nil) {
        self.cURL = cURL
        self.isVerbose = verbose
        self.output = output ?? NetworkLoggerPlugin.reversedPrint
        self.outputFormat = outputFormat ?? NetworkLoggerPlugin.printFormatter
        self.requestDataFormatter = requestDataFormatter
        self.responseDataFormatter = responseDataFormatter
    }

    public func willSend(_ request: RequestType, target: TargetType) {
        if let request = request as? CustomDebugStringConvertible, cURL {
            output(separator, terminator, request.debugDescription)
            return
        }
        outputItems(logNetworkRequest(request.request as URLRequest?))
    }

    public func didReceive(_ result: Result<Moya.Response, MoyaError>, target: TargetType) {
        if case .success(let response) = result {
            outputItems(logNetworkResponse(response.response, data: response.data, target: target))
        } else {
            outputItems(logNetworkResponse(nil, data: nil, target: target))
        }
    }

    fileprivate func outputItems(_ items: [String]) {
        if isVerbose {
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

    func logNetworkRequest(_ request: URLRequest?) -> [String] {

        var output = [String]()

        output += [outputFormat(loggerId, date, "Request", request?.description ?? "(invalid request)")]

        if let headers = request?.allHTTPHeaderFields {
            output += [outputFormat(loggerId, date, "Request Headers", headers.description)]
        }

        if let bodyStream = request?.httpBodyStream {
            output += [outputFormat(loggerId, date, "Request Body Stream", bodyStream.description)]
        }

        if let httpMethod = request?.httpMethod {
            output += [outputFormat(loggerId, date, "HTTP Request Method", httpMethod)]
        }

        if let body = request?.httpBody, let stringOutput = requestDataFormatter?(body) ?? String(data: body, encoding: .utf8), isVerbose {
            output += [outputFormat(loggerId, date, "Request Body", stringOutput)]
        }

        return output
    }

    func logNetworkResponse(_ response: HTTPURLResponse?, data: Data?, target: TargetType) -> [String] {
        guard let response = response else {
            return [outputFormat(loggerId, date, "Response", "Received empty network response for \(target).")]
        }

        var output = [String]()

        output += [outputFormat(loggerId, date, "Response", response.description)]

        if let data = data, let stringData = String(data: responseDataFormatter?(data) ?? data, encoding: String.Encoding.utf8), isVerbose {
            output += [stringData]
        }

        return output
    }
}

fileprivate extension NetworkLoggerPlugin {
    static func reversedPrint(_ separator: String, terminator: String, items: Any...) {
        for item in items {
            print(item, separator: separator, terminator: terminator)
        }
    }

    static func printFormatter(_ loggerId: String, date: String, identifier: String, message: String) -> String {
        return "\(loggerId): [\(date)] \(identifier): \(message)"
    }
}
