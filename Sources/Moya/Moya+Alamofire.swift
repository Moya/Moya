import Foundation
import Alamofire

public typealias Manager = Alamofire.SessionManager
internal typealias Request = Alamofire.Request
internal typealias DownloadRequest = Alamofire.DownloadRequest
internal typealias UploadRequest = Alamofire.UploadRequest
internal typealias DataRequest = Alamofire.DataRequest

internal typealias URLRequestConvertible = Alamofire.URLRequestConvertible

/// Represents an HTTP method.
public typealias Method = Alamofire.HTTPMethod

/// Choice of parameter encoding.
public typealias ParameterEncoding = Alamofire.ParameterEncoding
public typealias JSONEncoding = Alamofire.JSONEncoding
public typealias URLEncoding = Alamofire.URLEncoding
public typealias PropertyListEncoding = Alamofire.PropertyListEncoding

/// Multipart form
public typealias RequestMultipartFormData = Alamofire.MultipartFormData

/// Multipart form data encoding result.
public typealias MultipartFormDataEncodingResult = Manager.MultipartFormDataEncodingResult
public typealias DownloadDestination = Alamofire.DownloadRequest.DownloadFileDestination

/// Make the Alamofire Request type conform to our type, to prevent leaking Alamofire to plugins.
extension Request: RequestType { }

/// Internal token that can be used to cancel requests
public final class CancellableToken: Cancellable, CustomDebugStringConvertible {
    let cancelAction: () -> Void
    let request: Request?
    public fileprivate(set) var isCancelled = false

    fileprivate var lock: DispatchSemaphore = DispatchSemaphore(value: 1)

    public func cancel() {
        _ = lock.wait(timeout: DispatchTime.distantFuture)
        defer { lock.signal() }
        guard !isCancelled else { return }
        isCancelled = true
        cancelAction()
    }

    public init(action: @escaping () -> Void) {
        self.cancelAction = action
        self.request = nil
    }

    init(request: Request) {
        self.request = request
        self.cancelAction = {
            request.cancel()
        }
    }

    public var debugDescription: String {
        guard let request = self.request else {
            return "Empty Request"
        }
        return request.debugDescription
    }

}

internal typealias RequestableCompletion = (HTTPURLResponse?, URLRequest?, Data?, Swift.Error?) -> Void

internal protocol Requestable {
    func response(queue: DispatchQueue?, completionHandler: @escaping RequestableCompletion) -> Self
}

extension DataRequest: Requestable {
    internal func response(queue: DispatchQueue?, completionHandler: @escaping RequestableCompletion) -> Self {
        return response(queue: queue) { handler  in
            completionHandler(handler.response, handler.request, handler.data, handler.error)
        }
    }
}

extension DownloadRequest: Requestable {
    internal func response(queue: DispatchQueue?, completionHandler: @escaping RequestableCompletion) -> Self {
        return response(queue: queue) { handler  in
            completionHandler(handler.response, handler.request, nil, handler.error)
        }
    }
}
