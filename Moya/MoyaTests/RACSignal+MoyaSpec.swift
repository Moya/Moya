//
//  RACSignal+MoyaSpec.swift
//  Moya
//
//  Created by Ash Furrow on 2014-09-06.
//  Copyright (c) 2014 Ash Furrow. All rights reserved.
//

import Quick
import Nimble
import Moya

@objc class TestClass { }

// Necessary since UIImage(named:) doesn't work correctly in the test bundle
extension UIImage {
    class func testPNGImage(named name: String) -> UIImage {
        let bundle = NSBundle(forClass: TestClass().dynamicType)
        let path = bundle.pathForResource(name, ofType: "png")
        return UIImage(contentsOfFile: path!)
    }
}

func signalSendingData(data: NSData?) -> RACSignal {
    return RACSignal.createSignal({ (subscriber) -> RACDisposable! in
        subscriber.sendNext(data)
        subscriber.sendCompleted()
        
        return nil
    })
}

class RACSignalMoyaSpec: QuickSpec {
    override func spec() {
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
                
                expect(receivedError).toNot(beNil())
                expect(receivedError?.code).to(equal(MoyaErrorCode.ImageMapping.toRaw()))
            }
        })

        describe("JSON mapping", { () -> () in
            it("maps data representing some JSON to that JSON") {
                let json = ["name": "John Crighton", "occupation": "Astronaut"]
                let data = NSJSONSerialization.dataWithJSONObject(json, options: NSJSONWritingOptions.PrettyPrinted, error: nil)
                let signal = signalSendingData(data)
                
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
                let signal = signalSendingData(data)
                
                var receivedError: NSError?
                signal.mapJSON().subscribeNext({ (image) -> Void in
                    XCTFail("next called for invalid data")
                    }, error: { (error) -> Void in
                        receivedError = error
                })
                
                expect(receivedError).toNot(beNil())
                expect(receivedError?.domain).to(equal(NSCocoaErrorDomain))
            }
            
            it("ignores missing data") {
                let signal = signalSendingData(nil)
                
                var receivedError: NSError?
                signal.mapJSON().subscribeNext({ (image) -> Void in
                    XCTFail("next called for invalid data")
                    }, error: { (error) -> Void in
                        receivedError = error
                })
                
                expect(receivedError).toNot(beNil())
                expect(receivedError?.code).to(equal(MoyaErrorCode.JSONMapping.toRaw()))
            }
        })
        
        describe("string mapping", { () -> () in
            it("maps data representing a string to a string") {
                let string = "You have the rights to the remains of a silent attorney."
                let data = string.dataUsingEncoding(NSUTF8StringEncoding)
                let signal = signalSendingData(data)
                
                var receivedString: String?
                signal.mapString().subscribeNext({ (string) -> Void in
                    receivedString = string as? String
                    return
                })
                
                expect(receivedString).to(equal(string))
            }
            
            it("ignores missing strings") {
                let signal = signalSendingData(nil)
                
                var receivedError: NSError?
                signal.mapString().subscribeNext({ (string) -> Void in
                    XCTFail("next called for invalid data")
                    }, error: { (error) -> Void in
                        receivedError = error
                })
                
                expect(receivedError).toNot(beNil())
                expect(receivedError?.code).to(equal(MoyaErrorCode.StringMapping.toRaw()))
            }
        })
    }
}