# Response Handling

A very basic example of how to handle the result of a request in Moya looks like this:

```swift
provider.request(.zen) { result in
    switch result {
    case let .success(moyaResponse):
        let data = moyaResponse.data // Data, your JSON response is probably in here!
        let statusCode = moyaResponse.statusCode // Int - 200, 401, 500, etc

        // do something in your app
    case let .failure(error):
        // TODO: handle the error == best. comment. ever.
    }
}
```

The result of a request is of the type: `Result<Moya.Response, MoyaError>`.
`Result` is basically an enum with associated values.
A simplified version is:

```swift
enum Result {
    case success(Moya.Response)
    case failure(Error)
}
````

Therefore we switch over the result.

Moya comes with useful reactive bindings, both for `RxSwift` and `ReactiveSwift`, which means the above example can be done in these ways as well:

Here is an example for `RxSwift`:

```swift
provider.rx.request(.zen).subscribe { event in
    switch event {
    case .success(let response):
        // do something with the data
    case .error(let error):
        // handle the error
    }
}

// Or alternatively

provider.rx.request(.zen).subscribe(
    onSuccess: { response in
        // do something with the data
    },
    onError: { error in
        // handle the error
    }
)
```

## Basics

The `Response` object contains several properties:

- `data`: the data of the response as a `Data` object.
- `statusCode`: the status code of the response as an `Int`.
- `request`: the request that resulted in the response as a `URLRequest?`.
- `response`: the raw response as a `HTTPURLResponse?`.

The `Response` object also has `description` and `debugDescription` to help with logging and debugging.
Furthermore it is possible to compare two `Response` objects.
`Response` objects are equal if status codes, data, and the raw response are equal.

## Extensions

Moya provides several useful extensions to `Response`.
You can always extend with your own if necessary.

### Filtering

Usually you want to only handle responses within a limited set of status codes.
Moya has a couple of extensions for common cases: `filterSuccessfulStatusCodes()` and `filterSuccessfulStatusAndRedirectCodes()`

`filterSuccessfulStatusCodes()` throws a `MoyaError.statusCode(Response)` error if it encounters a status code that is not 200-299.
`filterSuccessfulStatusAndRedirectCodes()` will likewise throw the same error if it encounters a status code that is not 200-399.

A basic example is:

```swift
provider.request(.zen) { result in
    switch result {
    case let .success(moyaResponse):
        do {
            let filteredResponse = try moyaResponse.filterSuccessfulStatusCodes() // gives back a Response or throws an error.
            // We know if we get past this that the status code is 200-299.
            // Do something with the filteredResponse.
        }
        catch let error {
            // TODO: handle the error == best. comment. ever.
        }
    case let .failure(error):
        // TODO: handle the error == best. comment. ever.
    }
}
```

If you have specific needs there are also the more general:

- `filter(statusCode: Int)` which only accepts a single status code and throws an error otherwise.
- `filter(statusCodes: ClosedRange<Int>)` which accepts a range of status codes and throws an error if the response's status code doesn't fall within the range.

A basic example is:

```swift
provider.request(.zen) { result in
    switch result {
    case let .success(moyaResponse):
        do {
            let filteredResponse = try moyaResponse.filter(statusCodes: 200...299) // same as filterSuccessfulStatusCodes
            // We know if we get past this that the status code is 200-299.
            // Do something with the filteredResponse.
        }
        catch let error {
            // TODO: handle the error == best. comment. ever.
        }
    case let .failure(error):
        // TODO: handle the error == best. comment. ever.
    }
}
```

These extensions are also available in `RxSwift`, which makes the result handling a bit simpler:

```swift
provider.rx.request(.zen)
    .filterSuccessfulStatusCodes()
    .subscribe { event in
        switch event {
        case .success(let response):
            // do something with the data
        case .error(let error):
            // handle the error, which can be an underlying error or a status code error
        }
    }
}
```

The benefit of the reactive extensions is that error handling can be done in a central place, rather than having to copy/paste or otherwise handle an error the same way.

### MapJSON

Moya also has an extension to map your response into JSON called `mapJSON()`.
`mapJSON()` takes a single optional parameter (default: true), describing whether it should throw an error when data is empty or simply return `NSNull`.
The error thrown is `MoyaError.jsonMapping(Response)`.

A basic example:

```swift
provider.request(.zen) { result in
    switch result {
    case let .success(moyaResponse):
        do {
            let filteredResponse = try moyaResponse.filterSuccessfulStatusCodes()
            let json = try filteredResponse.mapJSON() // type Any

            // Do something with your json.
        }
        catch let error {
            // Here we get either statusCode error or jsonMapping error.
            // TODO: handle the error == best. comment. ever.
        }
    case let .failure(error):
        // TODO: handle the error == best. comment. ever.
    }
}
```

In `RxSwift`:

```swift
provider.rx.request(.zen)
    .filterSuccessfulStatusCodes()
    .mapJSON()
    .subscribe { event in
        switch event {
        case .success(let json):
            // Notice that now we do not get a Response object anymore but rather the JSON object
            // do something with the json
        case .error(let error):
            // handle the error, which can be an underlying error, a status code error, or an json mapping error
        }
    }
}
```

### Decodable

Moya supports extensions for `Decodable`.
To understand how this works let us first describe the API and our objects.
Let's assume we have an API with an endpoint `/users/:id`, which returns the following data:

```json
{
  "id": "jp",
  "firstName": "James",
  "lastName": "Potter"
}
```

We create a struct to handle this user on the client side:

```swift
struct User: Decodable {
    let id: String
    let firstName: String
    let lastName: String
}
```

Moya allows us to easily get our `User` from the response with the `map<D: Decodable>(_: D.Type, atKeyPath: String?, using: JSONDecoder, failsOnEmptyData: Bool)` extension.
Both `atKeyPath` and `using` are optional, meaning in most cases you'll use `map(_:)`.
The `failsOnEmptyData` property (default: true), describes whether it should throw an error when data is empty or simply return `Decodable` initialized with nil (note: your object must allow optionals or you'll still get thrown an error).
A basic example would be:

```swift
provider.request(.user("jp")) { result in
    switch result {
    case let .success(moyaResponse):
        do {
            let filteredResponse = try moyaResponse.filterSuccessfulStatusCodes()
            let user = try filteredResponse.map(User.self) // user is of type User

            // Do something with your user.
        }
        catch let error {
            // Here we get either statusCode error or objectMapping error.
            // TODO: handle the error == best. comment. ever.
        }
    case let .failure(error):
        // TODO: handle the error == best. comment. ever.
    }
}
```

In `RxSwift`:

```swift
provider.rx.request(.user("jp"))
    .filterSuccessfulStatusCodes()
    .map(User.self)
    .subscribe { event in
        switch event {
        case .success(let user):
            // Notice that now we do not get a Response object anymore but rather the User object
            // do something with the user
        case .error(let error):
            // handle the error, which can be an underlying error, a status code error, or an object mapping error
        }
    }
}
```

The above assumes your object is always at the root and that everything can be handled by the default `JSONDecoder`. 
But if it isn't, then it's not too difficult to change.
To show how this is done we will consider another endpoint in our API: `/users`.
This endpoint returns a list of users under a key called `"users"`.
Futhermore each user now has an `updated` property, which is the unix timestamp.

The data returned looks like this:

```json
{
  "users": [
    {
      "id": "jp",
      "firstName": "James",
      "lastName": "Potter",
      "updated": 1507709925 // Unix timestamp
    },
    {
      "id": "lp",
      "firstName": "Lily",
      "lastName": "Potter",
      "updated": 1507709926 // Unix timestamp
    }
  ]
}
```

Our updated `User` type looks like this:

```swift
struct User: Decodable {
    let id: String
    let firstName: String
    let lastName: String
    let updated: Date
}
```

Our handling of the result now has to do slightly more:

```swift
provider.request(.user) { result in
    switch result {
    case let .success(moyaResponse):
        do {
            let filteredResponse = try moyaResponse.filterSuccessfulStatusCodes()
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .secondsSince1970
            let users = try filteredResponse.map([User].self, atKeyPath: "users", using: decoder) // user is of type [User]

            // Do something with your users.
        }
        catch let error {
            // Here we get either statusCode error or objectMapping error.
            // TODO: handle the error == best. comment. ever.
        }
    case let .failure(error):
        // TODO: handle the error == best. comment. ever.
    }
}
```

In `RxSwift` this could look something like:

```swift
let decoder = JSONDecoder()
decoder.dateDecodingStrategy = .secondsSince1970
provider.rx.request(.users)
    .filterSuccessfulStatusCodes()
    .map([User].self, atKeyPath: "users", using: decoder)
    .subscribe { event in
        switch event {
        case .success(let users):
            // Notice that now we do not get a Response object anymore but rather an array of User objects
            // do something with the user
        case .error(let error):
            // handle the error, which can be an underlying error, a status code error, or an object mapping error
        }
    }
}
```

The above assumes your backend always returns data and if it doesn't, throwns an error.
But if you don't want to receive an error, we can set `failsOnEmptyData` to false.

The data returned looks like this:

```json
{
  "users": []
}
```

Our updated `User` type looks like this:

```swift
struct User: Decodable {
    let id: String?
    let firstName: String?
    let lastName: String?
    let updated: Date?
}
```

Our handling of the result now has to do slightly more:

```swift
provider.request(.user) { result in
    switch result {
    case let .success(moyaResponse):
        do {
            let filteredResponse = try moyaResponse.filterSuccessfulStatusCodes()
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .secondsSince1970
            let users = try filteredResponse.map([User].self, atKeyPath: "users", using: decoder, failsOnEmptyData: false) // user is of type [User]
            // Because the failsOnEmptyData is false and our user object allows optional, our array got initialized with an empty User object
            // Do something with your users.
        }
        catch let error {
            // Here we get either statusCode error or objectMapping error.
            // TODO: handle the error == best. comment. ever.
        }
    case let .failure(error):
        // TODO: handle the error == best. comment. ever.
    }
}
```

In `RxSwift` this could look something like:

```swift
let decoder = JSONDecoder()
decoder.dateDecodingStrategy = .secondsSince1970
provider.rx.request(.users)
    .filterSuccessfulStatusCodes()
    .map([User].self, atKeyPath: "users", using: decoder, failsOnEmptyData: false)
    .subscribe { event in
        switch event {
        case .success(let users):
            // Notice that now we do not get a Response object anymore but rather an array of User objects
            // Because the failsOnEmptyData is false and our user object allows optional, our array got initialized with an empty User object
            // do something with the user
        case .error(let error):
            // handle the error, which can be an underlying error, a status code error, or an object mapping error
        }
    }
}
```