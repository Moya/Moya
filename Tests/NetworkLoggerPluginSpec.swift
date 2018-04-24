import Quick
import Nimble
import Moya
import Result
import enum Alamofire.AFError

final class NetworkLoggerPluginSpec: QuickSpec {
    override func spec() {

        let output = TestNetworkLoggerOutput()

        var log: String { return output.log }

        let plugin = NetworkLoggerPlugin(verbose: true, output: output)

        let pluginWithCurl = NetworkLoggerPlugin(verbose: true, cURL: true, output: output)

        let pluginWithRequestDataFormatter = NetworkLoggerPlugin(verbose: true,
                                                                 output: output,
                                                                 responseDataFormatter: { _ in
            return "formatted request body".data(using: .utf8)!
        })

        let pluginWithResponseDataFormatter = NetworkLoggerPlugin(verbose: true,
                                                                  output: output,
                                                                  responseDataFormatter: { _ in
            return "formatted body".data(using: .utf8)!
        })

        let outputWithCustomFormat = TestNetworkLoggerOutputWithCustomFormat()

        let pluginWithOutputFormat = NetworkLoggerPlugin(verbose: true, output: outputWithCustomFormat)

        let dateFormatStringRegex = "[0-9]{2}/[0-9]{2}/[0-9]{4} [0-9]{2}:[0-9]{2}:[0-9]{2}"

        beforeEach {
            output.log = ""
            outputWithCustomFormat.log = ""
        }
        
        it("prefixes output with logger id, date, identifier") {

            plugin.willSend(TestBodyRequest(), target: GitHub.zen)

            expect(log).to(match("Moya_Logger: \\[\(dateFormatStringRegex)\\] Request: "))
            expect(log).to(match("Moya_Logger: \\[\(dateFormatStringRegex)\\] Request Headers: "))
            expect(log).to(match("Moya_Logger: \\[\(dateFormatStringRegex)\\] HTTP Request Method: "))
            expect(log).to(match("Moya_Logger: \\[\(dateFormatStringRegex)\\] Request Body: "))
        }

        it("customizes output prefix with the given format") {

            pluginWithOutputFormat.willSend(TestBodyRequest(), target: GitHub.zen)

            let log = outputWithCustomFormat.log

            expect(log).to( beginWith("Request: https://api.github.com/zen") )
            expect(log).notTo(contain("Moya_Logger: "))
            expect(log).notTo(match(dateFormatStringRegex))
        }

        it("outputs all request fields with body") {

            plugin.willSend(TestBodyRequest(), target: GitHub.zen)

            expect(log).to( contain("Request: https://api.github.com/zen") )
            expect(log).to( contain("Request Headers: [\"Content-Type\": \"application/json\"]") )
            expect(log).to( contain("HTTP Request Method: GET") )
            expect(log).to( contain("Request Body: cool body") )
        }

        it("outputs all request fields with stream") {

            plugin.willSend(TestStreamRequest(), target: GitHub.zen)

            expect(log).to( contain("Request: https://api.github.com/zen") )
            expect(log).to( contain("Request Headers: [\"Content-Type\": \"application/json\"]") )
            expect(log).to( contain("HTTP Request Method: GET") )
            expect(log).to( contain("Request Body Stream:") )
        }

        it("will output invalid request when reguest is nil") {

            plugin.willSend(TestNilRequest(), target: GitHub.zen)

            expect(log).to( contain("Request: (invalid request)") )
        }

        it("outputs the response data") {
            let response = Response(statusCode: 200, data: "cool body".data(using: .utf8)!, response: HTTPURLResponse(url: URL(string: url(GitHub.zen))!, mimeType: nil, expectedContentLength: 0, textEncodingName: nil))
            let result: Result<Moya.Response, MoyaError> = .success(response)

            plugin.didReceive(result, target: GitHub.zen)

            expect(log).to( contain("Response:") )
            expect(log).to( contain("{ URL: https://api.github.com/zen }") )
            expect(log).to( contain("cool body") )
        }

        it("outputs the formatted response data") {
            let response = Response(statusCode: 200, data: "cool body".data(using: .utf8)!, response: HTTPURLResponse(url: URL(string: url(GitHub.zen))!, mimeType: nil, expectedContentLength: 0, textEncodingName: nil))
            let result: Result<Moya.Response, MoyaError> = .success(response)

            pluginWithResponseDataFormatter.didReceive(result, target: GitHub.zen)

            expect(log).to( contain("Response:") )
            expect(log).to( contain("{ URL: https://api.github.com/zen }") )
            expect(log).to( contain("formatted body") )
        }

        it("outputs the formatted request data") {
            let response = Response(statusCode: 200, data: "cool body".data(using: .utf8)!, response: HTTPURLResponse(url: URL(string: url(GitHub.zen))!, mimeType: nil, expectedContentLength: 0, textEncodingName: nil))
            let result: Result<Moya.Response, MoyaError> = .success(response)

            pluginWithRequestDataFormatter.didReceive(result, target: GitHub.zen)

            expect(log).to( contain("Response:") )
            expect(log).to( contain("{ URL: https://api.github.com/zen }") )
            expect(log).to( contain("formatted request body") )
        }

        it("outputs an empty response message") {
            let emptyResponseError = AFError.responseSerializationFailed(reason: .inputDataNil)
            let result: Result<Moya.Response, MoyaError> = .failure(.underlying(emptyResponseError, nil))

            plugin.didReceive(result, target: GitHub.zen)

            expect(log).to( contain("Response: Received empty network response for zen.") )
        }

        it("outputs cURL representation of request") {
            pluginWithCurl.willSend(TestCurlBodyRequest(), target: GitHub.zen)

            expect(log).to( contain("$ curl -i") )
            expect(log).to( contain("-H \"Content-Type: application/json\"") )
            expect(log).to( contain("-d \"cool body\"") )
            expect(log).to( contain("\"https://api.github.com/zen\"") )

        }
    }
}

