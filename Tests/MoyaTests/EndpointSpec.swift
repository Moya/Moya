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

                // Workaround for error `expected to equal <nil>, got <nil> (use beNil() to match nils)` when httpBody is nil
                if let body = request.httpBody {
                    expect(body).to(equal(newEncodedRequest?.httpBody))
                } else {
                    expect(newEncodedRequest?.httpBody).to(beNil())
                }

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
            let parameters = ["Nemesis": "Harvey"]

            context("when task is .request") {
                context("without params") {
                    itBehavesLike("endpoint with no request property changed") {
                        return ["task": Task.request(),
                                "endpoint": self.simpleGitHubEndpoint]
                    }
                }

                context("with body params") {
                    context("value is .raw") {
                        itBehavesLike("endpoint with encoded parameters") {
                            let data = "Hello Moya".data(using: .utf8)!
                            let task: Task = .request(bodyParams: .raw(data))
                            let endpoint = self.simpleGitHubEndpoint.replacing(task: task)
                            return ["parameters": data,
                                    "encoder": RawDataParameterEncoder(),
                                    "endpoint": endpoint]
                        }
                    }

                    context("value is .json") {
                        itBehavesLike("endpoint with encoded parameters") {
                            let encoder = JSONParameterEncoder.default
                            let task: Task = .request(bodyParams: .json(parameters, encoder))
                            let endpoint = self.simpleGitHubEndpoint.replacing(task: task)
                            return ["parameters": parameters,
                                    "encoder": encoder,
                                    "endpoint": endpoint]
                        }
                    }

                    context("value is .urlEncoded") {
                        itBehavesLike("endpoint with encoded parameters") {
                            let encoder = URLEncodedFormParameterEncoder(destination: .httpBody)
                            let task: Task = .request(bodyParams: .urlEncoded(parameters, encoder))
                            let endpoint = self.simpleGitHubEndpoint.replacing(task: task)
                            return ["parameters": parameters,
                                    "encoder": encoder,
                                    "endpoint": endpoint]
                        }
                    }

                    context("value is .custom") {
                        itBehavesLike("endpoint with encoded parameters") {
                            let encoder = PropertyListEncoder()
                            let task: Task = .request(bodyParams: .custom(parameters, encoder))
                            let endpoint = self.simpleGitHubEndpoint.replacing(task: task)
                            return ["parameters": parameters,
                                    "encoder": encoder,
                                    "endpoint": endpoint]
                        }
                    }
                }

                context("with query params") {
                    itBehavesLike("endpoint with encoded parameters") {
                        let encoder = URLEncodedFormParameterEncoder(destination: .queryString)
                        let task: Task = .request(queryParams: .query(parameters, encoder))
                        let endpoint = self.simpleGitHubEndpoint.replacing(task: task)
                        return ["parameters": parameters,
                                "encoder": encoder,
                                "endpoint": endpoint]
                    }
                }
            }

            context("when task is .upload") {

                let data = "Hello Moya".data(using: .utf8)!

                context("without params") {
                    itBehavesLike("endpoint with no request property changed") {
                        return ["task": Task.upload(source: .rawData(data)),
                                "endpoint": self.simpleGitHubEndpoint]
                    }
                }

                context("with body params") {
                    context("value is .raw") {
                        itBehavesLike("endpoint with encoded parameters") {
                            let data = "Hello Moya".data(using: .utf8)!
                            let task: Task = .upload(source: .rawData(data), bodyParams: .raw(data))
                            let endpoint = self.simpleGitHubEndpoint.replacing(task: task)
                            return ["parameters": data,
                                    "encoder": RawDataParameterEncoder(),
                                    "endpoint": endpoint]
                        }
                    }

                    context("value is .json") {
                        itBehavesLike("endpoint with encoded parameters") {
                            let encoder = JSONParameterEncoder.default
                            let task: Task = .upload(source: .rawData(data), bodyParams: .json(parameters, encoder))
                            let endpoint = self.simpleGitHubEndpoint.replacing(task: task)
                            return ["parameters": parameters,
                                    "encoder": encoder,
                                    "endpoint": endpoint]
                        }
                    }

                    context("value is .urlEncoded") {
                        itBehavesLike("endpoint with encoded parameters") {
                            let encoder = URLEncodedFormParameterEncoder(destination: .httpBody)
                            let task: Task = .upload(source: .rawData(data), bodyParams: .urlEncoded(parameters, encoder))
                            let endpoint = self.simpleGitHubEndpoint.replacing(task: task)
                            return ["parameters": parameters,
                                    "encoder": encoder,
                                    "endpoint": endpoint]
                        }
                    }

                    context("value is .custom") {
                        itBehavesLike("endpoint with encoded parameters") {
                            let encoder = PropertyListEncoder()
                            let task: Task = .upload(source: .rawData(data), bodyParams: .custom(parameters, encoder))
                            let endpoint = self.simpleGitHubEndpoint.replacing(task: task)
                            return ["parameters": parameters,
                                    "encoder": encoder,
                                    "endpoint": endpoint]
                        }
                    }
                }

                context("with query params") {
                    itBehavesLike("endpoint with encoded parameters") {
                        let encoder = URLEncodedFormParameterEncoder(destination: .queryString)
                        let task: Task = .upload(source: .rawData(data), queryParams: .query(parameters, encoder))
                        let endpoint = self.simpleGitHubEndpoint.replacing(task: task)
                        return ["parameters": parameters,
                                "encoder": encoder,
                                "endpoint": endpoint]
                    }
                }
            }

            context("when task is .download") {

                let destination: DownloadDestination = { url, _ in (destinationURL: url, options: []) }

                context("without params") {
                    itBehavesLike("endpoint with no request property changed") {
                        return ["task": Task.download(destination: destination),
                                "endpoint": self.simpleGitHubEndpoint]
                    }
                }

                context("with body params") {
                    context("value is .raw") {
                        itBehavesLike("endpoint with encoded parameters") {
                            let data = "Hello Moya".data(using: .utf8)!
                            let task: Task = .download(destination: destination, bodyParams: .raw(data))
                            let endpoint = self.simpleGitHubEndpoint.replacing(task: task)
                            return ["parameters": data,
                                    "encoder": RawDataParameterEncoder(),
                                    "endpoint": endpoint]
                        }
                    }

                    context("value is .json") {
                        itBehavesLike("endpoint with encoded parameters") {
                            let encoder = JSONParameterEncoder.default
                            let task: Task = .download(destination: destination, bodyParams: .json(parameters, encoder))
                            let endpoint = self.simpleGitHubEndpoint.replacing(task: task)
                            return ["parameters": parameters,
                                    "encoder": encoder,
                                    "endpoint": endpoint]
                        }
                    }

                    context("value is .urlEncoded") {
                        itBehavesLike("endpoint with encoded parameters") {
                            let encoder = URLEncodedFormParameterEncoder(destination: .httpBody)
                            let task: Task = .download(destination: destination, bodyParams: .urlEncoded(parameters, encoder))
                            let endpoint = self.simpleGitHubEndpoint.replacing(task: task)
                            return ["parameters": parameters,
                                    "encoder": encoder,
                                    "endpoint": endpoint]
                        }
                    }

                    context("value is .custom") {
                        itBehavesLike("endpoint with encoded parameters") {
                            let encoder = PropertyListEncoder()
                            let task: Task = .download(destination: destination, bodyParams: .custom(parameters, encoder))
                            let endpoint = self.simpleGitHubEndpoint.replacing(task: task)
                            return ["parameters": parameters,
                                    "encoder": encoder,
                                    "endpoint": endpoint]
                        }
                    }
                }

                context("with query params") {
                    itBehavesLike("endpoint with encoded parameters") {
                        let encoder = URLEncodedFormParameterEncoder(destination: .queryString)
                        let task: Task = .download(destination: destination, queryParams: .query(parameters, encoder))
                        let endpoint = self.simpleGitHubEndpoint.replacing(task: task)
                        return ["parameters": parameters,
                                "encoder": encoder,
                                "endpoint": endpoint]
                    }
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
