import Result
import Moya

final class TestingPlugin: PluginType {
    var request: (RequestType, TargetType)?
    var result: Result<Moya.Response, Moya.Error>?

    func willSendRequest(request: RequestType, target: TargetType) {
        self.request = (request, target)
    }

    func didReceiveResponse(result: Result<Moya.Response, Moya.Error>, target: TargetType) {
        self.result = result
    }
    
} 
