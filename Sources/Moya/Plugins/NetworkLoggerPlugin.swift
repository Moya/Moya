import Foundation

/// Logs network activity (outgoing requests and incoming responses).
public final class NetworkLoggerPlugin: PluginType {
    fileprivate let loggerId = "Moya_Logger"
    fileprivate let dateFormatString = "dd/MM/yyyy HH:mm:ss"
    fileprivate let dateFormatter = DateFormatter()
    fileprivate let separator = ", "
    fileprivate let terminator = "\n"
    fileprivate let cURLTerminator = "\\\n"
    fileprivate let output: (_ separator: String, _ terminator: String, _ target: TargetType, _ items: Any...) -> Void
    fileprivate let requestDataFormatter: ((Data) -> (String))?
    fileprivate let responseDataFormatter: ((Data) -> (Data))?

    /// A Boolean value determing whether response body data should be logged.
    public let isVerbose: Bool
    public let cURL: Bool

    /// Initializes a NetworkLoggerPlugin.
    public init(verbose: Bool = false, cURL: Bool = false, output: ((_ separator: String, _ terminator: String, _ target: TargetType, _ items: Any...) -> Void)? = nil, requestDataFormatter: ((Data) -> (String))? = nil, responseDataFormatter: ((Data) -> (Data))? = nil) {
        self.cURL = cURL
        self.isVerbose = verbose
        self.output = output ?? NetworkLoggerPlugin.reversedPrint
        self.requestDataFormatter = requestDataFormatter
        self.responseDataFormatter = responseDataFormatter
    }

    public func willSend(_ request: RequestType, target: TargetType) {
        if let request = request as? CustomDebugStringConvertible, cURL {
            output(separator, terminator, target, request.debugDescription)
            return
        }
        outputItems(logNetworkRequest(request.request as URLRequest?), target)
    }

    public func didReceive(_ result: Result<Moya.Response, MoyaError>, target: TargetType) {
        switch result {
        case .success(let response):
            outputItems(logNetworkResponse(response, target: target, isFromError: false), target)
        case let .failure(error):
            outputItems(logNetworkError(error, target: target), target)
        }
    }

    fileprivate func outputItems(_ items: [String], _ target: TargetType) {
        if isVerbose {
            items.forEach { output(separator, terminator, target, $0) }
        } else {
            output(separator, terminator, target, items)
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

        if let body = request?.httpBody, let stringOutput = requestDataFormatter?(body) ?? String(data: body, encoding: .utf8), isVerbose {
            output += [format(loggerId, date: date, identifier: "Request Body", message: stringOutput)]
        }

        return output
    }

    func logNetworkResponse(_ response: Response, target: TargetType, isFromError: Bool) -> [String] {
        guard let httpResponse = response.response else {
            return [format(loggerId, date: date, identifier: "Response", message: "Received empty network response for \(target).")]
        }

        var output = [String]()

        output += [format(loggerId, date: date, identifier: "Response", message: httpResponse.description)]

        if let stringData = String(data: responseDataFormatter?(response.data) ?? response.data, encoding: String.Encoding.utf8),
            isFromError || isVerbose {
            output += ["Body: " + stringData]
        }

        return output
      }

      func logNetworkError(_ error: MoyaError, target: TargetType) -> [String] {
          //Some errors will still have a response, like errors due to Alamofire's HTTP code validation.
          if let moyaResponse = error.response {
              return logNetworkResponse(moyaResponse, target: target, isFromError: true)
          }

          //Errors without an HTTPURLResponse are those due to connectivity, time-out and such.
          return [format(loggerId, date: date, identifier: "Error", message: "Error calling \(target) : \(error)")]
      }
}

fileprivate extension NetworkLoggerPlugin {
    static func reversedPrint(_ separator: String, terminator: String, target: TargetType, items: Any...) {
        for item in items {
            print(item, separator: separator, terminator: terminator)
        }
    }
}
