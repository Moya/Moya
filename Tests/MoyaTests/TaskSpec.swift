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
                let entry = task.allParameters.first { $0.0 is URLEncodedFormParameterEncoder }
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
                expect(task.allParameters.count).to(be(1))
                let entry = task.allParameters.first!
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

            context("when creating a .request with a httpBody encodable") {
                let task = Task.request(bodyParams: .urlEncoded(encodable))
                itBehavesLike("request with URLEncodedFormParameterEncoder") {
                    return ["task": task,
                            "destination": URLEncodedFormParameterEncoder.Destination.httpBody,
                            "encodable": encodable]
                }
            }

            context("when creating a .request with a queryString encodable") {
                let task = Task.request(queryParams: .query(encodable))
                itBehavesLike("request with URLEncodedFormParameterEncoder") {
                    return ["task": task,
                            "destination": URLEncodedFormParameterEncoder.Destination.queryString,
                            "encodable": encodable]
                }
            }

            context("when creating a .request with a json encodable") {
                let task = Task.request(bodyParams: .json(encodable))

                let entry = task.allParameters.first { $0.0 is JSONParameterEncoder }
                expect(entry).toNot(beNil())
                expect(entry!.1 as! [String: String]).to(equal(encodable))
            }

            context("when creating a .request with a .custom bodyParams") {
                let encoder = PropertyListEncoder()
                let task = Task.request(bodyParams: .custom(encodable, encoder))

                let entry = task.allParameters.first { $0.0 is PropertyListEncoder }
                expect(entry).toNot(beNil())
                expect(entry!.0).to(beAKindOf(PropertyListEncoder.self))
                expect(entry!.0 as! PropertyListEncoder).to(equal(encoder))
                expect(entry!.1 as! [String: String]).to(equal(encodable))
            }

            context("when creating a .uploadMultiPart with a custom encoder") {
                let encoder = URLEncodedFormParameterEncoder()
                let task = Task.upload(source: .multipart([]),
                                       queryParams: .query(encodable, encoder))

                itBehavesLike("task with a custom encoder") {
                    return ["task": task,
                            "encoder": encoder,
                            "encodable": encodable]
                }
            }

            context("when creating a .download with a custom encoder") {
                let encoder = URLEncodedFormParameterEncoder()
                let destination: DownloadDestination = { url, _ in return (url, []) }
                let task = Task.download(destination: destination, queryParams: .query(encodable, encoder))

                itBehavesLike("task with a custom encoder") {
                    return ["task": task,
                            "encoder": encoder,
                            "encodable": encodable]
                }
            }
        }
    }
}
