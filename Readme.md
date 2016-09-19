[![CircleCI](https://circleci.com/gh/Moya/Moya.svg?style=svg)](https://circleci.com/gh/Moya/Moya) [![codecov.io](https://codecov.io/github/Moya/Moya/coverage.svg?branch=master)](https://codecov.io/github/Moya/Moya?branch=master)
[![Carthage compatible](https://img.shields.io/badge/Carthage-compatible-4BC51D.svg?style=flat)](https://github.com/Carthage/Carthage)

<p align="center">
  <img height="160" src="web/logo_github.png" />
</p>

You're a smart developer. You probably use [Alamofire](https://github.com/Alamofire/Alamofire) to abstract away access to
NSURLSession and all those nasty details you don't really care about. But then,
like lots of smart developers, you write ad hoc network abstraction layers. They
are probably called "APIManager" or "NetworkModel", and they always end in tears.

![Moya Overview](web/diagram.png)

Ad hoc network layers are common in iOS apps. They're bad for a few reasons:

- Makes it hard to write new apps ("where do I begin?")
- Makes it hard to maintain existing apps ("oh my god, this mess...")
- Makes it hard to write unit tests ("how do I do this again?")

So the basic idea of Moya is that we want some network abstraction layer that
sufficiently encapsulates actually calling Alamofire directly. It should be simple
enough that common things are easy, but comprehensive enough that complicated things
are also easy.

> If you use Alamofire to abstract away `NSURLSession`, why not use something
to abstract away the nitty gritty of URLs, parameters, etc?

Some awesome features of Moya:

- Compile-time checking for correct API endpoint accesses.
- Lets you define a clear usage of different endpoints with associated enum values.
- Treats test stubs as first-class citizens so unit testing is super-easy.

Sample Project
--------------

There's a sample project in the Demo directory. To use it, run `pod install` to download the required libraries. Have fun!

Project Status
--------------

This project is actively under development, and is being used in [Artsy's
new auction app](https://github.com/Artsy/eidolon). We consider it
ready for production use.

Currently, we support Xcode 7 and Swift 2.

Installation
------------

### CocoaPods

For Moya, us the following entry in your Podfile:

```rb
pod 'Moya', '8.0.0-beta.1'
```

In any file you'd like to use Moya in, don't forget to
import the framework with `import Moya`.

For RxSwift or ReactiveCocoa extensions, this project will include
them as dependencies. You can do this via CocoaPods subspecs, but you will also
need to include the pre-release versions of RxSwift or ReactiveSwift manually.

```rb
pod 'Moya/RxSwift'
pod 'RxSwift', '3.0.0-beta.1'
pod 'RxCocoa', '3.0.0-beta.1'

# or

pod 'Moya/ReactiveCocoa'
pod 'ReactiveSwift', :podspec => 'https://raw.githubusercontent.com/ashfurrow/ReactiveSwift/ea5a7f9c7e31adf262be14173a80709c15d25300/ReactiveSwift.podspec'
```

Then run `pod install`.

### Carthage
Carthage users can point to this repository and use whichever
generated framework they'd like, `Moya`, `RxMoya`, or `ReactiveMoya`.
The full Moya framework is bundled in each of those frameworks;
importing more than one framework in a single file will result in
ambiguous lookups at compile time.

```
github "Moya/Moya"
```

Usage
---

After [some setup](docs/Examples/Basic.md), using Moya is really simple. You can access an API like this:

```swift
provider = MoyaProvider<GitHub>()
provider.request(.Zen) { result in
    switch result {
    case let .Success(moyaResponse):
        let data = moyaResponse.data
        let statusCode = moyaResponse.statusCode
        // do something with the response data or statusCode
    case let .Failure(error):
        // this means there was a network failure - either the request
        // wasn't sent (connectivity), or no response was received (server
        // timed out).  If the server responds with a 4xx or 5xx error, that
        // will be sent as a ".Success"-ful response.
    }
}
```

That's a basic example. Many API requests need parameters. Moya encodes these
into the enum you use to access the endpoint, like this:

```swift
provider = MoyaProvider<GitHub>()
provider.request(.UserProfile("ashfurrow")) { result in
    // do something with the result
}
```

No more typos in URLs. No more missing parameter values. No more messing with
parameter encoding.

For more examples, see the [documentation](docs/Examples).

Reactive Extensions
-------------------

Even cooler are the reactive extensions. Moya provides reactive extensions for
[ReactiveCocoa](https://github.com/ReactiveCocoa/ReactiveCocoa) and
[RxSwift](https://github.com/ReactiveX/RxSwift).

## ReactiveCocoa

After `ReactiveCocoa` [setup](docs/ReactiveCocoa.md), `request(:)` method
immediately returns a `SignalProducer` (`RACSignal` is also available if needed)
that you can start or bind or map or whatever you want to do. To handle errors,
for instance, we could do the following:

```swift
provider = ReactiveCocoaMoyaProvider<GitHub>()
provider.request(.UserProfile("ashfurrow")).start { event in
    switch event {
    case .Next(let response):
        image = UIImage(data: response.data)
    case .Failed(let error):
        print(error)
    default:
      break
    }
}
```

## RxSwift

After `RxSwift` [setup](docs/RxSwift.md), `request(:)` method immediately
returns an `Observable` that you can subscribe to or bind or map or whatever you
want to do. To handle errors, for instance, we could do the following:

```swift
provider = RxMoyaProvider<GitHub>()
provider.request(.UserProfile("ashfurrow")).subscribe { event in
    switch event {
    case .Next(let response):
        image = UIImage(data: response.data)
    case .Error(let error):
        print(error)
    default:
        break
    }
}
```

---

In addition to the option of using signals instead of callback blocks, there are
also a series of signal operators for RxSwift and ReactiveCocoa that will attempt
to map the data received from the network response into either an image, some JSON,
or a string, with `mapImage()`, `mapJSON()`, and `mapString()`, respectively. If the mapping is unsuccessful, you'll get an error on the signal. You also get handy methods
for filtering out certain status codes. This means that you can place your code for
handling API errors like 400's in the same places as code for handling invalid
responses.

Community Extensions
--------------------

Moya has a great community around it and some people have created some very helpful extensions.

- [Moya-ObjectMapper](https://github.com/ivanbruel/Moya-ObjectMapper) - ObjectMapper bindings for Moya for easier JSON serialization
- [Moya-SwiftyJSONMapper](https://github.com/AvdLee/Moya-SwiftyJSONMapper) - SwiftyJSON bindings for Moya for easier JSON serialization
- [Moya-Argo](https://github.com/wattson12/Moya-Argo) - Argo bindings for Moya for easier JSON serialization
- [Moya-ModelMapper](https://github.com/sunshinejr/Moya-ModelMapper) - ModelMapper bindings for Moya for easier JSON serialization
- [Moya-Gloss](https://github.com/spxrogers/Moya-Gloss) - Gloss bindings for Moya for easier JSON serialization
- [Moya-JASON](https://github.com/DroidsOnRoids/Moya-JASON) - JASON bindings for Moya for easier JSON serialization
- [Moya-Unbox](https://github.com/RyogaK/Moya-Unbox) - Unbox bindings for Moya for easier JSON serialization

We appreciate all the work being done by the community around Moya. If you would like to have your extension featured in the list above, simply create a pull request adding your extensions to the list.

Contributing
------------

Hey! Like Moya? Awesome! We could actually really use your help!

Open source isn't just writing code. Moya could use your help with any of the
following:

- Finding (and reporting!) bugs.
- New feature suggestions.
- Answering questions on issues.
- Documentation improvements.
- Reviewing pull requests.
- Helping to manage issue priorities.
- Fixing bugs/new features.

If any of that sounds cool to you, send a pull request! After a few
contributions, we'll add you as an admin to the repo so you can merge pull
requests and help steer the ship :ship: You can read more details about that [in our contributor guidelines](https://github.com/Moya/contributors).

Moya's community has a tremendous positive energy, and the maintainers are committed to keeping things awesome. Like [in the CocoaPods community](https://github.com/CocoaPods/CocoaPods/wiki/Communication-&-Design-Rules), always assume positive intent; even if a comment sounds mean-spirited, give the person the benefit of the doubt.

Please note that this project is released with a Contributor Code of Conduct. By participating in this project you agree to abide by [its terms](https://github.com/Moya/contributors/blob/master/Code of Conduct.md).
 
### Adding new source files
 
If you add or remove a source file from Moya, a corresponding change needs to be made to the `Moya.xcodeproj` project at the root of this repository. This project is used for Carthage. Don't worry, you'll get an automated warning when submitting a pull request if you forget. 

License
-------

Moya is released under an MIT license. See LICENSE for more information.
