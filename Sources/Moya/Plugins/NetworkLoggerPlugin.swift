import Foundation

/// Logs network activity (outgoing requests and incoming responses).
public final class NetworkLoggerPlugin {

    public let configuration: Configuration

    /// Initializes a NetworkLoggerPlugin.
    public init(configuration: Configuration = Configuration()) {
        self.configuration = configuration
    }

    fileprivate func outputItems(_ items: [String], _ target: TargetType) {
        //TODO: Check why we output items one by one when verbose
        /*
         if isVerbose {
         items.forEach { output(separator, terminator, target, $0) }
         } else {
         output(separator, terminator, target, items)
         }
         */
        configuration.output(target, items)
    }
}

//MARK: - PluginType
extension NetworkLoggerPlugin: PluginType {
    public func willSend(_ request: RequestType, target: TargetType) {
        if configuration.requestLoggingOptions.contains(.formatAscURL),
            let request = request as? CustomDebugStringConvertible {
            //Don't use outputItems to prevent cURL being broken with additionnal terminators insertions
            let message = newEntry(identifier: "Request", message: request.debugDescription)
            configuration.output(target, message)
            return
        }

        outputItems(logNetworkRequest(request), target)
    }

    public func didReceive(_ result: Result<Moya.Response, MoyaError>, target: TargetType) {
        switch result {
        case .success(let response):
            outputItems(logNetworkResponse(response, target: target, isFromError: false), target)
        case let .failure(error):
            outputItems(logNetworkError(error, target: target), target)
        }
    }
}

//MARK: - Utils
private extension NetworkLoggerPlugin {

    func newEntry(identifier: String, message: String) -> String {
        let date = configuration.dateFormatter.string(from: Date())
        return "\(configuration.loggerId): [\(date)] \(identifier): \(message)"
    }

    func logNetworkRequest(_ request: RequestType) -> [String] {
        guard let httpRequest = request.request else {
            return [newEntry(identifier: "Request", message: "(invalid request)")]
        }

        var output = [String]()

        output.append(newEntry(identifier: "Request", message: httpRequest.description))

        if configuration.requestLoggingOptions.contains(.headers) {
            var allHeaders = request.sessionHeaders
            if let httpRequestHeaders = httpRequest.allHTTPHeaderFields {
                allHeaders.merge(httpRequestHeaders) { $1 }
            }
            output.append(newEntry(identifier: "Request Headers", message: allHeaders.description))
        }

        if configuration.requestLoggingOptions.contains(.body) {
            if let bodyStream = httpRequest.httpBodyStream {
                output.append(newEntry(identifier: "Request Body Stream", message: bodyStream.description))
            }

            if let body = httpRequest.httpBody {
                let stringOutput = configuration.requestDataFormatter(body)
                output.append(newEntry(identifier: "Request Body", message: stringOutput))
            }
        }

        if configuration.requestLoggingOptions.contains(.method),
            let httpMethod = httpRequest.httpMethod {
            output.append(newEntry(identifier: "HTTP Request Method", message: httpMethod))
        }

        return output
    }

    func logNetworkResponse(_ response: Response, target: TargetType, isFromError: Bool) -> [String] {
        guard let httpResponse = response.response else {
            return [newEntry(identifier: "Response", message: "Received empty network response for \(target).")]
        }

        var output = [String]()

        output.append(newEntry(identifier: "Response", message: httpResponse.description))

        if (isFromError && configuration.errorResponseLoggingOptions.contains(.body))
            || configuration.successResponseLoggingOptions.contains(.body) {

            let stringOutput = configuration.responseDataFormatter(response.data)
            output.append(newEntry(identifier: "Body", message: stringOutput))
        }

        return output
    }


    func logNetworkError(_ error: MoyaError, target: TargetType) -> [String] {
        //Some errors will still have a response, like errors due to Alamofire's HTTP code validation.
        if let moyaResponse = error.response {
            return logNetworkResponse(moyaResponse, target: target, isFromError: true)
        }

        //Errors without an HTTPURLResponse are those due to connectivity, time-out and such.
        return [newEntry(identifier: "Error", message: "Error calling \(target) : \(error)")]
    }
}

//MARK: - COnfiguration
public extension NetworkLoggerPlugin {
    struct Configuration {

        public typealias OutputType = (_ target: TargetType, _ items: Any...) -> Void
        public typealias DataFormatterType = (Data) -> (String)

        fileprivate let loggerId: String
        fileprivate let dateFormatter: DateFormatter
        fileprivate let output: OutputType
        fileprivate let requestDataFormatter: DataFormatterType
        //fileprivate let responseDataFormatter: ((Data) -> (Data))?
        fileprivate let responseDataFormatter: DataFormatterType
        fileprivate let requestLoggingOptions: RequestLogOptions
        fileprivate let successResponseLoggingOptions: ResponseLogOptions
        fileprivate let errorResponseLoggingOptions: ResponseLogOptions

        public init(loggerId: String = "Moya_Logger",
                    dateFormatter: DateFormatter = defaultDateFormatter,
                    output: @escaping OutputType = defaultOutput,
                    requestDataFormatter: @escaping DataFormatterType = defaultDataFormatter,
                    responseDataFormatter: @escaping DataFormatterType = defaultDataFormatter,
                    requestLoggingOptions: RequestLogOptions = .default,
                    successResponseLoggingOptions: ResponseLogOptions = .default,
                    errorResponseLoggingOptions: ResponseLogOptions = .default) {
            self.loggerId = loggerId
            self.dateFormatter = dateFormatter
            self.output = output
            self.requestDataFormatter = requestDataFormatter
            self.responseDataFormatter = responseDataFormatter
            self.requestLoggingOptions = requestLoggingOptions
            self.successResponseLoggingOptions = successResponseLoggingOptions
            self.errorResponseLoggingOptions = errorResponseLoggingOptions
        }

        public static var defaultDateFormatter: DateFormatter {
            let formatter = DateFormatter()
            formatter.timeStyle = .short
            formatter.dateStyle = .short
            return formatter
        }

        public static func defaultOutput(target: TargetType, items: Any...) {
            for item in items {
                print(item, separator: ",", terminator: "\n")
            }
        }

        public static func defaultDataFormatter(_ data: Data) -> String {
            return String(data: data, encoding: .utf8) ?? "## Cannot map data to String ##"
        }
    }
}

public extension NetworkLoggerPlugin.Configuration {
    struct RequestLogOptions: OptionSet {
        public let rawValue: Int
        public init(rawValue: Int) { self.rawValue = rawValue }

        public static let method:       RequestLogOptions = RequestLogOptions(rawValue: 1 << 0)
        public static let body:         RequestLogOptions = RequestLogOptions(rawValue: 1 << 1)
        public static let headers:      RequestLogOptions = RequestLogOptions(rawValue: 1 << 2)
        public static let formatAscURL: RequestLogOptions = RequestLogOptions(rawValue: 1 << 3)

        public static let `default`:    RequestLogOptions = [method, headers]
        public static let verbose:      RequestLogOptions = [method, headers, body]
    }

    struct ResponseLogOptions: OptionSet {
        public let rawValue: Int
        public init(rawValue: Int) { self.rawValue = rawValue }

        public static let body:         ResponseLogOptions = ResponseLogOptions(rawValue: 1 << 0)

        public static let `default`:    ResponseLogOptions = []
        public static let verbose:      ResponseLogOptions = [body]
    }
}
