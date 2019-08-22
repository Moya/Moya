import Foundation

/// Logs network activity (outgoing requests and incoming responses).
public final class NetworkLoggerPlugin {

    public let configuration: Configuration

    /// Initializes a NetworkLoggerPlugin.
    public init(configuration: Configuration = Configuration()) {
        self.configuration = configuration
    }
}

// MARK: - PluginType
extension NetworkLoggerPlugin: PluginType {
    public func willSend(_ request: RequestType, target: TargetType) {
        configuration.output(target, logNetworkRequest(request, target: target))
    }

    public func didReceive(_ result: Result<Moya.Response, MoyaError>, target: TargetType) {
        switch result {
        case .success(let response):
            configuration.output(target, logNetworkResponse(response, target: target, isFromError: false))
        case let .failure(error):
            configuration.output(target, logNetworkError(error, target: target))
        }
    }
}

// MARK: - Logging
private extension NetworkLoggerPlugin {

    func newEntry(identifier: String, message: String) -> String {
        let date = configuration.dateFormatter.string(from: Date())
        return "\(configuration.loggerId): [\(date)] \(identifier): \(message)"
    }

    func logNetworkRequest(_ request: RequestType, target: TargetType) -> [String] {

        //cURL formatting
        if configuration.logOptions.contains(.formatRequestAscURL),
            let request = request as? CustomDebugStringConvertible {
            return [newEntry(identifier: "Request", message: request.debugDescription)]
        }

        //Request presence check
        guard let httpRequest = request.request else {
            return [newEntry(identifier: "Request", message: "(invalid request)")]
        }

        // Adding log entries for each given log option
        var output = [String]()

        output.append(newEntry(identifier: "Request", message: httpRequest.description))

        if configuration.logOptions.contains(.requestHeaders) {
            var allHeaders = request.sessionHeaders
            if let httpRequestHeaders = httpRequest.allHTTPHeaderFields {
                allHeaders.merge(httpRequestHeaders) { $1 }
            }
            output.append(newEntry(identifier: "Request Headers", message: allHeaders.description))
        }

        if configuration.logOptions.contains(.requestBody) {
            if let bodyStream = httpRequest.httpBodyStream {
                output.append(newEntry(identifier: "Request Body Stream", message: bodyStream.description))
            }

            if let body = httpRequest.httpBody {
                let stringOutput = configuration.requestDataFormatter(body)
                output.append(newEntry(identifier: "Request Body", message: stringOutput))
            }
        }

        if configuration.logOptions.contains(.requestMethod),
            let httpMethod = httpRequest.httpMethod {
            output.append(newEntry(identifier: "HTTP Request Method", message: httpMethod))
        }

        return output
    }

    func logNetworkResponse(_ response: Response, target: TargetType, isFromError: Bool) -> [String] {

        //Response presence check
        guard let httpResponse = response.response else {
            return [newEntry(identifier: "Response", message: "Received empty network response for \(target).")]
        }

        // Adding log entries for each given log option
        var output = [String]()

        output.append(newEntry(identifier: "Response", message: httpResponse.description))

        if (isFromError && configuration.logOptions.contains(.errorResponseBody))
            || configuration.logOptions.contains(.successResponseBody) {

            let stringOutput = configuration.responseDataFormatter(response.data)
            output.append(newEntry(identifier: "Response Body", message: stringOutput))
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

// MARK: - Configuration
public extension NetworkLoggerPlugin {
    struct Configuration {

        public typealias OutputType = (_ target: TargetType, _ items: [String]) -> Void
        public typealias DataFormatterType = (Data) -> (String)

        fileprivate let loggerId: String
        fileprivate let dateFormatter: DateFormatter
        fileprivate let output: OutputType
        fileprivate let requestDataFormatter: DataFormatterType
        fileprivate let responseDataFormatter: DataFormatterType
        fileprivate let logOptions: LogOptions

        public init(loggerId: String = "Moya_Logger",
                    dateFormatter: DateFormatter = defaultDateFormatter,
                    output: @escaping OutputType = defaultOutput,
                    requestDataFormatter: @escaping DataFormatterType = defaultDataFormatter,
                    responseDataFormatter: @escaping DataFormatterType = defaultDataFormatter,
                    logOptions: LogOptions = .default) {
            self.loggerId = loggerId
            self.dateFormatter = dateFormatter
            self.output = output
            self.requestDataFormatter = requestDataFormatter
            self.responseDataFormatter = responseDataFormatter
            self.logOptions = logOptions
        }

        public static var defaultDateFormatter: DateFormatter {
            let formatter = DateFormatter()
            formatter.timeStyle = .short
            formatter.dateStyle = .short
            return formatter
        }

        public static func defaultOutput(target: TargetType, items: [String]) {
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
    struct LogOptions: OptionSet {
        public let rawValue: Int
        public init(rawValue: Int) { self.rawValue = rawValue }

        /// The request's method will be logged.
        public static let requestMethod: LogOptions = LogOptions(rawValue: 1 << 0)
        /// The request's body will be logged.
        public static let requestBody: LogOptions = LogOptions(rawValue: 1 << 1)
        /// The request's headers will be logged.
        public static let requestHeaders: LogOptions = LogOptions(rawValue: 1 << 2)
        /// The request will be logged in the cURL format.
        ///
        /// If this option is used, the following options are ignored: `requestMethod`, `requestBody`, `requestsHeaders`.
        public static let formatRequestAscURL: LogOptions = LogOptions(rawValue: 1 << 3)
        /// The body of a response that is a success will be logged.
        public static let successResponseBody: LogOptions = LogOptions(rawValue: 1 << 4)
        /// The body of a response that is an error will be logged.
        public static let errorResponseBody: LogOptions = LogOptions(rawValue: 1 << 5)

        //Aggregate options
        public static let `default`: LogOptions = [requestMethod, requestHeaders]
        public static let verbose: LogOptions = [requestMethod, requestHeaders, requestBody,
                                                 successResponseBody, errorResponseBody]
    }
}
