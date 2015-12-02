import Quick
import Nimble
import Moya

private let BodyKey = "CustomizedBodyKey"
private let BodyValue = "CustomizedBodyKey"

struct InterceptionPlugin: PluginType {
    func willSendRequest(request: RequestType, target: TargetType) {
        (request.request as? NSMutableURLRequest)?.HTTPBody = "\(BodyKey)=\(BodyValue)".dataUsingEncoding(NSUTF8StringEncoding)
    }
    
    func didReceiveResponse(result: Result<Response, Error>, target: TargetType) {
        
    }
}

enum HTTPBinAPI: TargetType {
    case POST
    
    var baseURL: NSURL {
        return NSURL(string: "http://httpbin.org/")!
    }
    
    var path: String {
        return "post"
    }
    
    var parameters: [String: AnyObject]? {
        return nil
    }
    
    var method: Moya.Method {
        return .POST
    }
    
    var sampleData: NSData {
        return NSData()
    }
}


final class InterceptionPluginSpec: QuickSpec {
    override func spec() {
        
        describe("provider without interception plugin") {
            
            it("receives raw response without any data") {
                let provider: MoyaProvider<HTTPBinAPI> = MoyaProvider<HTTPBinAPI>()
                
                var formData: [String: AnyObject] = ["Customized": "Data"]
                
                provider.request(.POST) { result in
                    if case .Success(let res) = result {
                            if let JSON = try? res.mapJSON() as? [String: AnyObject], let form = JSON?["form"] as? [String: AnyObject] {
                            formData = form
                        }
                    }
                }
                
                expect(formData.count).toEventually(equal(0), timeout: 5)
                
            }
        }
        
        describe("provider with interception plugin") {
            it("receives response with customized data") {
                let provider: MoyaProvider<HTTPBinAPI> = MoyaProvider<HTTPBinAPI>(plugins: [InterceptionPlugin()])
                
                var formData: [String: AnyObject] = [:]
                
                provider.request(.POST) { result in
                    if case .Success(let res) = result {
                        if let JSON = try? res.mapJSON() as? [String: AnyObject], let form = JSON?["form"] as? [String: AnyObject] {
                            formData = form
                        }
                    }
                }
                
                expect(formData.count).toEventually(equal(1), timeout: 5)
            }
        }
    }
}
