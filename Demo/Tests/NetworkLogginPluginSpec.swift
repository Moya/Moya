import Quick
import Nimble
import Moya
import Result

final class NetworkLogginPluginSpec: QuickSpec {
    override func spec() {
        
        var log = ""
        let plugin = NetworkLoggerPlugin(verbose: true, output: { printing in
            //mapping the Any... from items to a string that can be compared
            let stringArray: [String] = printing.items.map { $0 as? String }.flatMap { $0 }
            let string: String = stringArray.reduce("") { $0 + $1 + " " }
            log += string
        })
        
        let pluginWithResponseDataFormatter = NetworkLoggerPlugin(verbose: true, output: { printing in
            //mapping the Any... from items to a string that can be compared
            let stringArray: [String] = printing.items.map { $0 as? String }.flatMap { $0 }
            let string: String = stringArray.reduce("") { $0 + $1 + " " }
            log += string
            }, responseDataFormatter: { _ in
                return "formatted body".dataUsingEncoding(NSUTF8StringEncoding)!
        })
        
        beforeEach {
            log = ""
        }
        
        it("outputs all request fields with body") {
            
            plugin.willSendRequest(TestBodyRequest(), target: GitHub.Zen)
            
            expect(log).to( contain("Request:") )
            expect(log).to( contain("{ URL: https://api.github.com/zen }") )
            expect(log).to( contain("Request Headers: [\"Content-Type\": \"application/json\"]") )
            expect(log).to( contain("HTTP Request Method: GET") )
            expect(log).to( contain("Request Body: cool body") )
        }
        
        it("outputs all request fields with stream") {
            
            plugin.willSendRequest(TestStreamRequest(), target: GitHub.Zen)

            expect(log).to( contain("Request:") )
            expect(log).to( contain("{ URL: https://api.github.com/zen }") )
            expect(log).to( contain("Request Headers: [\"Content-Type\": \"application/json\"]") )
            expect(log).to( contain("HTTP Request Method: GET") )
            expect(log).to( contain("Request Body Stream:") )
        }
        
        it("will output invalid request when reguest is nil") {
            
            plugin.willSendRequest(TestNilRequest(), target: GitHub.Zen)
            
            expect(log).to( contain("Request: (invalid request)") )
        }
        
        it("outputs the response data") {
            let response = Response(statusCode: 200, data: "cool body".dataUsingEncoding(NSUTF8StringEncoding)!, response: NSURLResponse(URL: NSURL(string: url(GitHub.Zen))!, MIMEType: nil, expectedContentLength: 0, textEncodingName: nil))
            let result: Result<Moya.Response, Moya.Error> = .Success(response)
            
            plugin.didReceiveResponse(result, target: GitHub.Zen)
            
            expect(log).to( contain("Response:") )
            expect(log).to( contain("{ URL: https://api.github.com/zen }") )
            expect(log).to( contain("cool body") )
        }
        
        it("outputs the formatted response data") {
            let response = Response(statusCode: 200, data: "cool body".dataUsingEncoding(NSUTF8StringEncoding)!, response: NSURLResponse(URL: NSURL(string: url(GitHub.Zen))!, MIMEType: nil, expectedContentLength: 0, textEncodingName: nil))
            let result: Result<Moya.Response, Moya.Error> = .Success(response)
            
            pluginWithResponseDataFormatter.didReceiveResponse(result, target: GitHub.Zen)
            
            expect(log).to( contain("Response:") )
            expect(log).to( contain("{ URL: https://api.github.com/zen }") )
            expect(log).to( contain("formatted body") )
        }
        
        it("outputs an empty reponse message") {
            let response = Response(statusCode: 200, data: "cool body".dataUsingEncoding(NSUTF8StringEncoding)!, response: nil)
            let result: Result<Moya.Response, Moya.Error> = .Failure(Moya.Error.Data(response))
            
            plugin.didReceiveResponse(result, target: GitHub.Zen)
            
            expect(log).to( contain("Response: Received empty network response for Zen.") )
        }
    }
}

private class TestStreamRequest: RequestType {
    var request: NSURLRequest? {
        let r = NSMutableURLRequest(URL: NSURL(string: url(GitHub.Zen))!)
        r.allHTTPHeaderFields = ["Content-Type" : "application/json"]
        r.HTTPBodyStream = NSInputStream(data: "cool body".dataUsingEncoding(NSUTF8StringEncoding)!)
        
        return r
    }
    
    func authenticate(user user: String, password: String, persistence: NSURLCredentialPersistence) -> Self {
        return self
    }
    
    func authenticate(usingCredential credential: NSURLCredential) -> Self {
        return self
    }
}

private class TestBodyRequest: RequestType {
    var request: NSURLRequest? {
        let r = NSMutableURLRequest(URL: NSURL(string: url(GitHub.Zen))!)
        r.allHTTPHeaderFields = ["Content-Type" : "application/json"]
        r.HTTPBody = "cool body".dataUsingEncoding(NSUTF8StringEncoding)
        
        return r
    }
    
    func authenticate(user user: String, password: String, persistence: NSURLCredentialPersistence) -> Self {
        return self
    }
    
    func authenticate(usingCredential credential: NSURLCredential) -> Self {
        return self
    }
}

private class TestNilRequest: RequestType {
    var request: NSURLRequest? {
        return nil
    }
    
    func authenticate(user user: String, password: String, persistence: NSURLCredentialPersistence) -> Self {
        return self
    }
    
    func authenticate(usingCredential credential: NSURLCredential) -> Self {
        return self
    }
}
