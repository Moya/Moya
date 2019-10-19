import Quick
import Moya
import Nimble
import Foundation

final class NonUpdatingRequestEndpointConfiguration: QuickConfiguration {
    override static func configure(_ configuration: Configuration) {
        sharedExamples("endpoint with no request property changed") { (context: SharedExampleContext) in
            let task = context()["task"] as! Task
            let oldEndpoint = context()["endpoint"] as! Endpoint
            let endpoint = oldEndpoint.replacing(task: task)
            let request = try! endpoint.urlRequest()

            it("didn't update any of the request properties") {
                expect(request.httpBody).to(beNil())
                expect(request.url?.absoluteString).to(equal(endpoint.url))
                expect(request.allHTTPHeaderFields).to(equal(endpoint.httpHeaderFields))
                expect(request.httpMethod).to(equal(endpoint.method.rawValue))
            }
        }
    }
}

final class ParametersEncodedEndpointConfiguration: QuickConfiguration {
    override static func configure(_ configuration: Configuration) {
        sharedExamples("endpoint with encoded parameters") { (context: SharedExampleContext) in
            let parameters = context()["parameters"] as! Encodable
            let encoder = context()["encoder"] as! ParameterEncoder
            let endpoint = context()["endpoint"] as! Endpoint
            let request = try! endpoint.urlRequest()

            it("updated the request correctly") {
                let newEndpoint = endpoint.replacing(task: .request())
                let newRequest = try! newEndpoint.urlRequest()
                let newEncodedRequest = try? encoder.encode(AnyEncodable(parameters), into: newRequest)

                expect(request.httpBody).to(equal(newEncodedRequest?.httpBody))
                expect(request.url?.absoluteString).to(equal(newEncodedRequest?.url?.absoluteString))
                expect(request.allHTTPHeaderFields).to(equal(newEncodedRequest?.allHTTPHeaderFields))
                expect(request.httpMethod).to(equal(newEncodedRequest?.httpMethod))
            }
        }
    }
}

final class EndpointSpec: QuickSpec {

    private var simpleGitHubEndpoint: Endpoint {
        let target: GitHub = .zen
        let headerFields = ["Title": "Dominar"]
        return Endpoint(url: url(target), sampleResponseClosure: {.networkResponse(200, target.sampleData)}, method: Moya.Method.get, task: .request(), httpHeaderFields: headerFields)
    }

