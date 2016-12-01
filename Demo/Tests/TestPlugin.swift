import Result
import Moya

final class TestingPlugin: PluginType {
    var request: (RequestType, TargetType)?
    var result: Result<Moya.Response, Moya.Error>?
    var didPrepare = false

    func prepareRequest(_ request: URLRequest, target: TargetType) -> URLRequest {
        var request = request
        request.addValue("yes", forHTTPHeaderField: "prepared")
        return request
    }

    func willSendRequest(_ request: RequestType, target: TargetType) {
        self.request = (request, target)

        // We check for whether or not we did prepare here to make sure prepareRequest gets called
        // before willSendRequest
        didPrepare = request.request?.allHTTPHeaderFields?["prepared"] == "yes"
    }

    func didReceiveResponse(_ result: Result<Moya.Response, Moya.Error>, target: TargetType) {
        self.result = result
    }

    func processResponse(_ result: Result<Response, Moya.Error>, target: TargetType) -> Result<Response, Moya.Error> {
        var result = result

        if case .success(let response) = result {
            let processedResponse = Response(statusCode: -1, data: response.data, request: response.request, response: response.response)
            result = .success(processedResponse)
        }

        return result
    }
    
} 
