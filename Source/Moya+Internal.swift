import Foundation
import Result

/// Internal extension to keep the inner-workings outside the main Moya.swift file.
internal extension MoyaProvider {
    internal func requestNormal(target: Target, queue: dispatch_queue_t?, progress: Moya.ProgressBlock?, completion: Moya.Completion) -> Cancellable {
        let endpoint = self.endpoint(target)
        let stubBehavior = self.stubClosure(target)
        let cancellableToken = CancellableWrapper()

        if trackInflights {
            objc_sync_enter(self)
            var inflightCompletionBlocks = self.inflightRequests[endpoint]
            inflightCompletionBlocks?.append(completion)
            self.inflightRequests[endpoint] = inflightCompletionBlocks
            objc_sync_exit(self)

            if inflightCompletionBlocks != nil {
                return cancellableToken
            } else {
                objc_sync_enter(self)
                self.inflightRequests[endpoint] = [completion]
                objc_sync_exit(self)
            }
        }

        let performNetworking = { (requestResult: Result<NSURLRequest, Moya.Error>) in
            if cancellableToken.cancelled {
                self.cancelCompletion(completion, target: target)
                return
            }

            var request: NSURLRequest!

            switch requestResult {
            case .Success(let urlRequest):
                request = urlRequest
            case .Failure(let error):
                completion(result: .Failure(error))
                return
            }

            switch stubBehavior {
            case .Never:
                let networkCompletion: Moya.Completion = { result in
                    if self.trackInflights {
                        self.inflightRequests[endpoint]?.forEach({ $0(result: result) })

                        objc_sync_enter(self)
                        self.inflightRequests.removeValueForKey(endpoint)
                        objc_sync_exit(self)
                    } else {
                        completion(result: result)
                    }
                }
                switch target.task {
                case .Request:
                    cancellableToken.innerCancellable = self.sendRequest(target, request: request, queue: queue, progress: progress, completion: networkCompletion)
                case .Upload(.File(let file)):
                    cancellableToken.innerCancellable = self.sendUploadFile(target, request: request, queue: queue, file: file, progress: progress, completion: networkCompletion)
                case .Upload(.Multipart(let multipartBody)):
                    guard !multipartBody.isEmpty && (target.method == .POST || target.method == .PUT) else {
                        fatalError("\(target) is not a multipart upload target.")
                    }
                    cancellableToken.innerCancellable = self.sendUploadMultipart(target, request: request, queue: queue, multipartBody: multipartBody, progress: progress, completion: networkCompletion)
                case .Download(.Request(let destination)):
                    cancellableToken.innerCancellable = self.sendDownloadRequest(target, request: request, queue: queue, destination: destination, progress: progress, completion: networkCompletion)
                }
            default:
                cancellableToken.innerCancellable = self.stubRequest(target, request: request, completion: { result in
                    if self.trackInflights {
                        self.inflightRequests[endpoint]?.forEach({ $0(result: result) })

                        objc_sync_enter(self)
                        self.inflightRequests.removeValueForKey(endpoint)
                        objc_sync_exit(self)
                    } else {
                        completion(result: result)
                    }
                    }, endpoint: endpoint, stubBehavior: stubBehavior)
            }
        }

        requestClosure(endpoint, performNetworking)

        return cancellableToken
    }

    internal func cancelCompletion(completion: Moya.Completion, target: Target) {
        let error = Moya.Error.Underlying(NSError(domain: NSURLErrorDomain, code: NSURLErrorCancelled, userInfo: nil))
        plugins.forEach { $0.didReceiveResponse(.Failure(error), target: target) }
        completion(result: .Failure(error))
    }

    /// When overriding this method, take care to `notifyPluginsOfImpendingStub` and to perform the stub using the `createStubFunction` method.
    /// Note: this was previously in an extension, however it must be in the original class declaration to allow subclasses to override.
    internal func stubRequest(target: Target, request: NSURLRequest, completion: Moya.Completion, endpoint: Endpoint<Target>, stubBehavior: Moya.StubBehavior) -> CancellableToken {
        let cancellableToken = CancellableToken { }
        notifyPluginsOfImpendingStub(request, target: target)
        let plugins = self.plugins
        let stub: () -> () = createStubFunction(cancellableToken, forTarget: target, withCompletion: completion, endpoint: endpoint, plugins: plugins)
        switch stubBehavior {
        case .Immediate:
            stub()
        case .Delayed(let delay):
            let killTimeOffset = Int64(CDouble(delay) * CDouble(NSEC_PER_SEC))
            let killTime = dispatch_time(DISPATCH_TIME_NOW, killTimeOffset)
            dispatch_after(killTime, dispatch_get_main_queue()) {
                stub()
            }
        case .Never:
            fatalError("Method called to stub request when stubbing is disabled.")
        }
        
        return cancellableToken
    }


    /// Creates a function which, when called, executes the appropriate stubbing behavior for the given parameters.
    internal final func createStubFunction(token: CancellableToken, forTarget target: Target, withCompletion completion: Moya.Completion, endpoint: Endpoint<Target>, plugins: [PluginType]) -> (() -> ()) {
        return {
            if token.cancelled {
                self.cancelCompletion(completion, target: target)
                return
            }

            switch endpoint.sampleResponseClosure() {
            case .NetworkResponse(let statusCode, let data):
                let response = Moya.Response(statusCode: statusCode, data: data, response: nil)
                plugins.forEach { $0.didReceiveResponse(.Success(response), target: target) }
                completion(result: .Success(response))
            case .NetworkError(let error):
                let error = Moya.Error.Underlying(error)
                plugins.forEach { $0.didReceiveResponse(.Failure(error), target: target) }
                completion(result: .Failure(error))
            }
        }
    }

