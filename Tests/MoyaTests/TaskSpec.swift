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
                let allParameters = try? task.allParameters()
                expect(allParameters).toNot(beNil())
                let entry = allParameters!.first { $0.1 is URLEncodedFormParameterEncoder }
                expect(entry).toNot(beNil())
                let encoder = entry!.1 as! URLEncodedFormParameterEncoder
                expect(encoder.destination).to(equal(expectedDestination))
                expect(entry!.0 as! [String: String]).to(equal(encodable))
            }
        }

        sharedExamples("task with a custom encoder") { (context: SharedExampleContext) in
            let task = context()["task"] as! Task
            let expectedEncoder = context()["encoder"] as! ParameterEncoder
            let expectedEncodable = context()["encodable"] as! [String: String]

            it("uses the correct encoder and encodable") {
                let allParameters = try? task.allParameters()
                expect(allParameters).toNot(beNil())
                expect(allParameters!.count).to(be(1))
                let entry = allParameters!.first!
                expect(entry.1).to(be(expectedEncoder))
                expect(entry.0 as! [String: String]).to(equal(expectedEncodable))
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

                let allParameters = try? task.allParameters()
                expect(allParameters).toNot(beNil())
                let entry = allParameters!.first { $0.1 is JSONParameterEncoder }
                expect(entry).toNot(beNil())
                expect(entry!.0 as! [String: String]).to(equal(encodable))
            }

            context("when creating a .request with a .custom bodyParams") {
                let encoder = PropertyListEncoder()
                let task = Task.request(bodyParams: .custom(encodable, encoder))

                let allParameters = try? task.allParameters()
                expect(allParameters).toNot(beNil())
                let entry = allParameters!.first { $0.1 is PropertyListEncoder }
                expect(entry).toNot(beNil())
                expect(entry!.1).to(beAKindOf(PropertyListEncoder.self))
                expect(entry!.1 as! PropertyListEncoder).to(equal(encoder))
                expect(entry!.0 as! [String: String]).to(equal(encodable))
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
