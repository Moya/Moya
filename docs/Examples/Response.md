# Response Handling

You've now setup your TargetType correctly, and you've come to the fun part of implementing calls to your API.
But one thing is not quite clear: How do you actually use the response from the `MoyaProvider`?

A very basic example is:

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

## Decodable

This is all good, but how do we actually use this to map to our own objects?

Swift 4 introduces `Decodable`, meaning now our objects can easily be decoded from JSON.
But how do we actually do that?

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

Now, how do we get our response mapped to our `User` type?
Luckily Moya provides several nice extensions to the `Response` object.
One of which is `map(_:, atKeyPath:, using:)`.

An basic example usage would then be:

```swift
provider.request(.user('jp')) { result in
    switch result {
    case let .success(moyaResponse):
        let filteredResponse = moyaResponse.filterSuccessfulStatusCodes() // We want the status code to be within 200...299
        let user = filteredResponse.map(User.self) // The user object is automatically decoded using a default decoder

        // do something in your app
    case let .failure(error):
        // TODO: handle the error == best. comment. ever.
    }
}
```

What if we had an endpoint `/users` that returned a list of users, and each user now had an `updated` property as well?
Let's first look at the data returned:

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

We also update our `User` type:

```swift
struct User: Decodable {
    let id: String
    let firstName: String
    let lastName: String
    let updated: Date
}
```

Now our example has slightly more going on:

```swift
provider.request(.user) { result in
    switch result {
    case let .success(moyaResponse):
        let filteredResponse = moyaResponse.filterSuccessfulStatusCodes() // We want the status code to be within 200...299
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .secondsSince1970
        let users = filteredResponse.map([User].self, atKeyPath: "list", using: decoder)

        // do something in your app
    case let .failure(error):
        // TODO: handle the error == best. comment. ever.
    }
}
```