    override func spec() {
        var endpoint: Endpoint!

        beforeEach {
            endpoint = self.simpleGitHubEndpoint
        }

        it("returns a new endpoint for adding(newHTTPHeaderFields:)") {
            let agent = "Zalbinian"
            let newEndpoint = endpoint.adding(newHTTPHeaderFields: ["User-Agent": agent])
            let newEndpointAgent = newEndpoint.httpHeaderFields?["User-Agent"]

            // Make sure our closure updated the sample response, as proof that it can modify the Endpoint
            expect(newEndpointAgent).to(equal(agent))

            // Compare other properties to ensure they've been copied correctly
            expect(newEndpoint.url).to(equal(endpoint.url))
            expect(newEndpoint.method).to(equal(endpoint.method))
        }

        it("returns a nil urlRequest for an invalid URL") {
            let badEndpoint = Endpoint(url: "some invalid URL", sampleResponseClosure: { .networkResponse(200, Data()) }, method: .get, task: .request(), httpHeaderFields: nil)
            let urlRequest = try? badEndpoint.urlRequest()
            expect(urlRequest).to(beNil())
        }

        describe("successful converting to urlRequest") {
            context("when task is .request(params: nil)") {
                itBehavesLike("endpoint with no request property changed") {
                    ["task": Task.request(), "endpoint": self.simpleGitHubEndpoint]
                }
            }

            context("when task is .uploadFile") {
                itBehavesLike("endpoint with no request property changed") {
                    ["task": Task.uploadFile(URL(string: "https://google.com")!), "endpoint": self.simpleGitHubEndpoint]
                }
            }

            context("when task is .uploadMultipart") {
                itBehavesLike("endpoint with no request property changed") {
                    ["task": Task.uploadMultipart([]), "endpoint": self.simpleGitHubEndpoint]
                }
            }

            context("when task is .download") {
                itBehavesLike("endpoint with no request property changed") {
                    let destination: DownloadDestination = { url, response in
                        return (destinationURL: url, options: [])
                    }
                    return ["task": Task.download(to: destination), "endpoint": self.simpleGitHubEndpoint]
                }
            }

            context("when task is .request with JSON encoder") {
                itBehavesLike("endpoint with encoded parameters") {
                    let parameters: Encodable = ["Nemesis": "Harvey"]
                    let encoder = JSONParameterEncoder.default
                    let endpoint = self.simpleGitHubEndpoint.replacing(task: .request(jsonParams: parameters))
                    return ["parameters": parameters, "encoder": encoder, "endpoint": endpoint]
                }
            }

            context("when task is .download with parameters") {
                itBehavesLike("endpoint with encoded parameters") {
                    let parameters: Encodable = ["Nemesis": "Harvey"]
                    let encoder = JSONParameterEncoder.default
                    let destination: DownloadDestination = { url, response in
                        return (destinationURL: url, options: [])
                    }
                    let newTask: Task = .download(destination: destination, params: [(encoder, parameters)])
                    let endpoint = self.simpleGitHubEndpoint.replacing(task: newTask)
                    return ["parameters": parameters, "encoder": encoder, "endpoint": endpoint]
                }
            }

            context("when task is .request with data encoded in body") {
                var data: Data!
                var request: URLRequest!

                beforeEach {
                    data = "test data".data(using: .utf8)
                    endpoint = endpoint.replacing(task: .request(bodyData: data))
                    request = try! endpoint.urlRequest()
                }

                it("updates httpBody") {
                    expect(request.httpBody).to(equal(data))
                }

                it("doesn't update any of the other properties") {
                    expect(request.url?.absoluteString).to(equal(endpoint.url))
                    expect(request.allHTTPHeaderFields).to(equal(endpoint.httpHeaderFields))
                    expect(request.httpMethod).to(equal(endpoint.method.rawValue))
                }
            }

            context("when task is .request with json encoded in body") {
                var issue: Issue!
                var request: URLRequest!

                beforeEach {
                    issue = Issue(title: "Hello, Moya!", createdAt: Date(), rating: 0)
                    endpoint = endpoint.replacing(task: .request(jsonParams: issue))
                    request = try! endpoint.urlRequest()
                }

                it("updates httpBody") {
                    let expectedIssue = try! JSONDecoder().decode(Issue.self, from: request.httpBody!)
                    expect(issue.createdAt).to(equal(expectedIssue.createdAt))
                    expect(issue.title).to(equal(expectedIssue.title))
                }

                it("updates headers to include Content-Type: application/json") {
                    let contentTypeHeaders = ["Content-Type": "application/json"]
                    let initialHeaderFields = endpoint.httpHeaderFields ?? [:]
                    let expectedHTTPHeaderFields = initialHeaderFields.merging(contentTypeHeaders) { initialValue, _ in initialValue }
                    expect(request.allHTTPHeaderFields).to(equal(expectedHTTPHeaderFields))
                }

                it("doesn't update any of the other properties") {
                    expect(request.url?.absoluteString).to(equal(endpoint.url))
                    expect(request.httpMethod).to(equal(endpoint.method.rawValue))
                }
            }

            context("when task is .request with json body and a custom encoder") {
                var issue: Issue!
                var request: URLRequest!

                let formatter = DateFormatter()
                formatter.locale = Locale(identifier: "en_US_POSIX")
                formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSZ"

                let encoder = JSONEncoder()
                encoder.dateEncodingStrategy = .formatted(formatter)

                let decoder = JSONDecoder()
                decoder.dateDecodingStrategy = .formatted(formatter)

                beforeEach {
                    issue = Issue(title: "Hello, Moya!", createdAt: Date(), rating: 0)
                    let taskParameters: Task.TaskParameters = [(JSONParameterEncoder(encoder: encoder), issue)]
                    endpoint = endpoint.replacing(task: .request(customParams: taskParameters))
                    request = try! endpoint.urlRequest()
                }

                it("updates httpBody") {
                    let expectedIssue = try! decoder.decode(Issue.self, from: request.httpBody!)
                    expect(formatter.string(from: issue.createdAt)).to(equal(formatter.string(from: expectedIssue.createdAt)))
                    expect(issue.title).to(equal(expectedIssue.title))
                }

                it("updates headers to include Content-Type: application/json") {
                    let contentTypeHeaders = ["Content-Type": "application/json"]
                    let initialHeaderFields = endpoint.httpHeaderFields ?? [:]
                    let expectedHTTPHeaderFields = initialHeaderFields.merging(contentTypeHeaders) { initialValue, _ in initialValue }
                    expect(request.allHTTPHeaderFields).to(equal(expectedHTTPHeaderFields))
                }

                it("doesn't update any of the other properties") {
                    expect(request.url?.absoluteString).to(equal(endpoint.url))
                    expect(request.httpMethod).to(equal(endpoint.method.rawValue))
                }
            }

            context("when task is .request with body data and query parameters") {
                var parameters: Encodable!
                var data: Data!
                var request: URLRequest!

                beforeEach {
                    parameters = ["Nemesis": "Harvey"]
                    data = "test data".data(using: .utf8)
                    endpoint = endpoint.replacing(task: .request(bodyData: data, queryParams: parameters))
                    request = try! endpoint.urlRequest()
                }

                it("updates url") {
                    let expectedUrl = endpoint.url + "?Nemesis=Harvey"
                    expect(request.url?.absoluteString).to(equal(expectedUrl))
                }

                it("updates httpBody") {
                    expect(request.httpBody).to(equal(data))
                }

                it("doesn't update any of the other properties") {
                    expect(request?.allHTTPHeaderFields).to(equal(endpoint.httpHeaderFields))
                    expect(request?.httpMethod).to(equal(endpoint.method.rawValue))
                }
            }

            context("when task is .request with body and query params") {
                var bodyParameters: Encodable!
                var urlParameters: Encodable!
                var request: URLRequest!

                beforeEach {
                    bodyParameters = ["Nemesis": "Harvey"]
                    urlParameters = ["Harvey": "Nemesis"]
                    endpoint = endpoint.replacing(task: .request(httpBodyParams: bodyParameters,
                                                                 queryParams: urlParameters))
                    request = try! endpoint.urlRequest()
                }

                it("updates url") {
                    let expectedUrl = endpoint.url + "?Harvey=Nemesis"
                    expect(request.url?.absoluteString).to(equal(expectedUrl))
                }

                it("updates the request correctly") {
                    let newEndpoint = endpoint.replacing(task: .request())
                    let newRequest = try! newEndpoint.urlRequest()
                    let newEncodedRequest = try? JSONParameterEncoder.default.encode(AnyEncodable(bodyParameters), into: newRequest)

                    expect(request.httpBody).to(equal(newEncodedRequest?.httpBody))
                    expect(request.allHTTPHeaderFields).to(equal(newEncodedRequest?.allHTTPHeaderFields))
                    expect(request.httpMethod).to(equal(newEncodedRequest?.httpMethod))
                }
            }

            context("when task is .uploadMultipart with params") {
                var urlParameters: Encodable!
                var request: URLRequest!

                beforeEach {
                    urlParameters = ["Harvey": "Nemesis"]
                    endpoint = endpoint.replacing(task: .uploadMultipart([], queryParams: urlParameters))
                    request = try! endpoint.urlRequest()
                }

                it("updates url") {
                    let expectedUrl = endpoint.url + "?Harvey=Nemesis"
                    expect(request.url?.absoluteString).to(equal(expectedUrl))
                }
            }
        }

        describe("unsuccessful converting to urlRequest") {
            context("when url String is invalid") {
                it("throws a .requestMapping error") {
                    let badEndpoint = Endpoint(url: "some invalid URL",
                                               sampleResponseClosure: { .networkResponse(200, Data()) },
                                               method: .get,
                                               task: .request(),
                                               httpHeaderFields: nil)
                    let expectedError = MoyaError.requestMapping("some invalid URL")
                    var recievedError: MoyaError?
                    do {
                        _ = try badEndpoint.urlRequest()
                    } catch {
                        recievedError = error as? MoyaError
                    }
                    expect(recievedError).toNot(beNil())
                    expect(recievedError).to(beOfSameErrorType(expectedError))
                }
            }

            context("when parameter encoding is unsuccessful") {
                it("throws a .parameterEncoding error") {

                    // Non-serializable type to cause serialization error
                    class InvalidParameter: Encodable {
                        func encode(to encoder: Encoder) throws {}
                    }

                    let taskParameters: Task.TaskParameters = [(PropertyListEncoder.default, ["": InvalidParameter()] )]
                    endpoint = endpoint.replacing(task: .request(customParams: taskParameters))
                    let cocoaError = NSError(domain: "NSCocoaErrorDomain",
                                             code: 3851,
                                             userInfo: ["NSDebugDescription": "Property list invalid for format: 100 (property lists cannot contain objects of type 'CFType')"])
                    let expectedError = MoyaError.parameterEncoding(cocoaError)
                    var recievedError: MoyaError?

                    do {
                        _ = try endpoint.urlRequest()
                    } catch {
                        recievedError = error as? MoyaError
                    }
                    expect(recievedError).toNot(beNil())
                    expect(recievedError).to(beOfSameErrorType(expectedError))
                }
            }

            context("when json encodable set with incorrect parameters") {
                it("throws a .encodableMapping error") {

                    let issue = Issue(title: "Hello, Moya!", createdAt: Date(), rating: Float.infinity)
                    endpoint = endpoint.replacing(task: .request(jsonParams: issue))

                    let expectedError = MoyaError.encodableMapping(EncodingError.invalidValue(Float.infinity, EncodingError.Context(codingPath: [Issue.CodingKeys.rating], debugDescription: "Unable to encode Float.infinity directly in JSON. Use JSONEncoder.NonConformingFloatEncodingStrategy.convertToString to specify how the value should be encoded.", underlyingError: nil)))
                    var recievedError: MoyaError?

                    do {
                        _ = try endpoint.urlRequest()
                    } catch {
                        recievedError = error as? MoyaError
                    }
                    expect(recievedError).toNot(beNil())
                    expect(recievedError).to(beOfSameErrorType(expectedError))
                }
            }
        }
    }
}

enum Empty {
}

extension Empty: TargetType {
    // None of these matter since the Empty has no cases and can't be instantiated.
    var baseURL: URL { URL(string: "http://example.com")! }
    var path: String { "" }
    var method: Moya.Method { .get }
    var task: Task { .request() }
    var sampleData: Data { Data() }
    var headers: [String: String]? { nil }
}
