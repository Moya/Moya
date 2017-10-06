# Use a custom ParameterEncoding
Moya is using dictionary as a root container for JSON data. But sometimes you will need to send JSON array as a root element instead. Here is solution by writing your own parameter encoding:

Define a struct or class:
```swift
import Alamofire

struct JSONArrayEncoding: ParameterEncoding {
    static let `default` = JSONArrayEncoding()

    func encode(_ urlRequest: URLRequestConvertible, with parameters: Parameters?) throws -> URLRequest {
        var request = try urlRequest.asURLRequest()

        guard let json = parameters?["jsonArray"] else {
            return request
        }

        let data = try JSONSerialization.data(withJSONObject: json, options: [])

        if request.value(forHTTPHeaderField: "Content-Type") == nil {
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        }

        request.httpBody = data

        return request
    }
}
```

Configure the target:

```swift
public var task: Task {
    switch self {
    case .api:
        return .requestParameters(parameters: ["jsonArray": ["Yes", "What", "abc"]], encoding: JSONArrayEncoding.default)
    }
}
```

This will send data as a JSON array `["Yes", "What", "Abc"]` for the `.api` endpoint. For more information, see discussion in: [#467](https://github.com/Moya/Moya/issues/467)
