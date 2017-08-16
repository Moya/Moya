import Quick
import Moya
import RxSwift
import Nimble

class ObservableMoyaSpec: QuickSpec {
    override func spec() {
        describe("status codes filtering") {
            it("filters out unrequested status codes") {
                let data = Data()
                let observable = Response(statusCode: 10, data: data).asObservable()

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
                let observable = Response(statusCode: 404, data: data).asObservable()

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
                let observable = Response(statusCode: 200, data: data).asObservable()

                var called = false
                _ = observable.filterSuccessfulStatusCodes().subscribe(onNext: { _ in
                    called = true
                })

                expect(called).to(beTruthy())
            }

            it("filters out non-successful status and redirect codes") {
                let data = Data()
                let observable = Response(statusCode: 404, data: data).asObservable()

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
                let observable = Response(statusCode: 200, data: data).asObservable()

                var called = false
                _ = observable.filterSuccessfulStatusAndRedirectCodes().subscribe(onNext: { _ in
                    called = true
                })

                expect(called).to(beTruthy())
            }

            it("passes through correct redirect codes") {
                let data = Data()
                let observable = Response(statusCode: 304, data: data).asObservable()

                var called = false
                _ = observable.filterSuccessfulStatusAndRedirectCodes().subscribe(onNext: { _ in
                    called = true
                })

                expect(called).to(beTruthy())
            }

            it("knows how to filter individual status code") {
                let data = Data()
                let observable = Response(statusCode: 42, data: data).asObservable()

                var called = false
                _ = observable.filter(statusCode: 42).subscribe(onNext: { _ in
                    called = true
                })

                expect(called).to(beTruthy())
            }

            it("filters out different individual status code") {
                let data = Data()
                let observable = Response(statusCode: 43, data: data).asObservable()

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
                guard let data = ImageJPEGRepresentation(image, 0.75) else { fatalError("Failed creating Data from Image") }

                let observable = Response(statusCode: 200, data: data).asObservable()

                var size: CGSize?
                _ = observable.mapImage().subscribe(onNext: { image in
                    size = image?.size
                })

                expect(size).to(equal(image.size))
            }

            it("ignores invalid data") {
                let data = Data()
                let observable = Response(statusCode: 200, data: data).asObservable()

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
                let observable = Response(statusCode: 200, data: data).asObservable()

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
                guard let data = json.data(using: .utf8) else { fatalError("Failed creating Data from JSON String") }

                let observable = Response(statusCode: 200, data: data).asObservable()

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
                guard let data = string.data(using: .utf8) else { fatalError("Failed creating Data from String") }

                let observable = Response(statusCode: 200, data: data).asObservable()

                var receivedString: String?
                _ = observable.mapString().subscribe(onNext: { string in
                    receivedString = string
                })

                expect(receivedString).to(equal(string))
            }

            it("maps data representing a string at a key path to a string") {
                let string = "You have the rights to the remains of a silent attorney."
                let json = ["words_to_live_by": string]
                guard let data = try? JSONSerialization.data(withJSONObject: json, options: .prettyPrinted) else {
                    fatalError("Failed creating Data from JSON dictionary")
                }

                let observable = Response(statusCode: 200, data: data).asObservable()

                var receivedString: String?
                _ = observable.mapString(atKeyPath: "words_to_live_by").subscribe(onNext: { string in
                    receivedString = string
                })

                expect(receivedString).to(equal(string))
            }

            it("ignores invalid data") {
                let data = Data(bytes: [0x11FFFF] as [UInt32], count: 1) //Byte exceeding UTF8
                let observable = Response(statusCode: 200, data: data).asObservable()

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
