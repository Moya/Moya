import Result
import Moya

final class TestingPlugin: PluginType {
    var request: (RequestType, TargetType)?
    var result: Result<Moya.Response, Moya.Error>?

    func willSendRequest(_ request: RequestType, target: TargetType) {
        self.request = (request, target)
    }

    func didReceiveResponse(_ result: Result<Moya.Response, Moya.Error>, target: TargetType) {
        self.result = result
    }
    
} 
