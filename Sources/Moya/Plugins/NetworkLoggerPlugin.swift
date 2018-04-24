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
    fileprivate let output: NetworkLoggerOutput
    fileprivate let requestDataFormatter: ((Data) -> (String))?
    fileprivate let responseDataFormatter: ((Data) -> (Data))?

    /// A Boolean value determing whether response body data should be logged.
    public let isVerbose: Bool
    public let cURL: Bool

    /// Initializes a NetworkLoggerPlugin.
    public init(verbose: Bool = false,
                cURL: Bool = false,
                output: NetworkLoggerOutput = DefaultNetworkLoggerOutput(),
                requestDataFormatter: ((Data) -> (String))? = nil,
                responseDataFormatter: ((Data) -> (Data))? = nil) {
        self.cURL = cURL
        self.isVerbose = verbose
        self.output = output
        self.requestDataFormatter = requestDataFormatter
        self.responseDataFormatter = responseDataFormatter
    }

    public func willSend(_ request: RequestType, target: TargetType) {
        if let request = request as? CustomDebugStringConvertible, cURL {
            output.print(separator, terminator: terminator, items: request.debugDescription)
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
            items.forEach { output.print(separator, terminator: terminator, items: $0) }
        } else {
            output.print(separator, terminator: terminator, items: items)
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

        var outputResult = [String]()

        outputResult += [output.format(loggerId, date: date, identifier: "Request", message: request?.description ?? "(invalid request)")]

        if let headers = request?.allHTTPHeaderFields {
            outputResult += [output.format(loggerId, date: date, identifier: "Request Headers", message: headers.description)]
        }

        if let bodyStream = request?.httpBodyStream {
            outputResult += [output.format(loggerId, date: date, identifier: "Request Body Stream", message: bodyStream.description)]
        }

        if let httpMethod = request?.httpMethod {
            outputResult += [output.format(loggerId, date: date, identifier: "HTTP Request Method", message: httpMethod)]
        }

        if let body = request?.httpBody, let stringOutput = requestDataFormatter?(body) ?? String(data: body, encoding: .utf8), isVerbose {
            outputResult += [output.format(loggerId, date: date, identifier: "Request Body", message: stringOutput)]
        }

        return outputResult
    }

    func logNetworkResponse(_ response: HTTPURLResponse?, data: Data?, target: TargetType) -> [String] {
        guard let response = response else {
            return [output.format(loggerId, date: date, identifier: "Response", message: "Received empty network response for \(target).")]
        }

        var outputResult = [String]()

        outputResult += [output.format(loggerId, date: date, identifier: "Response", message: response.description)]

        if let data = data, let stringData = String(data: responseDataFormatter?(data) ?? data, encoding: String.Encoding.utf8), isVerbose {
            outputResult += [stringData]
        }

        return outputResult
    }
}
