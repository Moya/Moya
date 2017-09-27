# 可选的请求参数

假设你想调用 `api/users?limit=10` 也希望能调用 `api/users`:

```swift
public enum MyService {
    case users(limit: Int?)
}

extension MyService: TargetType {
//...
    public var task: Task {
        switch self {
        case .users(let limit):
            var params: [String: Any] = [:]
            params["limit"] = limit
            return .requestParameters(parameters: params, encoding: URLEncoding.default)
        default:
            return .requestPlain
        }
    }
//...
}
```

在这个例子中 `params["limit"] = nil` 等同于移除key `limit`的值 。

这对任何类型的请求都适用, 因为方法的类型是在单独的属性中定义的

```swift
extension MyService: TargetType {
//...
    public var method: Moya.Method {
        switch self {
        case .emailAuth:
            return .post
        default:
            return .get
        }
    }
//...
}
```

## 重要声明

您 **必须** 像上面演示的那样添加可选参数, 每行一个。 如果您试着把它们初始化在一行中，那么可选参数在值为nil时不会被移除 例如:

```swift
//...
	// This won't work!
	public var parameters: [String: Any]? {
	    switch self {
	    case .users(let limit):
	        let params: [String: Any] = ["limit": limit]
	        return .requestParameters(parameters: params, encoding: URLEncoding.default)
        default:
            return .requestPlain
        }
    }
//...
```

在这种情况下，如果limit值为 ```nil```， URL请求将包含一个像这样的参数  ```api/users?limit=nil``` .