    /// Notify all plugins that a stub is about to be performed. You must call this if overriding `stubRequest`.
    internal final func notifyPluginsOfImpendingStub(request: NSURLRequest, target: Target) {
        let alamoRequest = manager.request(request)
        plugins.forEach { $0.willSendRequest(alamoRequest, target: target) }
    }
}

private extension Moya {
    private func sendUploadMultipart(target: Target, request: NSURLRequest, queue: dispatch_queue_t?, multipartBody: [MultipartFormData], progress: Moya.ProgressBlock? = nil, completion: Moya.Completion) -> CancellableWrapper {
        let cancellable = CancellableWrapper()

        let multipartFormData = { (form: RequestMultipartFormData) -> Void in
            for bodyPart in multipartBody {
                switch bodyPart.provider {
                case .Data(let data):
                    form.appendBodyPart(data: data, name: bodyPart.name, fileName: bodyPart.fileName, mimeType: bodyPart.mimeType)
                case .File(let url):
                    form.appendBodyPart(fileURL: url, name: bodyPart.name, fileName: bodyPart.fileName, mimeType: bodyPart.mimeType)
                case .Stream(let stream, let length):
                    form.appendBodyPart(stream: stream, length: length, name: bodyPart.name, fileName: bodyPart.fileName, mimeType: bodyPart.mimeType)
                }
            }

            if let parameters = target.parameters {
                parameters
                    .flatMap { (key, value) in multipartQueryComponents(key, value) }
                    .forEach { (key, value) in
                        if let data = value.dataUsingEncoding(NSUTF8StringEncoding, allowLossyConversion: false) {
                            form.appendBodyPart(data: data, name: key)
                        }
                }
            }
        }

        manager.upload(request, multipartFormData: multipartFormData) { (result: MultipartFormDataEncodingResult) in
            switch result {
            case .Success(let alamoRequest, _, _):
                if cancellable.cancelled {
                    self.cancelCompletion(completion, target: target)
                    return
                }
                cancellable.innerCancellable = self.sendAlamofireRequest(alamoRequest, target: target, queue: queue, progress: progress, completion: completion)
            case .Failure(let error):
                completion(result: .Failure(Moya.Error.Underlying(error as NSError)))
            }
        }

        return cancellable
    }

    private func sendUploadFile(target: Target, request: NSURLRequest, queue: dispatch_queue_t?, file: NSURL, progress: ProgressBlock? = nil, completion: Completion) -> CancellableToken {
        let alamoRequest = manager.upload(request, file: file)
        return self.sendAlamofireRequest(alamoRequest, target: target, queue: queue, progress: progress, completion: completion)
    }

    private func sendDownloadRequest(target: Target, request: NSURLRequest, queue: dispatch_queue_t?, destination: DownloadDestination, progress: ProgressBlock? = nil, completion: Completion) -> CancellableToken {
        let alamoRequest = manager.download(request, destination: destination)
        return self.sendAlamofireRequest(alamoRequest, target: target, queue: queue, progress: progress, completion: completion)
    }

    private func sendRequest(target: Target, request: NSURLRequest, queue: dispatch_queue_t?, progress: Moya.ProgressBlock?, completion: Moya.Completion) -> CancellableToken {
        let alamoRequest = manager.request(request)
        return sendAlamofireRequest(alamoRequest, target: target, queue: queue, progress: progress, completion: completion)
    }

    private func sendAlamofireRequest(alamoRequest: Request, target: Target, queue: dispatch_queue_t?, progress: Moya.ProgressBlock?, completion: Moya.Completion) -> CancellableToken {
        // Give plugins the chance to alter the outgoing request
        let plugins = self.plugins
        plugins.forEach { $0.willSendRequest(alamoRequest, target: target) }

        // Perform the actual request
        if let progress = progress {
            alamoRequest
                .progress { (bytesWritten, totalBytesWritten, totalBytesExpected) in
                    let sendProgress: () -> () = {
                        progress(progress: ProgressResponse(totalBytes: totalBytesWritten, bytesExpected: totalBytesExpected))
                    }

                    if let queue = queue {
                        dispatch_async(queue, sendProgress)
                    } else {
                        sendProgress()
                    }
            }
        }

        alamoRequest
            .response(queue: queue) { (_, response: NSHTTPURLResponse?, data: NSData?, error: NSError?) -> () in
                let result = convertResponseToResult(response, data: data, error: error)
                // Inform all plugins about the response
                plugins.forEach { $0.didReceiveResponse(result, target: target) }
                completion(result: result)
        }

        
        alamoRequest.resume()
        
        return CancellableToken(request: alamoRequest)
    }
}

/**
 Encode parameters for multipart/form-data
 */
private func multipartQueryComponents(key: String, _ value: AnyObject) -> [(String, String)] {
    var components: [(String, String)] = []

    if let dictionary = value as? [String: AnyObject] {
        for (nestedKey, value) in dictionary {
            components += multipartQueryComponents("\(key)[\(nestedKey)]", value)
        }
    } else if let array = value as? [AnyObject] {
        for value in array {
            components += multipartQueryComponents("\(key)[]", value)
        }
    } else {
        components.append((key, "\(value)"))
    }

    return components
}
