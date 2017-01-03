import Quick
import Moya
import RxSwift
import Nimble

#if os(iOS) || os(watchOS) || os(tvOS)
    private func ImageJPEGRepresentation(_ image: ImageType, _ compression: CGFloat) -> Data? {
        return UIImageJPEGRepresentation(image, compression)
    }
#elseif os(OSX)
    private func ImageJPEGRepresentation(_ image: ImageType, _ compression: CGFloat) -> Data? {
        var imageRect = CGRect(x: 0, y: 0, width: image.size.width, height: image.size.height)
        let imageRep = NSBitmapImageRep(cgImage: image.cgImage(forProposedRect: &imageRect, context: nil, hints: nil)!)
        return imageRep.representation(using: .JPEG, properties:[:])
    }
#endif

// Necessary since Image(named:) doesn't work correctly in the test bundle
private extension ImageType {
    class func testPNGImage(named name: String) -> ImageType {
        class TestClass { }
        let bundle = Bundle(for: type(of: TestClass()))
        let path = bundle.path(forResource: name, ofType: "png")
        return Image(contentsOfFile: path!)!
    }
}

private func observableSendingData(_ data: Data, statusCode: Int = 200) -> Observable<Response> {
    return Observable.just(Response(statusCode: statusCode, data: data, response: nil))
}

