import Quick
import Moya
import RxSwift
import Nimble

// Necessary since UIImage(named:) doesn't work correctly in the test bundle
private extension UIImage {
    class func testPNGImage(named name: String) -> UIImage {
        class TestClass { }
        let bundle = NSBundle(forClass: TestClass().dynamicType)
        let path = bundle.pathForResource(name, ofType: "png")
        return UIImage(contentsOfFile: path!)!
    }
}

private func observableSendingData(data: NSData, statusCode: Int = 200) -> Observable<Response> {
    return just(Response(statusCode: statusCode, data: data, response: nil))
}

final class ObservableMoyaSpec: QuickSpec {
    override func spec() {
        describe("status codes filtering") {
            it("filters out unrequested status codes") {
                let data = NSData()
                let observable = observableSendingData(data, statusCode: 10)
                
                var errored = false
                _ = observable.filterStatusCodes(0...9).subscribe { (event) -> Void in
                    switch event {
                    case .Next(let object):
                        fail("called on non-correct status code: \(object)")
                    case .Error:
                        errored = true
                    default:
                        break
                    }
                }
                
                expect(errored).to(beTruthy())
            }
            
            it("filters out non-successful status codes") {
                let data = NSData()
                let observable = observableSendingData(data, statusCode: 404)
                
                var errored = false
                _ = observable.filterSuccessfulStatusCodes().subscribe { (event) -> Void in
                    switch event {
                    case .Next(let object):
                        fail("called on non-success status code: \(object)")
                    case .Error:
                        errored = true
                    default:
                        break
                    }
                }
                
                expect(errored).to(beTruthy())
            }
            
            it("passes through correct status codes") {
                let data = NSData()
                let observable = observableSendingData(data)
                
                var called = false
                _ = observable.filterSuccessfulStatusCodes().subscribeNext { (object) -> Void in
                    called = true
                }
                
                expect(called).to(beTruthy())
            }
            
            it("filters out non-successful status and redirect codes") {
                let data = NSData()
                let observable = observableSendingData(data, statusCode: 404)
                
                var errored = false
                _ = observable.filterSuccessfulStatusAndRedirectCodes().subscribe { (event) -> Void in
                    switch event {
                    case .Next(let object):
                        fail("called on non-success status code: \(object)")
                    case .Error:
                        errored = true
                    default:
                        break
                    }
                }
                
                expect(errored).to(beTruthy())
            }
            
            it("passes through correct status codes") {
                let data = NSData()
                let observable = observableSendingData(data)
                
                var called = false
                _ = observable.filterSuccessfulStatusAndRedirectCodes().subscribeNext { (object) -> Void in
                    called = true
                }
                
                expect(called).to(beTruthy())
            }
            
            it("passes through correct redirect codes") {
                let data = NSData()
                let observable = observableSendingData(data, statusCode: 304)
                
                var called = false
                _ = observable.filterSuccessfulStatusAndRedirectCodes().subscribeNext { (object) -> Void in
                    called = true
                }
                
                expect(called).to(beTruthy())
            }
            
            
            it("knows how to filter individual status code") {
                let data = NSData()
                let observable = observableSendingData(data, statusCode: 42)
                
                var called = false
                _ = observable.filterStatusCode(42).subscribeNext { (object) -> Void in
                    called = true
                }
                
                expect(called).to(beTruthy())
            }
            
            it("filters out different individual status code") {
                let data = NSData()
                let observable = observableSendingData(data, statusCode: 43)
                
                var errored = false
                _ = observable.filterStatusCode(42).subscribe { (event) -> Void in
                    switch event {
                    case .Next(let object):
                        fail("called on non-success status code: \(object)")
                    case .Error:
                        errored = true
                    default:
                        break
                    }
                }
                
                expect(errored).to(beTruthy())
            }
        }
        
        describe("image maping") {
            it("maps data representing an image to an image") {
                let image = UIImage.testPNGImage(named: "testImage")
                let data = UIImageJPEGRepresentation(image, 0.75)
                let observable = observableSendingData(data!)
                
                var size: CGSize?
                _ = observable.mapImage().subscribeNext { (image) -> Void in
                    size = image.size
                }
                
                expect(size).to(equal(image.size))
            }
            
            it("ignores invalid data") {
                let data = NSData()
                let observable = observableSendingData(data)
                
                var receivedError: MoyaError?
                _ = observable.mapImage().subscribe { (event) -> Void in
                    switch event {
                    case .Next:
                        fail("next called for invalid data")
                    case .Error(let error):
                        receivedError = error as? MoyaError
                    default:
                        break
                    }
                }
                
                expect(receivedError).toNot(beNil())
                let expectedError = MoyaError.ImageMapping(Response(statusCode: 200, data: NSData(), response: nil))
                expect(receivedError).to(beOfSameErrorType(expectedError))
            }
        }
        
        describe("JSON mapping") {
            it("maps data representing some JSON to that JSON") {
                let json = ["name": "John Crighton", "occupation": "Astronaut"]
                let data = try! NSJSONSerialization.dataWithJSONObject(json, options: .PrettyPrinted)
                let observable = observableSendingData(data)
                
                var receivedJSON: [String: String]?
                _ = observable.mapJSON().subscribeNext { (json) -> Void in
                    if let json = json as? [String: String] {
                        receivedJSON = json
                    }
                }
                
                expect(receivedJSON?["name"]).to(equal(json["name"]))
                expect(receivedJSON?["occupation"]).to(equal(json["occupation"]))
            }
            
            it("returns a Cocoa error domain for invalid JSON") {
                let json = "{ \"name\": \"john }"
                let data = json.dataUsingEncoding(NSUTF8StringEncoding)
                let observable = observableSendingData(data!)
                
                var receivedError: MoyaError?
                _ = observable.mapJSON().subscribe { (event) -> Void in
                    switch event {
                    case .Next:
                        fail("next called for invalid data")
                    case .Error(let error):
                        receivedError = error as? MoyaError
                    default:
                        break
                    }
                }
                
                expect(receivedError).toNot(beNil())
                switch receivedError {
                case .Some(.Underlying(let error as NSError)):
                    expect(error.domain).to(equal("\(NSCocoaErrorDomain)"))
                default:
                    fail("expected NSError with \(NSCocoaErrorDomain) domain")
                }
            }
        }
        
        describe("string mapping") {
            it("maps data representing a string to a string") {
                let string = "You have the rights to the remains of a silent attorney."
                let data = string.dataUsingEncoding(NSUTF8StringEncoding)
                let observable = observableSendingData(data!)
                
                var receivedString: String?
                _ = observable.mapString().subscribeNext { (string) -> Void in
                    receivedString = string
                }
                
                expect(receivedString).to(equal(string))
            }
            
            it("ignores invalid data") {
                let data = NSData(bytes: [0x11FFFF] as [UInt32], length: 1) //Byte exceeding UTF8
                let observable = observableSendingData(data)
                
                var receivedError: MoyaError?
                _ = observable.mapString().subscribe { (event) -> Void in
                    switch event {
                    case .Next:
                        fail("next called for invalid data")
                    case .Error(let error):
                        receivedError = error as? MoyaError
                    default:
                        break
                    }
                }
                
                expect(receivedError).toNot(beNil())
                let expectedError = MoyaError.StringMapping(Response(statusCode: 200, data: NSData(), response: nil))
                expect(receivedError).to(beOfSameErrorType(expectedError))
            }
        }
    }
}
