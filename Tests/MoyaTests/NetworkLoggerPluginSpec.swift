import Quick
import Nimble
import Moya
import Foundation
import enum Alamofire.AFError

final class NetworkLoggerPluginSpec: QuickSpec {
    override func spec() {

        var log = ""

        let customLoggerOutput: NetworkLoggerPlugin.Configuration.OutputType = { log += $1.joined() }

        let plugin: NetworkLoggerPlugin = {
            let plugin = NetworkLoggerPlugin()
            plugin.configuration.output = customLoggerOutput
            plugin.configuration.logOptions = .verbose
            return plugin
        }()

        beforeEach {
            log = ""
        }

        it("outputs all request fields with body") {

            plugin.willSend(TestBodyRequest(), target: GitHub.zen)

            let possibleHeaders = ["Request Headers: [\"Accept-Language\": \"en-US\", \"Content-Type\": \"application/json\"]",
                                   "Request Headers: [\"Content-Type\": \"application/json\", \"Accept-Language\": \"en-US\"]"]
            expect(log).to(contain("Request: https://api.github.com/zen"))
            expect(log).to(containOne(of: possibleHeaders))
            expect(log).to(contain("HTTP Request Method: GET"))
            expect(log).to(contain("Request Body: cool body"))
        }

        it("outputs all request fields with stream") {

            plugin.willSend(TestStreamRequest(), target: GitHub.zen)

            let possibleHeaders = ["Request Headers: [\"Accept-Language\": \"en-US\", \"Content-Type\": \"application/json\"]",
                                   "Request Headers: [\"Content-Type\": \"application/json\", \"Accept-Language\": \"en-US\"]"]
            expect(log).to(contain("Request: https://api.github.com/zen"))
            expect(log).to(containOne(of: possibleHeaders))
            expect(log).to(contain("HTTP Request Method: GET"))
            expect(log).to(contain("Request Body Stream:"))
        }

        it("will output invalid request when reguest is nil") {

            plugin.willSend(TestNilRequest(), target: GitHub.zen)

            expect(log).to(contain("Request: (invalid request)"))
        }

        it("outputs the response data") {
            let response = Response(statusCode: 200, data: "cool body".data(using: .utf8)!, response: HTTPURLResponse(url: URL(string: url(GitHub.zen))!, mimeType: nil, expectedContentLength: 0, textEncodingName: nil))
            let result: Result<Moya.Response, MoyaError> = .success(response)

            plugin.didReceive(result, target: GitHub.zen)

            expect(log).to(contain("Response:"))
            expect(log).to(contain("{ URL: https://api.github.com/zen }"))
            expect(log).to(contain("Response Body: cool body"))
        }

        it("outputs a validation error message") {
            let response = Response(statusCode: 500, data: "Internal error".data(using: .utf8)!, response: HTTPURLResponse(url: URL(string: url(GitHub.zen))!, mimeType: nil, expectedContentLength: 0, textEncodingName: nil))
            let validationResponseError = AFError.responseValidationFailed(reason: .unacceptableStatusCode(code: 500))
            let result: Result<Moya.Response, MoyaError> = .failure(.underlying(validationResponseError, response))

            plugin.didReceive(result, target: GitHub.zen)

            expect(log).to( contain("Response:") )
            expect(log).to( contain("{ URL: https://api.github.com/zen }") )
            expect(log).to( contain("Internal error") )
        }

        it("outputs a serialization error message") {
            let emptyResponseError = AFError.responseSerializationFailed(reason: .inputFileNil)
            let result: Result<Moya.Response, MoyaError> = .failure(.underlying(emptyResponseError, nil))

            plugin.didReceive(result, target: GitHub.zen)

            expect(log).to( contain("Error calling zen : underlying(Alamofire.AFError.responseSerializationFailed(reason: Alamofire.AFError.ResponseSerializationFailureReason.inputFileNil), nil)") )
        }

        it("outputs cURL representation of request") {
            let pluginWithCurl: NetworkLoggerPlugin = {
                let plugin = NetworkLoggerPlugin()
                plugin.configuration.output = customLoggerOutput
                plugin.configuration.logOptions = [.formatRequestAscURL]
                return plugin
            }()

            pluginWithCurl.willSend(TestCurlBodyRequest(), target: GitHub.zen)

            expect(log).to(contain("$ curl -i"))
            expect(log).to(contain("-H \"Content-Type: application/json\""))
            expect(log).to(contain("-d \"cool body\""))
            expect(log).to(contain("\"https://api.github.com/zen\""))
        }

        it("outputs the formatted request data") {
            let pluginWithRequestDataFormatter: NetworkLoggerPlugin = {
                let plugin = NetworkLoggerPlugin()
                plugin.configuration.output = customLoggerOutput
                plugin.configuration.logOptions = .verbose
                plugin.configuration.formatter.requestData = { _ in "formatted request body" }
                return plugin
            }()

            pluginWithRequestDataFormatter.willSend(TestBodyRequest(), target: GitHub.zen)

            expect(log).to(contain("Request: https://api.github.com/zen"))
            expect(log).to(contain("Body: formatted request body"))
        }

        it("outputs the customized entries") {
            let pluginWithEntryFormatter: NetworkLoggerPlugin = {
                let plugin = NetworkLoggerPlugin()
                plugin.configuration.output = customLoggerOutput
                plugin.configuration.formatter.entry = { _, _, _ in "formatted log entry" }
                return plugin
            }()

            pluginWithEntryFormatter.willSend(TestBodyRequest(), target: GitHub.zen)

            expect(log).to(contain("formatted log entry"))
        }

        it("outputs the formatted response data") {
            let response = Response(statusCode: 200, data: "cool body".data(using: .utf8)!, response: HTTPURLResponse(url: URL(string: url(GitHub.zen))!, mimeType: nil, expectedContentLength: 0, textEncodingName: nil))
            let result: Result<Moya.Response, MoyaError> = .success(response)

            let pluginWithResponseDataFormatter: NetworkLoggerPlugin = {
                let plugin = NetworkLoggerPlugin()
                plugin.configuration.output = customLoggerOutput
                plugin.configuration.formatter.responseData = { _ in "formatted response body" }
                plugin.configuration.logOptions = .verbose
                return plugin
            }()

            pluginWithResponseDataFormatter.didReceive(result, target: GitHub.zen)

            expect(log).to(contain("Response:"))
            expect(log).to(contain("{ URL: https://api.github.com/zen }"))
            expect(log).to(contain("Response Body: formatted response body"))
        }
    }
}

