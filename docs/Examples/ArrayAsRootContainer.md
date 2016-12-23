Use Array instead of Dictionary as JSON root container
======================================================

Moya is using dictionary as a root container for JSON data. But
sometimes you will need to send JSON array as a root element instead.
Here is solution by using `.custom` parameter encoding (see discussion
in [#467](https://github.com/Moya/Moya/issues/467)):

Define JsonArrayEncoding closure:

```swift
    var req = request.URLRequest
let JsonArrayEncodingClosure: (URLRequestConvertible, [String: Any]?) -> (URLRequest, Error?) = { request, data in

    do {
        let json = try JSONSerialization.data(withJSONObject: data!["jsonArray"]!, options: .prettyPrinted)
        req.setValue("application/json; charset=utf-8", forHTTPHeaderField: "Content-Type")
        req.httpBody = json
    } catch {
        return (req, nil)
    }
    return (req, nil)
}
```

Configure target :
```swift
  var parameters: [String: Any]? {
        switch self {
        case .someAPI:
            return ["jsonArray": ["Yes", "What", "Abc"]]
        default:
            return nil
        }
    }

    var parameterEncoding: Moya.ParameterEncoding {
        switch self {
        case .someAPI:
            return ParameterEncoding.custom(JsonArrayEncodingClosure)
        default:
            return ParameterEncoding.json
        }
    }
```

This will send data as JSON array `["Yes", "What", "Abc"]` for `.someAPI` endpoint.
