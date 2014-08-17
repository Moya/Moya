Moya
================

So the basic idea is that we want some network abstraction layer to satisfy
all of the requirements listed [here](https://github.com/artsy/eidolon/issues/9).
Mainly:

- Treat test stubs as first-class citizens.
- Only allow endpoints clearly defined through Moya can be access through Moya,
enforced by the compiler.
- Allow iterating through all potential API requests at runtime for API sanity 
checks.
- Keep track of inflight requests and don't support duplicates.

Super-cool. We actually go a bit farther than other network libraries by 
abstracting the API endpoints away, too. Instead of dealing with endpoints 
(URLS) directly, we use *targets*, which represent actions to be take on the 
API. This is beneficial if one action can hit different endpoints; for example,
if you want to GET a user profile, but the endpoint differs depending on if that
user is a friend or not. Hey – I don't write these APIs, I just use 'em.

Project Status
----------------

This is still pretty early in its development, though it works now. There are 
plenty of [issues](https://github.com/AshFurrow/Moya/issues) open, which should 
give you an idea of our roadmap. If you have any suggestions on any of them, 
please do feel free to leave a comment. 

Setup
----------------

This project has [Alamofire](https://github.com/Alamofire/Alamofire), [swfitz](https://github.com/maxpow4h/swiftz) 
and the  `swift-development` branch of [ReactiveCocoa](https://github.com/reactivecocoa/reactivecocoa/tree/swift-development)
as dependencies. If you want to use this library, just grab those repos and 
integrate them into your project. Then drag and drop the `Moya.swift` and 
`Endpoint.swift` files, and you're set. 

If that doesn't work for some reason, or you want to get the full monty to run
the library's test and contribute back, clone this repo and set up the 
submodules.

```sh
git clone git@github.com:AshFurrow/Moya.git
cd Moya
git submodule init
git submodule update
```

ReactiveCocoa requires its setup script to be run. 

```sh
./submodules/ReactiveCocoa/script/bootstrap 
```

Use
----------------

So how do you use this library? Well, it's easy. First, set up an `enum` with 
all of your targets. The `enum` will need a base type that conforms to the
`Hashable` protocol – `Int`s work best. 

```swift
enum Target: Int {
	case MediumImage = 0
	case 	
}
```

This enum is used to make sure that you provide implementation details for each
target (at compile time).

Next, we'll set up the endpoints for use with our API. 

```swift
let endpointsClosure = { (target: Target, method: Moya.Method, parameters: [String: AnyObject]) -> Endpoint<Target> in
    switch target {
    case .MediumImage:
        return Endpoint(URL: "http://rdjpg.com/300/200/", sampleResponse: {
            return sampleData
        })
    case .LargeImage:
        return Endpoint(URL: "http://rdjpg.com/500/600/", sampleResponse: {
            return otherSampleData
        })
    }
}
```

The block you provide will be invoked every time an API call is to be made. Its
responsibility is to return an `Endpoint` instance configured for use by Moya. 
The `parameters` parameter is passed into this block to allow you to configure
the `Endpoint` instance – these parameters are *not* automatically passed onto
the network request, so add them to the `Endpoint` if they should be. 

Notice that returning sample data is *required*. One of the key benefits of Moya
is that it makes testing the app or running the app, using stubbed responses for
API calls, really easy. 

Great, now we're all set. Just need to create our provider. 

```swift
// Tuck this away somewhere where it'll be visible to anyone who wants to use it
var provider: MoyaProvider<Target>!

// Create this instance at app launch
let provider = MoyaProvider(endpointsClosure: endpointsClosure)
```

Neato. Now how do we make a request?

```swift
provider.request(.LargeImage).subscribeNext({ (object: AnyObject!) -> Void in
    image = UIImage(data: object as? NSData)
})
```

The `request` method is given a `Target` value and, optionally, an HTTP method 
and parameters for the endpoint closure. It immediately returns a `RACSignal` 
that you can subscribe to our bind or map or whatever you want to do. To handle
errors, for instance, we could do the following:

```swift
provider.request(.LargeImage).subscribeNext({ (object: AnyObject!) -> Void in
        image = UIImage(data: object as? NSData)
    }, error: { (error: NSError!) -> Void in
        println(error)
    })
```

License
----------------

Copyright (c) Ash Furrow, 2014

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in
all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
THE SOFTWARE.
