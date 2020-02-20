import Quick
@testable import Moya
import Nimble
import Foundation

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

    it("encodes all Parameters") {
      let jsonParams: Task.BodyParams = .json(["This is": "a JSON example"])
      let urlParams: Task.URLParams = .init(["This is": "a query example"])

      let task = Task.request(bodyParams: jsonParams, urlParams: urlParams)
      let endpointRequest = try! endpoint.replacing(task: task).urlRequest()

      let testRequest = URLRequest(url: URL(string: endpoint.url)!)

      // Checking usage of bodyParams
      let jsonEncodedRequest = try! jsonParams.encoder.encode(AnyEncodable(jsonParams.encodable), into: testRequest)
      expect(jsonEncodedRequest.httpBody).to(equal(endpointRequest.httpBody))
      expect(jsonEncodedRequest.allHTTPHeaderFields?["Content-Type"]).to(equal(endpointRequest.allHTTPHeaderFields?["Content-Type"]))

      // Checking usage of urlParams
      let urlEncodedRequest = try! urlParams.encoder.encode(AnyEncodable(urlParams.encodable), into: testRequest)
      expect(urlEncodedRequest.url?.absoluteString).to(equal(endpointRequest.url?.absoluteString))
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
