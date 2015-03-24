//
//  RACSignal+MoyaSpec.swift
//  Moya
//
//  Created by Ash Furrow on 2014-09-06.
//  Copyright (c) 2014 Ash Furrow. All rights reserved.
//

import Quick
import Moya
import ReactiveCocoa
import Nimble

@objc class TestClass { }

// Necessary since UIImage(named:) doesn't work correctly in the test bundle
extension UIImage {
    class func testPNGImage(named name: String) -> UIImage {
        let bundle = NSBundle(forClass: TestClass().dynamicType)
        let path = bundle.pathForResource(name, ofType: "png")
        return UIImage(contentsOfFile: path!)!
    }
}

func signalSendingData(data: NSData, statusCode: Int = 200) -> RACSignal {
    return RACSignal.createSignal({ (subscriber) -> RACDisposable! in
        subscriber.sendNext(MoyaResponse(statusCode: statusCode, data: data, response: nil))
        subscriber.sendCompleted()
        
        return nil
    })
}

class RACSignalMoyaSpec: QuickSpec {
    override func spec() {
        describe("status codes filtering", {
            it("filters out unrequested status codes") {
                let data = NSData()
                let signal = signalSendingData(data, statusCode: 10)

                var errored = false
                signal.filterStatusCodes(0...9).subscribeNext({ (object) -> Void in
                    XCTFail("called on non-correct status code: \(object)")
                }, error: { (error) -> Void in
                    errored = true
                })
                
                expect(errored).to(beTruthy())
            }
            
            it("filters out non-successful status codes") {
                let data = NSData()
                let signal = signalSendingData(data, statusCode: 404)
                
                var errored = false
                signal.filterSuccessfulStatusCodes().subscribeNext({ (object) -> Void in
                    XCTFail("called on non-success status code: \(object)")
                }, error: { (error) -> Void in
                    errored = true
                })
                
                expect(errored).to(beTruthy())
            }
            
            it("passes through correct status codes") {
                let data = NSData()
                let signal = signalSendingData(data)
                
                var called = false
                signal.filterSuccessfulStatusCodes().subscribeNext({ (object) -> Void in
                    called = true
                })
                
                expect(called).to(beTruthy())
            }
            
            it("filters out non-successful status and redirect codes") {
                let data = NSData()
                let signal = signalSendingData(data, statusCode: 404)
                
                var errored = false
                signal.filterSuccessfulStatusAndRedirectCodes().subscribeNext({ (object) -> Void in
                    XCTFail("called on non-success status code: \(object)")
                    }, error: { (error) -> Void in
                        errored = true
                })
                
                expect(errored).to(beTruthy())
            }
            
            it("passes through correct status codes") {
                let data = NSData()
                let signal = signalSendingData(data)
                
                var called = false
                signal.filterSuccessfulStatusAndRedirectCodes().subscribeNext({ (object) -> Void in
                    called = true
                })
                
                expect(called).to(beTruthy())
            }
            
            it("passes through correct redirect codes") {
                let data = NSData()
                let signal = signalSendingData(data, statusCode: 304)
                
                var called = false
                signal.filterSuccessfulStatusAndRedirectCodes().subscribeNext({ (object) -> Void in
                    called = true
                })
                
                expect(called).to(beTruthy())
            }
        })
        
        describe("image maping", {
            it("maps data representing an image to an image") {
                let image = UIImage.testPNGImage(named: "testImage")
                let data = UIImageJPEGRepresentation(image, 0.75)
                let signal = signalSendingData(data)
                
                var size: CGSize?
                signal.mapImage().subscribeNext({ (image) -> Void in
                    size = image.size
                })
                
                expect(size).to(equal(image.size))
            }
            
            it("ignores invalid data") {
                let data = NSData()
                let signal = signalSendingData(data)
                
                var receivedError: NSError?
                signal.mapImage().subscribeNext({ (image) -> Void in
                    XCTFail("next called for invalid data")
                }, error: { (error) -> Void in
                    receivedError = error
                })
                
                expect(receivedError?.code).to(equal(MoyaErrorCode.ImageMapping.rawValue))
            }
        })

        describe("JSON mapping", { () -> () in
            it("maps data representing some JSON to that JSON") {
                let json = ["name": "John Crighton", "occupation": "Astronaut"]
                let data = NSJSONSerialization.dataWithJSONObject(json, options: nil, error: nil)
                let signal = signalSendingData(data!)
                
                var receivedJSON: [String: String]?
                signal.mapJSON().subscribeNext({ (json) -> Void in
                    if let json = json as? [String: String] {
                        receivedJSON = json
                    }
                })
                
                expect(receivedJSON?["name"]).to(equal(json["name"]))
                expect(receivedJSON?["occupation"]).to(equal(json["occupation"]))
            }
            
            it("returns a Cocoa error domain for invalid JSON") {
                let json = "{ \"name\": \"john }"
                let data = json.dataUsingEncoding(NSUTF8StringEncoding)
                let signal = signalSendingData(data!)
                
                var receivedError: NSError?
                signal.mapJSON().subscribeNext({ (image) -> Void in
                    XCTFail("next called for invalid data")
                    }, error: { (error) -> Void in
                        receivedError = error
                })
                
                expect(receivedError).toNot(beNil())
                expect(receivedError?.domain).to(equal("\(NSCocoaErrorDomain)"))
            }
        })
        
        describe("string mapping", { () -> () in
            it("maps data representing a string to a string") {
                let string = "You have the rights to the remains of a silent attorney."
                let data = string.dataUsingEncoding(NSUTF8StringEncoding)
                let signal = signalSendingData(data!)
                
                var receivedString: String?
                signal.mapString().subscribeNext({ (string) -> Void in
                    receivedString = string as? String
                    return
                })
                
                expect(receivedString).to(equal(string))
            }
        })
    }
}