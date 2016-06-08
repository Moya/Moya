import Foundation
import Result

/// Logs network activity (outgoing requests and incoming responses).
public final class NetworkLoggerPlugin: PluginType {
    private let loggerId = "Moya_Logger"
    private let dateFormatString = "dd/MM/yyyy HH:mm:ss"
    private let dateFormatter = NSDateFormatter()
    private let separator = ", "
    private let terminator = "\n"
    private let cURLTerminator = "\\\n"
    private let output: (items: Any..., separator: String, terminator: String) -> Void
    private let responseDataFormatter: ((NSData) -> (NSData))?
    
    /// If true, also logs response body data.
    public let verbose: Bool
    public let cURL: Bool

    public init(verbose: Bool = false, cURL: Bool = false, output: (items: Any..., separator: String, terminator: String) -> Void = print, responseDataFormatter: ((NSData) -> (NSData))? = nil) {
        self.cURL = cURL
        self.verbose = verbose
        self.output = output
        self.responseDataFormatter = responseDataFormatter
    }

    public func willSendRequest(request: RequestType, session: NSURLSession, target: TargetType) {
        outputRequestItems(logNetworkRequest(request.request, session: session))
    }

    public func didReceiveResponse(result: Result<Moya.Response, Moya.Error>, session: NSURLSession, target: TargetType) {
        if case .Success(let response) = result {
            outputItems(logNetworkResponse(response.response, data: response.data, target: target))
        } else {
            outputItems(logNetworkResponse(nil, data: nil, target: target))
        }
    }

    private func outputRequestItems(items: [String]) {
        if cURL {
            items.joinWithSeparator(" \\\n\t")
        } else {
            outputItems(items)
        }
    }

    private func outputItems(items: [String]) {
        if verbose {
            items.forEach { output(items: $0, separator: separator, terminator: terminator) }
        } else {
            output(items: items, separator: separator, terminator: terminator)
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
    
    func logNetworkRequest(request: NSURLRequest?, session: NSURLSession) -> [String] {

        guard !cURL else {
            return NetworkLoggerPlugin.curlRepresentation(request, session: session)
        }

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

        if let data = data where verbose == true {
            if let stringData = String(data: responseDataFormatter?(data) ?? data , encoding: NSUTF8StringEncoding) {
                output += [stringData]
            }
        }

        return output
    }
}

// MARK: cURL
extension NetworkLoggerPlugin {

  private class func curlRepresentation(request: NSURLRequest?, session: NSURLSession?) -> [String] {
    var components = ["$ curl -i"]

    guard let
      request = request,
      URL = request.URL,
      host = URL.host,
      session = session
      else {
        return ["$ curl command could not be created"]
    }

    if let HTTPMethod = request.HTTPMethod where HTTPMethod != "GET" {
      components.append("-X \(HTTPMethod)")
    }

    if let credentialStorage = session.configuration.URLCredentialStorage {
      let protectionSpace = NSURLProtectionSpace(
        host: host,
        port: URL.port?.integerValue ?? 0,
        protocol: URL.scheme,
        realm: host,
        authenticationMethod: NSURLAuthenticationMethodHTTPBasic
      )

      if let credentials = credentialStorage.credentialsForProtectionSpace(protectionSpace)?.values {
        for credential in credentials {
          components.append("-u \(credential.user!):\(credential.password!)")
        }
      }
    }

    if session.configuration.HTTPShouldSetCookies {
      if let
        cookieStorage = session.configuration.HTTPCookieStorage,
        cookies = cookieStorage.cookiesForURL(URL) where !cookies.isEmpty
      {
        let string = cookies.reduce("") { $0 + "\($1.name)=\($1.value ?? String());" }
        components.append("-b \"\(string.substringToIndex(string.endIndex.predecessor()))\"")
      }
    }

    var headers: [NSObject: AnyObject] = [:]

    if let additionalHeaders = session.configuration.HTTPAdditionalHeaders {
      for (field, value) in additionalHeaders where field != "Cookie" {
        headers[field] = value
      }
    }

    if let headerFields = request.allHTTPHeaderFields {
      for (field, value) in headerFields where field != "Cookie" {
        headers[field] = value
      }
    }

    for (field, value) in headers {
      components.append("-H \"\(field): \(value)\"")
    }

    if let
      HTTPBodyData = request.HTTPBody,
      HTTPBody = String(data: HTTPBodyData, encoding: NSUTF8StringEncoding)
    {
      var escapedBody = HTTPBody.stringByReplacingOccurrencesOfString("\\\"", withString: "\\\\\"")
      escapedBody = escapedBody.stringByReplacingOccurrencesOfString("\"", withString: "\\\"")

      components.append("-d \"\(escapedBody)\"")
    }

    components.append("\"\(URL.absoluteString)\"")

    return components
  }
}
