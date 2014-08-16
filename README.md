Moya
================

So the basic idea is that we want some network abstraction layer to satisfy
all of the requirements listed [here](https://github.com/artsy/eidolon/issues/9).
This project has [Alamofire](https://github.com/Alamofire/Alamofire) as a 
submodule, so we'll see where that takes us.

Goals
----------------

I'm thinking some kind of setup at app launch where you provide some information
to this framework (maybe even via plist or something, but for now, in code). 
What you'd provide would be something like "here is a list of the API endpoints 
you support". Each one of the endpoints provided would specify the URL, a
closure for configuring the request (probably abstract that later), and 
importantly, a closure for providing a stubbed response. This stubbed response 
would be used for testing. Stubbed responses, in Moya, are a first-class citizen
that you must provide at startup. 
