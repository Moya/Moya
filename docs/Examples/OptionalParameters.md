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
            var params: [String: Any] = [:]
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
            return .post
        default:
            return .get
        }
    }
//...
}
```


Important Note
--------------
You **have to** add optional parameters like shown above, one per line. Optional parameters won't be removed in case of ```nil``` if you try to initialize them within one line, e.g.:

```swift
//...
	// This won't work!
	public var parameters: [String: Any]? {
	    switch self {
	    case .users(let limit):
	        let params: [String: Any] = ["limit": limit]
	        return params
        default:
            return nil
        }
    }
//...
```

In this case the URL request would contain a parameter like ```api/users?limit=nil``` if limit is ```nil```.
