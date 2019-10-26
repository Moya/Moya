import Quick
import Moya
import Nimble
import Foundation

final class TaskConfiguration: QuickConfiguration {
    override static func configure(_ configuration: Configuration) {
        sharedExamples("request with URLEncodedFormParameterEncoder") { (context: SharedExampleContext) in
            let task = context()["task"] as! Task
            let expectedDestination = context()["destination"] as! URLEncodedFormParameterEncoder.Destination
            let encodable = context()["encodable"] as! [String: String]

            it("uses the correct encoder and encodable") {
                let entry = task.params!.first { $0.0 is URLEncodedFormParameterEncoder }
                expect(entry).toNot(beNil())
                let encoder = entry!.0 as! URLEncodedFormParameterEncoder
                expect(encoder.destination).to(equal(expectedDestination))
                expect(entry!.1 as! [String: String]).to(equal(encodable))
            }
        }

        sharedExamples("task with a custom encoder") { (context: SharedExampleContext) in
            let task = context()["task"] as! Task
            let expectedEncoder = context()["encoder"] as! ParameterEncoder
            let expectedEncodable = context()["encodable"] as! [String: String]

            it("uses the correct encoder and encodable") {
                expect(task.params).toNot(beNil())
                expect(task.params!.count).to(be(1))
                let entry = task.params!.first!
                expect(entry.0).to(be(expectedEncoder))
                expect(entry.1 as! [String: String]).to(equal(expectedEncodable))
            }
        }
    }
}

final class TaskSpec: QuickSpec {

    override func spec() {

        let encodable: [String: String] = ["Hello": "Moya"]

        describe("task uses the correct encoder when using convenience functions") {

            context("when creating a .request with a method dependent encodable") {
                let task = Task.request(methodDependentParams: encodable)
                itBehavesLike("request with URLEncodedFormParameterEncoder") {
                    return ["task": task,
                            "destination": URLEncodedFormParameterEncoder.Destination.methodDependent,
                            "encodable": encodable]
                }
            }

            context("when creating a .request with a httpBody encodable") {
                let task = Task.request(httpBodyParams: encodable)
                itBehavesLike("request with URLEncodedFormParameterEncoder") {
                    return ["task": task,
                            "destination": URLEncodedFormParameterEncoder.Destination.httpBody,
                            "encodable": encodable]
                }
            }

            context("when creating a .request with a queryString encodable") {
                let task = Task.request(queryParams: encodable)
                itBehavesLike("request with URLEncodedFormParameterEncoder") {
                    return ["task": task,
                            "destination": URLEncodedFormParameterEncoder.Destination.queryString,
                            "encodable": encodable]
                }
            }

            context("when creating a .request with a json encodable") {
                let task = Task.request(jsonParams: encodable)

                let entry = task.params!.first { $0.0 is JSONParameterEncoder }
                expect(entry).toNot(beNil())
                expect(entry!.1 as! [String: String]).to(equal(encodable))
            }

            context("when creating a .request with a custom encoder") {
                let encoder = PropertyListEncoder()
                let task = Task.request(customParams: [(encoder, encodable)])

                let entry = task.params!.first { $0.0 is PropertyListEncoder }
                expect(entry).toNot(beNil())
                expect(entry!.0).to(beAKindOf(PropertyListEncoder.self))
                expect(entry!.0 as! PropertyListEncoder).to(equal(encoder))
                expect(entry!.1 as! [String: String]).to(equal(encodable))
            }

            context("when creating a .uploadMultiPart with a custom encoder") {
                let encoder = URLEncodedFormParameterEncoder()
                let task = Task.uploadMultipart([],
                                                queryParamsEncoder: encoder,
                                                queryParams: encodable)

                itBehavesLike("task with a custom encoder") {
                    return ["task": task,
                            "encoder": encoder,
                            "encodable": encodable]
                }
            }

            context("when creating a .download with a custom encoder") {
                let encoder = URLEncodedFormParameterEncoder()
                let destination: DownloadDestination = { url, _ in return (url, []) }
                let task = Task.download(to: destination,
                                         paramsEncoder: encoder,
                                         params: encodable)

                itBehavesLike("task with a custom encoder") {
                    return ["task": task,
                            "encoder": encoder,
                            "encodable": encodable]
                }
            }
        }
    }
}
