# ResonanceKit
ResonanceKit is a very lightweight framework, compared to something like AlamoFire, for async JSON REST requests utilizing the Codable protocols to 
get the model objects from the server. It is pure Swift. It utilizes Coroutines to allow awaiting on main thread or any other thread you like. 

In addition to handing the decoding and encoding requests, it uses Await symantics so that you can make multiple requests as if they are sequential
before returning the final result. This greatly simplifies your code and avoids callback hell. Eventually coroutine support will be built into, likely, 
Swift 6, and will be the way to make concurrent network requests in the future.

## Built in testing mechanism
It provides a injectable mock session that simulates talking to the real server, by putting your requests in a folder structure that mimics the folder 
structure on the real server and returning the same JSON for those requests you can run tests quickly and reliably. 

## Other minor features:
* An extension to UIImageView to allow downloading of images with an in memory LRU Cache. 
* A convineient way of printing out the request so you can easily paste it into `curl` for debugging requests.

# How to use
Simply import using Swift Package manager `https://github.com/possen/ResonanceKit.git` then `import ResonanceKit` and `import SwiftCoroutines` in files
that need to make network requests.

Create a session with your base URL: 

    session = JSONSession(baseURL: "https://mygreatrestservice.com")
   
Setup your decoding strategies: 

    session.keyDecodingStrategy = .convertFromSnakeCase
   
From there just create a request object with the decodable type of the object you need. Then perform your network request where `Person` is `Decodable`:

    let request = JSONRequest<Person, ErrorResponse>(
        method: .get,
        path: "api/people/
        session: session
    )
    return try request.perform(parameters: ["search": filter, "page": String(page)]).await()

The call must be wrapped in the call to `DispatchQueue.main.startCoroutine()` at some point in your request call stack, this can be high up in your
`NetworkController` just so long as it is in the callstack of the request. As mentioned earlier, you don't have to put it on the main thread, but 
it won't block because it utilises CoRoutines. Which are similar to coooperative multithreading. 

# Dependencies
The dependencies are meant to keep it as lightweight as possible and as system support becomes available, I will try to eliminate these.
* SwiftCoroutines - for coroutine support
* SwiftyBeaver - for logging requests. Uses my fork of it to allow bundling as a `Built for Distribution` flag which does not work due to a module namespace issue,
Would use new logging announced at WWDC 2020 but that would limit the use to prerelease software. 
