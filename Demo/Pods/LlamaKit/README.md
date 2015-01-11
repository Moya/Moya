LlamaKit
========

Collection of must-have functional tools. Trying to be as lightweight as possible, hopefully providing a simple foundation that
more advanced systems can build on. LlamaKit is very Cocoa-focused. It is designed to work with common Cocoa paradigms, use names
that are understandable to Cocoa devs, integrate with Cocoa tools like GCD, and in general strive for a low-to-modest learning
curve for devs familiar with ObjC and Swift rather than Haskell and ML. There are more functionally beautiful toolkits out there
(see [Swiftz](https://github.com/maxpow4h/swiftz) and [Swift-Extras](https://github.com/CodaFi/Swift-Extras) for some nice
examples). LlamaKit intentionally is much less full-featured, and is focused only on things that come up commonly in Cocoa
development. (Within those restrictions, it hopes to be based as much as possible on the lessons of other FP languages, and I
welcome input from folks with deeper FP experience.)

Currently has a `Result` object, which is the most critical. (And in the end, it may be the *only* thing in the main module.)
`Result` is mostly done except for documentation (in progress). Tests are built.

`Future` is in progress. It's heavily inspired by [Scala's approach](http://docs.scala-lang.org/overviews/core/futures.html),
though there are some small differences. I haven't decided if a `Promise` ISA `Future` or HASA `Future`. The Scala approach
is a weird hybrid. It technically HASA `Future`, but in the main implementation, the `Promise` is its own `Future`, so it's
kind of ISA, too. Still a work in progress there. I'm considering pulling `Future` out; it already makes this module too
complicated (did I mention that LlamaKit wants to be really, really simple?)

LlamaKit should be considered highly experimental, pre-alpha, in development, I promise I will break you.

But the `Result` object is kind of nice already if you want to go ahead and use it. :D
