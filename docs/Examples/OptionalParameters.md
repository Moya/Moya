Optional request parameters
===========================

Suppose you want to call `api/users?limit=10` but also `api/users`:

```swift
public enum MyService {
	case users(limit: Int?)
}

extension MyService: TargetType {
//...
	public var parameters: [String: Any]? {
	    switch self {
	    case .users(let limit):
	        var params: [String : Any] = [:]
	        params["limit"] = limit
	        return params
        default:
            return nil
        }
    }
//...
}
```

In this case `params["limit"] = nil` will be equal of removing object for key `limit`.

This will work for any type of requests, since method type is defined in separate property

```swift
extension MyService: TargetType {
//...
    public var method: Moya.Method {
        switch self {
        case .emailAuth:
            return .POST
        default:
            return .GET
        }
    }
//...
}
```
