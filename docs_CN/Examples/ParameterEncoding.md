# 使用自定义的ParameterEncoding
Moya 使用字典作为JSON数据的根容器。但是有时候您需要将JSON数组作为根元素发送。这儿有一个解决方案，即通过编写您自己的参数编码 :

定义一个struct或者一个class:

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

配置target:

```swift
public var task: Task {
    switch self {
    case .api:
        return .requestParameters(parameters: ["jsonArray": ["Yes", "What", "abc"]], encoding: JSONArrayEncoding.default)
    }
}
```

这将会把`.api`接口的数据作为JSON数组`["Yes", "What", "Abc"]`发送。更多信息, 查看讨论: [#467](https://github.com/Moya/Moya/issues/467)
