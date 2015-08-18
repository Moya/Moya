[![Circle CI](https://circleci.com/gh/Moya/Moya.svg?style=svg)](https://circleci.com/gh/Moya/Moya)

![Moya Logo](web/moya_logo_github.png)

You're a smart developer. You probably use Alamofire to abstract away access to
NSURLSession and all those nasty details you don't really care about. But then,
like lots of smart developers, you write ad hoc network abstraction layers. They
are probably called "APIManager" or "NetworkModel", and probably look something 
like this. 

![Ad hoc network layer](web/bad.png)

It's leaky, meaning your app touches Alamofire directly and your layer bypasses
Alamofire to access the network directly sometimes. 

This kind of ad hoc network layer is common in iOS apps. It's bad for a few reasons:

- It makes it hard to write new apps ("where do I begin?")
- It makes it hard to maintain existing apps ("oh my god, this mess...")
- It makes it hard to write unit tests ("how do I do this again?")

So the basic idea is that we want some network abstraction layer that sufficiently
encapsulates actually calling Alamofire directly. It should be simple enough that
common things are easy, but comprehensive enough that complicated things are also
easy.

![Moya diagram](web/good.png)

Basically:

> If you use Alamofire to abstract away `NSURLSession`, why not use something
to abstract away the nitty gritty of URLs, parameters, etc?

Some awesome features of Moya:

- Compile-time checking for correct API endpoint accesses.
- Lets you define a clear usage of different endpoints with associated enum values.
- Keeps track of inflight requests with ReactiveCocoa and prevents duplicate requests.
- Treats test stubs as first-class citizens so unit testing is super-easy.

Sample Project
--------------

There's a sample project in the Example directory. Go nuts!

Project Status
--------------

This project has hit a 1.0 release, and we're using it in [Artsy's
new auction app](https://github.com/Artsy/eidolon). We consider it
ready for production use. 

Currently, we support Xcode 6.3.1 and Swift 1.2.

Installation
------------

###CocoaPods
Just add `pod 'Moya'` to your Podfile and go!

For reactive extensions, this project has some dependencies. Add the following 
lines to your Podfile:

```rb
pod 'Moya'

# Include the following only if you want to use ReactiveCocoa extensions with Moya
pod 'ReactiveCocoa', '3.0-beta.6'
pod 'Moya/Reactive'
```

Then run `pod install`. 

###Carthage
Add `github "ashfurrow/Moya"` and run `carthage update`.

This will build the reactive extensions by default. If you do not need them, do not add them to your project.

####Using Moya
To use `Moya`, you must add `Moya` and `Alamofire` to your application.

####Using ReactiveMoya
To use `ReactiveMoya`, you must include what's mentioned above, as well as `ReactiveCocoa`, `Result`, and `Box`.

Be sure to add `import ReactiveMoya` wherever you would like to use it.

####Using RxMoya
To use `RxMoya`, you must include what's mentioned in "Using Moya", as well as `RxSwift`.

Be sure to add `import RxMoya` wherever you would like to use it.

Use
---
In any file where you'd like to use `Moya`, don't forget to import the framework with `import Moya`.


After some setup, using Moya is really simple. You can access an API like this:

```swift
provider.request(.Zen) { (data, statusCode, response, error) in
    if let data = data {
        // do something with the data
    }
}
```

That's a basic example. Many API requests need parameters. Moya encodes these
into the enum you use to access the endpoint, like this:

```swift
provider.request(.UserProfile("ashfurrow")) { (data, statusCode, response, error) in
    if let data = data {
        // do something with the data
    }
}
```

No more typos in URLs. No more missing parameter values. No more messing with
parameter encoding.

For more examples, see the [documentation](docs/).

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
contributions, we'll add you as admins to the repo so you can merge pull 
requests :tada:

Please note that this project is released with a Contributor Code of Conduct. By participating in this project you agree to abide by [its terms](https://github.com/Moya/code-of-conduct).

License
-------

Moya is released under an MIT license. See LICENSE for more information.