class ObservableMoyaSpec: QuickSpec {
    override func spec() {
        describe("status codes filtering") {
            it("filters out unrequested status codes") {
                let data = Data()
                let observable = observableSendingData(data, statusCode: 10)
                
                var errored = false
                _ = observable.filter(statusCodes: 0...9).subscribe { event in
                    switch event {
                    case .next(let object):
                        fail("called on non-correct status code: \(object)")
                    case .error:
                        errored = true
                    default:
                        break
                    }
                }
                
                expect(errored).to(beTruthy())
            }
            
            it("filters out non-successful status codes") {
                let data = Data()
                let observable = observableSendingData(data, statusCode: 404)
                
                var errored = false
                _ = observable.filterSuccessfulStatusCodes().subscribe { event in
                    switch event {
                    case .next(let object):
                        fail("called on non-success status code: \(object)")
                    case .error:
                        errored = true
                    default:
                        break
                    }
                }
                
                expect(errored).to(beTruthy())
            }
            
            it("passes through correct status codes") {
                let data = Data()
                let observable = observableSendingData(data)
                
                var called = false
                _ = observable.filterSuccessfulStatusCodes().subscribe(onNext: { object in
                    called = true
                })
                
                expect(called).to(beTruthy())
            }
            
            it("filters out non-successful status and redirect codes") {
                let data = Data()
                let observable = observableSendingData(data, statusCode: 404)
                
                var errored = false
                _ = observable.filterSuccessfulStatusAndRedirectCodes().subscribe { event in
                    switch event {
                    case .next(let object):
                        fail("called on non-success status code: \(object)")
                    case .error:
                        errored = true
                    default:
                        break
                    }
                }
                
                expect(errored).to(beTruthy())
            }
            
            it("passes through correct status codes") {
                let data = Data()
                let observable = observableSendingData(data)
                
                var called = false
                _ = observable.filterSuccessfulStatusAndRedirectCodes().subscribe(onNext: { object in
                    called = true
                })
                
                expect(called).to(beTruthy())
            }
            
            it("passes through correct redirect codes") {
                let data = Data()
                let observable = observableSendingData(data, statusCode: 304)
                
                var called = false
                _ = observable.filterSuccessfulStatusAndRedirectCodes().subscribe(onNext: { object in
                    called = true
                })
                
                expect(called).to(beTruthy())
            }
            
            
            it("knows how to filter individual status code") {
                let data = Data()
                let observable = observableSendingData(data, statusCode: 42)
                
                var called = false
                _ = observable.filter(statusCode: 42).subscribe(onNext: { object in
                    called = true
                })
                
                expect(called).to(beTruthy())
            }
            
            it("filters out different individual status code") {
                let data = Data()
                let observable = observableSendingData(data, statusCode: 43)
                
                var errored = false
                _ = observable.filter(statusCode: 42).subscribe { event in
                    switch event {
                    case .next(let object):
                        fail("called on non-success status code: \(object)")
                    case .error:
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
                let image = Image.testPNGImage(named: "testImage")
                let data = ImageJPEGRepresentation(image, 0.75)
                let observable = observableSendingData(data!)
                
                var size: CGSize?
                _ = observable.mapImage().subscribe(onNext: { image in
                    size = image?.size
                })
                
                expect(size).to(equal(image.size))
            }
            
            it("ignores invalid data") {
                let data = Data()
                let observable = observableSendingData(data)
                
                var receivedError: MoyaError?
                _ = observable.mapImage().subscribe { event in
                    switch event {
                    case .next:
                        fail("next called for invalid data")
                    case .error(let error):
                        receivedError = error as? MoyaError
                    default:
                        break
                    }
                }
                
                expect(receivedError).toNot(beNil())
                let expectedError = MoyaError.imageMapping(Response(statusCode: 200, data: Data(), response: nil))
                expect(receivedError).to(beOfSameErrorType(expectedError))
            }
        }
        
        describe("JSON mapping") {
            it("maps data representing some JSON to that JSON") {
                let json = ["name": "John Crighton", "occupation": "Astronaut"]
                let data = try! JSONSerialization.data(withJSONObject: json, options: .prettyPrinted)
                let observable = observableSendingData(data)
                
                var receivedJSON: [String: String]?
                _ = observable.mapJSON().subscribe(onNext: { json in
                    if let json = json as? [String: String] {
                        receivedJSON = json
                    }
                })
                
                expect(receivedJSON?["name"]).to(equal(json["name"]))
                expect(receivedJSON?["occupation"]).to(equal(json["occupation"]))
            }
            
            it("returns a Cocoa error domain for invalid JSON") {
                let json = "{ \"name\": \"john }"
                let data = json.data(using: .utf8)
                let observable = observableSendingData(data!)
                
                var receivedError: MoyaError?
                _ = observable.mapJSON().subscribe { event in
                    switch event {
                    case .next:
                        fail("next called for invalid data")
                    case .error(let error):
                        receivedError = error as? MoyaError
                    default:
                        break
                    }
                }
                
                expect(receivedError).toNot(beNil())
                switch receivedError {
                case .some(.jsonMapping):
                    break
                default:
                    fail("expected NSError with \(NSCocoaErrorDomain) domain")
                }
            }
        }
        
        describe("string mapping") {
            it("maps data representing a string to a string") {
                let string = "You have the rights to the remains of a silent attorney."
                let data = string.data(using: .utf8)
                let observable = observableSendingData(data!)
                
                var receivedString: String?
                _ = observable.mapString().subscribe(onNext: { string in
                    receivedString = string
                })
                
                expect(receivedString).to(equal(string))
            }

            it("maps data representing a string at a key path to a string") {
                let string = "You have the rights to the remains of a silent attorney."
                let json = ["words_to_live_by": string]
                let data = try! JSONSerialization.data(withJSONObject: json, options: .prettyPrinted)
                let observable = observableSendingData(data)

                var receivedString: String?
                _ = observable.mapString(atKeyPath: "words_to_live_by").subscribe(onNext: { string in
                    receivedString = string
                })

                expect(receivedString).to(equal(string))
            }
            
            it("ignores invalid data") {
                let data = Data(bytes: [0x11FFFF] as [UInt32], count: 1) //Byte exceeding UTF8
                let observable = observableSendingData(data)
                
                var receivedError: MoyaError?
                _ = observable.mapString().subscribe { event in
                    switch event {
                    case .next:
                        fail("next called for invalid data")
                    case .error(let error):
                        receivedError = error as? MoyaError
                    default:
                        break
                    }
                }
                
                expect(receivedError).toNot(beNil())
                let expectedError = MoyaError.stringMapping(Response(statusCode: 200, data: Data(), response: nil))
                expect(receivedError).to(beOfSameErrorType(expectedError))
            }
        }
    }
}
