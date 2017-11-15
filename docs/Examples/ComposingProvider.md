# Composing Provider and refreshing session automatically

Based on [Artsy's implementation](https://github.com/artsy/eidolon/blob/master/Kiosk/App/Networking/Networking.swift).

Used RxSwift.

```swift
final class TokenProvider<Target> where Target: Moya.TargetType {
	private let provider: MoyaProvider<Target>

	// init with all default values to initialize MoyaProvider
	init(endpointClosure: @escaping MoyaProvider<Target>.EndpointClosure = MoyaProvider.defaultEndpointMapping,
	     requestClosure: @escaping MoyaProvider<Target>.RequestClosure = MoyaProvider.defaultRequestMapping,
	     stubClosure: @escaping MoyaProvider<Target>.StubClosure = MoyaProvider.neverStub,
	     manager: Manager = MoyaProvider<Target>.defaultAlamofireManager(),
	     plugins: [PluginType] = [],
	     trackInflights: Bool = false) {

		self.provider = MoyaProvider(endpointClosure: endpointClosure,
		                             requestClosure: requestClosure,
		                             stubClosure: stubClosure,
		                             manager: manager,
		                             plugins: plugins,
		                             trackInflights: trackInflights)
	}

	func request(_ token: Target) -> Single<Moya.Response> {
		let actualRequest = provider.rx.request(token)

		return self.XAppTokenRequest().flatMap { _ in
			actualRequest
		}
	}

	// Request to fetch and store new XApp token if the current token is missing or expired.
	private func XAppTokenRequest() -> Single<String?> {
		var appToken = UserInfo.shared.accessToken

		// If we have a valid token, just return it
		if appToken.isValidAndNotExpired {
			return Single.just(appToken.token)
		}

		// Do not attempt to refresh a session if we don't have valid credentials
		guard let userId = UserInfo.shared.userId, let refreshToken = UserInfo.shared.accessToken.refreshToken else {
			return Single.just(nil)
		}

		// Create actual refresh request
		let newTokenRequest = provider.rx.request(MyService.refreshSession(userId: userId, refreshToken: refreshToken))
			.filterSuccessfulStatusCodes()
			.mapJSON()
			.map { element -> (token: String?, refreshToken: String?, expiryTime: Double?) in
				guard let dictionary = element as? NSDictionary else { return (token: nil, refreshToken: nil, expiryTime: nil) }

				return (token: dictionary["auth_token"] as? String, refreshToken: dictionary["refresh_token"] as? String, expiryTime: dictionary["session_time_valid"] as? Double)
			}
			.do(onNext: { element in
				UserInfo.shared.accessToken.token = element.0
				UserInfo.shared.accessToken.refreshToken = element.1
				UserInfo.shared.accessToken.setExpirySecondsLeft(element.2)
			})
			.map { (token, refreshToken, expiry) -> String? in
				return token
			}
			.catchError { e -> Single<String?> in
				guard let error = e as? MoyaError else { throw e }
				guard case .statusCode(let response) = error else { throw e }

				// If we have 401 error - delete all credentials and handle logout
				if response.statusCode == 401 {
					UserInfo.shared.invalidate()
					Router.shared.popToLoginScreen()
				}
				throw error
		}

		return newTokenRequest
	}
}
```

Create custom provider the same way as usual:

```swift
let myServiceProvider = TokenProvider()
```

Also you can pass parameters there:

```swift
let myServiceProvider = TokenProvider(endpointClosure: endpointClosure, plugins: [NetworkLogger()])
```