private class TestStreamRequest: RequestType {

    var request: URLRequest? {
        var request = URLRequest(url: URL(string: url(GitHub.zen))!)
        request.allHTTPHeaderFields = ["Content-Type": "application/json"]
        request.httpBodyStream = InputStream(data: "cool body".data(using: .utf8)!)

        return request
    }

    var sessionHeaders: [String: String] {
        ["Content-Type": "application/badJson", "Accept-Language": "en-US"]
    }

    func authenticate(username user: String, password: String, persistence: URLCredential.Persistence) -> Self { self }

    func authenticate(with credential: URLCredential) -> Self { self }

    func cURLDescription(calling handler: @escaping (String) -> Void) -> Self {
        handler("")
        return self
    }
}

private class TestBodyRequest: RequestType {
    var request: URLRequest? {
        var request = URLRequest(url: URL(string: url(GitHub.zen))!)
        request.allHTTPHeaderFields = ["Content-Type": "application/json"]
        request.httpBody = "cool body".data(using: .utf8)

        return request
    }

    var sessionHeaders: [String: String] {
        ["Content-Type": "application/badJson", "Accept-Language": "en-US"]
    }

    func authenticate(username user: String, password: String, persistence: URLCredential.Persistence) -> Self { self }

    func authenticate(with credential: URLCredential) -> Self { self }

    func cURLDescription(calling handler: @escaping (String) -> Void) -> Self {
        handler("")
        return self
    }
}

private class TestCurlBodyRequest: RequestType {
    var request: URLRequest? {
        var request = URLRequest(url: URL(string: url(GitHub.zen))!)
        request.allHTTPHeaderFields = ["Content-Type": "application/json"]
        request.httpBody = "cool body".data(using: .utf8)

        return request
    }

    var sessionHeaders: [String: String] {
        ["Content-Type": "application/badJson", "Accept-Language": "en-US"]
    }

    func authenticate(username user: String, password: String, persistence: URLCredential.Persistence) -> Self { self }

    func authenticate(with credential: URLCredential) -> Self { self }

    func cURLDescription(calling handler: @escaping (String) -> Void) -> Self {
        handler(["$ curl -i", "-H \"Content-Type: application/json\"", "-d \"cool body\"", "\"https://api.github.com/zen\""].joined(separator: " \\\n\t"))
        return self
    }
}

private class TestNilRequest: RequestType {
    var request: URLRequest? { nil }

    var sessionHeaders: [String: String] { [:] }

    func authenticate(username user: String, password: String, persistence: URLCredential.Persistence) -> Self { self }

    func authenticate(with credential: URLCredential) -> Self { self }

    func cURLDescription(calling handler: @escaping (String) -> Void) -> Self {
        handler("")
        return self
    }
}
