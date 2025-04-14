import Foundation
import Result
import Combine

public enum NetworkLogEvent {
    case requestCreated(request: URLRequest, requestId: UUID)
    case responseDataReceived(data: Data, requestId: UUID)
    case requestCompleted(response: URLResponse?, data: Data?, error: Error?, requestId: UUID, metrics: URLSessionTaskMetrics?)
    case progressUpdated(completed: Int64, total: Int64, requestId: UUID)
}

public final class NetworkLoggerPlugin: PluginType {
    fileprivate let loggerId = "Moya_Logger"
    fileprivate let dateFormatString = "dd/MM/yyyy HH:mm:ss"
    fileprivate let dateFormatter = DateFormatter()
    fileprivate let separator = ", "
    fileprivate let terminator = "\n"
    fileprivate let cURLTerminator = "\\\n"
    
    public let logSubject: PassthroughSubject<NetworkLogEvent, Never>
    
    fileprivate let requestDataFormatter: ((Data) -> (String))?
    fileprivate let responseDataFormatter: ((Data) -> (Data))?

    public let isVerbose: Bool
    public let cURL: Bool
    
    private var requestIds: [String: UUID] = [:]
    
    public init(
        verbose: Bool = false,
        cURL: Bool = false,
        requestDataFormatter: ((Data) -> (String))? = nil,
        responseDataFormatter: ((Data) -> (Data))? = nil
    ) {
        self.cURL = cURL
        self.isVerbose = verbose
        self.requestDataFormatter = requestDataFormatter
        self.responseDataFormatter = responseDataFormatter
        self.logSubject = PassthroughSubject<NetworkLogEvent, Never>()
    }

    public func willSend(_ request: RequestType, target: TargetType) {
        if let request = request as? CustomDebugStringConvertible, cURL {
            return
        }
        guard let urlRequest = request.request as URLRequest? else { return }
        
        let requestId = UUID()
        if let urlString = urlRequest.url?.absoluteString {
            requestIds[urlString] = requestId
        }
        logSubject.send(.requestCreated(request: urlRequest, requestId: requestId))
        
        if isVerbose {
            let logItems = logNetworkRequest(urlRequest)
            logItems.forEach { print($0 + terminator) }
        }
    }

    public func didReceive(_ result: Result<Moya.Response, MoyaError>, target: TargetType) {
            let startDate = Date()
            
            if case .success(let response) = result {
                guard let urlRequest = response.request,
                      let urlString = urlRequest.url?.absoluteString,
                      let requestId = requestIds[urlString] else { return }
                
                logSubject.send(.responseDataReceived(data: response.data, requestId: requestId))
                
                let endDate = Date()
                let duration = endDate.timeIntervalSince(startDate)
                
                logSubject.send(.requestCompleted(
                    response: response.response,
                    data: response.data,
                    error: nil,
                    requestId: requestId,
                    metrics: nil
                ))
                
                requestIds.removeValue(forKey: urlString)
                
                if isVerbose {
                    let logItems = logNetworkResponse(response.response, data: response.data, target: target)
                    logItems.forEach { print($0 + terminator) }
                }
            } else if case .failure(let error) = result {
                let urlRequest = error.response?.request ?? URLRequest(url: target.baseURL)
                guard let urlString = urlRequest.url?.absoluteString,
                      let requestId = requestIds[urlString] else { return }
                
                let endDate = Date()
                let duration = endDate.timeIntervalSince(startDate)
                
                logSubject.send(.requestCompleted(
                    response: error.response?.response,
                    data: error.response?.data,
                    error: error,
                    requestId: requestId,
                    metrics: nil
                ))
                
                requestIds.removeValue(forKey: urlString)
                
                if isVerbose {
                    let logItems = logNetworkResponse(nil, data: nil, target: target)
                    logItems.forEach { print($0 + terminator) }
                }
            }
        }
    // Остальные методы для форматирования логов (для отладки)
    private var date: String {
        dateFormatter.dateFormat = dateFormatString
        dateFormatter.locale = Locale(identifier: "en_US_POSIX")
        return dateFormatter.string(from: Date())
    }

    private func format(_ loggerId: String, date: String, identifier: String, message: String) -> String {
        return "\(loggerId): [\(date)] \(identifier): \(message)"
    }

    private func logNetworkRequest(_ request: URLRequest?) -> [String] {
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

    private func logNetworkResponse(_ response: HTTPURLResponse?, data: Data?, target: TargetType) -> [String] {
        guard let response = response else {
            return [format(loggerId, date: date, identifier: "Response", message: "Received empty network response for \(target).")]
        }
        var output = [String]()
        output += [format(loggerId, date: date, identifier: "Response", message: response.description)]
        if let data = data, let stringData = String(data: responseDataFormatter?(data) ?? data, encoding: .utf8), isVerbose {
            output += [stringData]
        }
        return output
    }
}

extension NetworkLoggerPlugin {
    public func logPublisher() -> AnyPublisher<NetworkLogEvent, Never> {
        logSubject.eraseToAnyPublisher()
    }
}
