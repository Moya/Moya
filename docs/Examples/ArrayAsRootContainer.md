# Use Array instead of Dictionary as JSON root container

Moya is using a dictionary as the root container for JSON data. But
sometimes you will need to send a JSON array as the root element instead.
Here is solution using a custom `ParameterEncoding` (see [Moya ParameterEncoding Documentation] and discussion
in [#467](https://github.com/Moya/Moya/issues/467) for details):

Define JSONStringArrayEncoding custom `ParameterEncoding`:

```swift
struct JSONStringArrayEncoding: ParameterEncoding {

    public static var arrayKey = "jsonArray"

    public static var `default`: JSONStringArrayEncoding { return JSONStringArrayEncoding() }

    func encode(_ urlRequest: URLRequestConvertible, with parameters: Parameters?) throws -> URLRequest {
        var urlRequest = try urlRequest.asURLRequest()

        let json = try JSONSerialization.data(withJSONObject: parameters!["jsonArray"]!, options: .prettyPrinted)
        urlRequest.setValue("application/json; charset=utf-8", forHTTPHeaderField: "Content-Type")
        urlRequest.httpBody = json

        return urlRequest
    }
}
```

Configure the target:

```swift
var parameters: [String: Any]? {
    switch self {
    case .someAPI:
        return [JSONStringArrayEncoding.arrayKey: ["Yes", "What", "Abc"]]
    default:
    return nil
    }
}

var parameterEncoding: Moya.ParameterEncoding {
    switch self {
    case .someAPI:
        return JSONStringArrayEncoding.default
    default:
        return JSONEncoding.default
    }
}
```

This will send data as a JSON array `["Yes", "What", "Abc"]` for the `.someAPI` endpoint.

[Moya ParameterEncoding Documentation]: https://github.com/Alamofire/Alamofire#custom-encoding