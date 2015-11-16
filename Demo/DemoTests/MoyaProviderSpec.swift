import Quick
import Nimble
import Alamofire
import Moya

final class MoyaProviderSpec: QuickSpec {
    override func spec() {
        var provider: MoyaProvider<GitHub>!
        beforeEach {
            provider = MoyaProvider<GitHub>(stubClosure: MoyaProvider.ImmediatelyStub)
        }
        
        it("returns stubbed data for zen request") {
            var message: String?
            
            let target: GitHub = .Zen
            provider.request(target) { (response, error) in
                if let data = response?.data {
                    message = NSString(data: data, encoding: NSUTF8StringEncoding) as? String
                }
            }
            
            let sampleData = target.sampleData as NSData
            expect(message).to(equal(NSString(data: sampleData, encoding: NSUTF8StringEncoding)))
        }
        
        it("returns stubbed data for user profile request") {
            var message: String?
            
            let target: GitHub = .UserProfile("ashfurrow")
            provider.request(target) { (response, error) in
                if let data = response?.data {
                    message = NSString(data: data, encoding: NSUTF8StringEncoding) as? String
                }
            }
            
            let sampleData = target.sampleData as NSData
            expect(message).to(equal(NSString(data: sampleData, encoding: NSUTF8StringEncoding)))
        }
        
        it("returns equivalent Endpoint instances for the same target") {
            let target: GitHub = .Zen
            
            let endpoint1 = provider.endpoint(target)
            let endpoint2 = provider.endpoint(target)
            expect(endpoint1.urlRequest).to(equal(endpoint2.urlRequest))
        }
        
        it("returns a cancellable object when a request is made") {
            let target: GitHub = .UserProfile("ashfurrow")
            
            let cancellable: Cancellable = provider.request(target) { (_, _) in }
            
            expect(cancellable).toNot(beNil())

        }

        it("uses the Alamofire.Manager.sharedInstance by default") {
            expect(provider.manager).to(beIdenticalTo(Alamofire.Manager.sharedInstance))
        }
                
        it("credential closure returns nil") {
            var called = false
            let plugin = CredentialsPlugin { (target) -> NSURLCredential? in
                called = true
                return nil
            }
            
            let provider = MoyaProvider<HTTPBin>(stubClosure: MoyaProvider.ImmediatelyStub, plugins: [plugin])
            let target: HTTPBin = .BasicAuth
            provider.request(target) { (response, error) in }
            
            expect(called) == true
        }
        
        it("credential closure returns valid username and password") {
            var called = false
            let plugin = CredentialsPlugin { (target) -> NSURLCredential? in
                called = true
                return NSURLCredential(user: "user", password: "passwd", persistence: .None)
            }
            
            let provider = MoyaProvider<HTTPBin>(stubClosure: MoyaProvider.ImmediatelyStub, plugins: [plugin])
            let target: HTTPBin = .BasicAuth
            provider.request(target) { (response, error) in }
            
            expect(called) == true
        }

        it("accepts a custom Alamofire.Manager") {
            let manager = Manager()
            let provider = MoyaProvider<GitHub>(manager: manager)

            expect(provider.manager).to(beIdenticalTo(manager))
        }

        it("uses a custom Alamofire.Manager for session challenges") {
            var called = false
            let manager = Manager()
            manager.delegate.sessionDidReceiveChallenge = { (session, challenge) in
                called = true
                let disposition: NSURLSessionAuthChallengeDisposition = .PerformDefaultHandling
                return (disposition, nil)
            }
            let provider = MoyaProvider<GitHub>(manager: manager)
            let target: GitHub = .Zen
            waitUntil(timeout: 3) { done in
                provider.request(target) { (response, error) in
                    done()
                }
                return
            }

            expect(called) == true
        }

        it("notifies at the beginning of network requests") {
            var called = false
            let plugin = NetworkActivityPlugin { (change) -> () in
                if change == .Began {
                    called = true
                }
            }
            
            let provider = MoyaProvider<GitHub>(stubClosure: MoyaProvider.ImmediatelyStub, plugins: [plugin])
            let target: GitHub = .Zen
            provider.request(target) { (response, error) in }

            expect(called) == true
        }

        it("notifies at the end of network requests") {
            var called = false
            let plugin = NetworkActivityPlugin { (change) -> () in
                if change == .Ended {
                    called = true
                }
            }

            let provider = MoyaProvider<GitHub>(stubClosure: MoyaProvider.ImmediatelyStub, plugins: [plugin])
            let target: GitHub = .Zen
            provider.request(target) { (response, error) in }
            
            expect(called) == true
        }

        it("delays execution when appropriate") {
            let provider = MoyaProvider<GitHub>(stubClosure: MoyaProvider.DelayedStub(2))

            let startDate = NSDate()
            var endDate: NSDate?
            let target: GitHub = .Zen
            waitUntil(timeout: 3) { done in
                provider.request(target) { (response, error) in
                    endDate = NSDate()
                    done()
                }
                return
            }

            expect {
                return endDate?.timeIntervalSinceDate(startDate)
            }.to( beGreaterThanOrEqualTo(NSTimeInterval(2)) )
        }

        describe("a provider with a custom endpoint resolver") {
            var provider: MoyaProvider<GitHub>!
            var executed = false
            
            beforeEach {
                executed = false
                let endpointResolution = { (endpoint: Endpoint<GitHub>, done: NSURLRequest -> Void) in
                    executed = true
                    done(endpoint.urlRequest)
                }
                provider = MoyaProvider<GitHub>(requestClosure: endpointResolution, stubClosure: MoyaProvider.ImmediatelyStub)
            }
            
            it("executes the endpoint resolver") {
                let target: GitHub = .Zen
                provider.request(target, completion: { (response, error) in })

                expect(executed).to(beTruthy())
            }
        }

        describe("with stubbed errors") {
            var provider: MoyaProvider<GitHub>!
            beforeEach {
                provider = MoyaProvider(endpointClosure: failureEndpointClosure, stubClosure: MoyaProvider.ImmediatelyStub)
            }
            
            it("returns stubbed data for zen request") {
                var errored = false
                
                let target: GitHub = .Zen
                provider.request(target) { (response, error) in
                    if error != nil {
                        errored = true
                    }
                }
                
                let _ = target.sampleData
                expect(errored).toEventually(beTruthy())
            }
            
            it("returns stubbed data for user profile request") {
                var errored = false
                
                let target: GitHub = .UserProfile("ashfurrow")
                provider.request(target) { (response, error) in
                    if error != nil {
                        errored = true
                    }
                }
                
                let _ = target.sampleData
                expect{errored}.toEventually(beTruthy(), timeout: 1, pollInterval: 0.1)
            }

            it("returns stubbed error data when present") {
                var receivedError: NSError?
                
                let target: GitHub = .UserProfile("ashfurrow")
                provider.request(target) { (response, error) in
                    receivedError = error as NSError?
                }

                expect(receivedError?.localizedDescription) == "Houston, we have a problem"
            }
        }
    }
}
