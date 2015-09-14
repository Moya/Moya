import Quick
import Moya
import RxMoya
import ReactiveMoya
import Nimble
import ReactiveCocoa
import RxSwift
import Alamofire

class MoyaProviderSpec: QuickSpec {
    override func spec() {
        var provider: MoyaProvider<GitHub>!
        beforeEach {
            provider = MoyaProvider<GitHub>(stubBehavior: MoyaProvider.ImmediateStubbingBehaviour)
        }
        
        it("returns stubbed data for zen request") {
            var message: String?
            
            let target: GitHub = .Zen
            provider.request(target) { (data, statusCode, response, error) in
                if let data = data {
                    message = NSString(data: data, encoding: NSUTF8StringEncoding) as? String
                }
            }
            
            let sampleData = target.sampleData as NSData
            expect(message).to(equal(NSString(data: sampleData, encoding: NSUTF8StringEncoding)))
        }
        
        it("returns stubbed data for user profile request") {
            var message: String?
            
            let target: GitHub = .UserProfile("ashfurrow")
            provider.request(target) { (data, statusCode, response, error) in
                if let data = data {
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
            expect(endpoint1).to(equal(endpoint2))
        }
        
        it("returns a cancellable object when a request is made") {
            let target: GitHub = .UserProfile("ashfurrow")
            
            let cancellable: Cancellable = provider.request(target) { (_, _, _, _) in }
            
            expect(cancellable).toNot(beNil())

        }

        it("uses the Alamofire.Manager.sharedInstance by default") {
            expect(provider.manager).to(beIdenticalTo(Alamofire.Manager.sharedInstance))
        }

        it("accepts a custom Alamofire.Manager") {
            let manager = Manager()
            let provider = MoyaProvider<GitHub>(manager: manager)

            expect(provider.manager).to(beIdenticalTo(manager))
        }

        it("notifies at the beginning of network requests") {
            var called = false
            let provider = MoyaProvider<GitHub>(stubBehavior: MoyaProvider.ImmediateStubbingBehaviour, networkActivityClosure: { (change) -> () in
                if change == .Began {
                    called = true
                }
            })

            let target: GitHub = .Zen
            provider.request(target) { (data, statusCode, response, error) in }

            expect(called) == true
        }

        it("notifies at the end of network requests") {
            var called = false
            let provider = MoyaProvider<GitHub>(stubBehavior: MoyaProvider.ImmediateStubbingBehaviour, networkActivityClosure: { (change) -> () in
                if change == .Ended {
                    called = true
                }
            })

            let target: GitHub = .Zen
            provider.request(target) { (data, statusCode, response, error) in }
            
            expect(called) == true
        }

        it("delays execution when appropriate") {
            let provider = MoyaProvider<GitHub>(stubBehavior: MoyaProvider.DelayedStubbingBehaviour(2))

            let startDate = NSDate()
            var endDate: NSDate?
            let target: GitHub = .Zen
            waitUntil(timeout: 3) { done in
                provider.request(target) { (data, statusCode, response, error) in
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
                let endpointResolution = { (endpoint: Endpoint<GitHub>) -> (NSURLRequest) in
                    executed = true
                    return endpoint.urlRequest
                }
                provider = MoyaProvider<GitHub>(endpointResolver: endpointResolution, stubBehavior: MoyaProvider.ImmediateStubbingBehaviour)
            }
            
            it("executes the endpoint resolver") {
                let target: GitHub = .Zen
                provider.request(target, completion: { (data, statusCode, response, error) in })

                expect(executed).to(beTruthy())
            }
        }

        describe("with stubbed errors") {
            var provider: MoyaProvider<GitHub>!
            beforeEach {
                provider = MoyaProvider(endpointClosure: failureEndpointClosure, stubBehavior: MoyaProvider.ImmediateStubbingBehaviour)
            }
            
            it("returns stubbed data for zen request") {
                var errored = false
                
                let target: GitHub = .Zen
                provider.request(target) { (object, statusCode, response, error) in
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
                provider.request(target) { (object, statusCode, response, error) in
                    if error != nil {
                        errored = true
                    }
                }
                
                let _ = target.sampleData
                expect{errored}.toEventually(beTruthy(), timeout: 1, pollInterval: 0.1)
            }
            
            it("returns stubbed error data when present") {
                var errorMessage = ""
                
                let target: GitHub = .UserProfile("ashfurrow")
                provider.request(target) { (object, statusCode, response, error) in
                    if let object = object {
                        errorMessage = NSString(data: object, encoding: NSUTF8StringEncoding) as! String
                    }
                }

                expect{errorMessage}.toEventually(equal("Houston, we have a problem"), timeout: 1, pollInterval: 0.1)
            }
        }

        describe("with lazy data") {
            var provider: MoyaProvider<GitHub>!
            beforeEach {
                provider = MoyaProvider<GitHub>(endpointClosure: lazyEndpointClosure, stubBehavior: MoyaProvider.ImmediateStubbingBehaviour)
            }

            it("returns stubbed data for zen request") {
                var message: String?

                let target: GitHub = .Zen
                provider.request(target) { (data, statusCode, response, error) in
                    if let data = data {
                        message = NSString(data: data, encoding: NSUTF8StringEncoding) as? String
                    }
                }

                let sampleData = target.sampleData as NSData
                expect(message).to(equal(NSString(data: sampleData, encoding: NSUTF8StringEncoding)))
            }
        }
    }
}
