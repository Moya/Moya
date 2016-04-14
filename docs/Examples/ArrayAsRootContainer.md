Use Array instead of Dictionary as JSON root container
======================================================

Moya is using dictionary as a root container for JSON data. But 
sometimes you will need to send JSON array as a root element instead.
Here is solution by using `.Custom` parameter encoding (see discussion
in [#467](https://github.com/Moya/Moya/issues/467)):

Define JsonArrayEncoding closure:

```swift
let JsonArrayEncodingClosure: (URLRequestConvertible, [String:AnyObject]?) -> (NSMutableURLRequest, NSError?) = { request, data in
    var req = request.URLRequest as NSMutableURLRequest

    do {
        let json = try NSJSONSerialization.dataWithJSONObject(data!["jsonArray"]!, options: NSJSONWritingOptions.PrettyPrinted)
        req.setValue("application/json; charset=utf-8", forHTTPHeaderField: "Content-Type")
        req.HTTPBody = json
    } catch {
        return (req, nil)
    }
    return (req, nil)
}
```

Configure target :
```swift
  var parameters: [String:AnyObject]? {
        switch self {
        case .SomeAPI:
            return ["jsonArray": ["Yes", "What", "Abc"]]
        default:
            return nil
        }
    }

    var parameterEncoding: Moya.ParameterEncoding {
        switch self {
        case .SomeAPI:
            return ParameterEncoding.Custom(JsonArrayEncodingClosure)
        default:
            return ParameterEncoding.JSON
        }
    }
```

This will send data as JSON array `["Yes", "What", "Abc"]` for `.SomeAPI` endpoint.