private class TestNetworkLoggerOutputWithCustomFormat: NetworkLoggerOutput {
    var log: String = ""

    func print(_ separator: String, terminator: String, items: Any...) {
        //mapping the Any... from items to a string that can be compared
        let stringArray: [String] = items.map { $0 as? String }.flatMap { $0 }
        let string: String = stringArray.reduce("") { $0 + $1 + " " }
        log += string
    }

    func format(_ loggerId: String, date: String, identifier: String, message: String) -> String {
        return "\(identifier): \(message)"
    }
}

private class TestStreamRequest: RequestType {
    var request: URLRequest? {
        var request = URLRequest(url: URL(string: url(GitHub.zen))!)
        request.allHTTPHeaderFields = ["Content-Type": "application/json"]
        request.httpBodyStream = InputStream(data: "cool body".data(using: .utf8)!)

        return request
    }

    func authenticate(user: String, password: String, persistence: URLCredential.Persistence) -> Self {
        return self
    }

    func authenticate(usingCredential credential: URLCredential) -> Self {
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

    func authenticate(user: String, password: String, persistence: URLCredential.Persistence) -> Self {
        return self
    }

    func authenticate(usingCredential credential: URLCredential) -> Self {
        return self
    }
}

private class TestCurlBodyRequest: RequestType, CustomDebugStringConvertible {
    var request: URLRequest? {
        var request = URLRequest(url: URL(string: url(GitHub.zen))!)
        request.allHTTPHeaderFields = ["Content-Type": "application/json"]
        request.httpBody = "cool body".data(using: .utf8)

        return request
    }

    func authenticate(user: String, password: String, persistence: URLCredential.Persistence) -> Self {
        return self
    }

    func authenticate(usingCredential credential: URLCredential) -> Self {
        return self
    }

    var debugDescription: String {
        return ["$ curl -i", "-H \"Content-Type: application/json\"", "-d \"cool body\"", "\"https://api.github.com/zen\""].joined(separator: " \\\n\t")
    }
}

private class TestNilRequest: RequestType {
    var request: URLRequest? {
        return nil
    }

    func authenticate(user: String, password: String, persistence: URLCredential.Persistence) -> Self {
        return self
    }

    func authenticate(usingCredential credential: URLCredential) -> Self {
        return self
    }
}
