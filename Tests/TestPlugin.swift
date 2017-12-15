import enum Result.Result
@testable import Moya

final class TestingPlugin: PluginType {
    var request: (RequestType, TargetType)?
    var result: Result<Moya.Response, MoyaError>?
    var didPrepare = false

    func prepare(_ request: URLRequest, target: TargetType) -> URLRequest {
        var request = request
        request.addValue("yes", forHTTPHeaderField: "prepared")
        return request
    }

    func willSend(_ request: RequestType, target: TargetType) {
        self.request = (request, target)

        // We check for whether or not we did prepare here to make sure prepare gets called
        // before willSend
        didPrepare = request.request?.allHTTPHeaderFields?["prepared"] == "yes"
    }

    func didReceive(_ result: Result<Moya.Response, MoyaError>, target: TargetType) {
        self.result = result
    }

    func process(_ result: Result<Response, MoyaError>, target: TargetType) -> Result<Response, MoyaError> {
        var result = result

        if case .success(let response) = result {
            let processedResponse = Response(statusCode: -1, data: response.data, request: response.request, response: response.response)
            result = .success(processedResponse)
        }

        return result
    }

}
