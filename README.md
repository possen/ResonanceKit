# ResonanceKit
ResonanceKit is a very lightweight framework, compared to something like AlamoFire, for async JSON REST requests utilizing the `Codable` protocols to 
get the model objects from the server. It is pure Swift. It utilizes Coroutines to allow awaiting on main thread or any other thread you like. 

In addition to handing the decoding and encoding requests, it uses Await symantics so that you can make multiple requests as if they are sequential
before returning the final result. This greatly simplifies your code and avoids callback hell. Eventually coroutine support will be built into, likely, 
Swift 6, and will be the way to make concurrent network requests in the future.

## Built in testing mock server
It provides a injectable mock session that simulates talking to the real server, by putting your requests in a folder structure that mimics the folder 
structure on the real server and returning the same `JSON` for those requests you can run tests quickly and reliably.

## Other minor features:
* An extension to `UIImageView` to allow downloading of images with an in memory `LRU` Cache. 
* A convineient way of printing out the request so you can easily paste it into `curl` for debugging requests.

# How to use
Simply import using Swift Package Manager `https://github.com/possen/ResonanceKit.git` then `import ResonanceKit` and `import SwiftCoroutines` in files
that need to make network requests.

Create a session with your base URL: 

    session = JSONSession(baseURL: "https://MyGreatRestService.com")
   
Setup your decoding strategies: 

    session.keyDecodingStrategy = .convertFromSnakeCase
    
Similar properties exist for encoding an object to send to the request body. 
   
From there just create a request object with the decodable type of the object you need. Then perform your network request where `Person` is `Decodable`:

    let request = JSONRequest<People, ErrorResponse>(
        method: .get,
        path: "api/1.0/people/
        session: session
    )
    return try request.perform(parameters: ["search": filter, "page": String(page)]).await()

The call must be wrapped in the call to `DispatchQueue.main.startCoroutine()` at some point in your request call stack, this can be high up in your
`NetworkController` just so long as it is in the callstack of the request. As mentioned earlier, you don't have to put it on the main thread, but 
it won't block because it utilises CoRoutines. Which are similar to coooperative multithreading. 

### Example Person Model Object:

    struct People: Decodable {
        var count: Int
        let next: URL?
        var results: [Person]
    }

    struct Person: Decodable, CustomStringConvertible, Hashable {

        var description: String {
            return name
        }

        let name: String
        let birthYear: String
        let eyeColor: String
        let height: String
        let mass: String
        let skinColor: String
        let homeworld: URL
        let films: [URL]
        let species: [URL]
        let starships: [URL]
        let vehicles: [URL]
        let created: Date
        let edited: Date
        let url: URL
    }

## To use Testing 

Each file in that folder structure is a JSON
file which has the following structure which is an array so you can have multiple responses in the same file:

* A `request` section to validate the matching of the request:
* A `status` section to simulate the different response codes
* A `method` section to match the type of request
* A `response` section which is the JSON response as if it were coming back from real server

### Example Mock Response put in folder Mocks/People.json:

        [{
            "request": {},
            "status": 200,
            "method": "GET",
            "response": {
                "count": 82,
                "next": "http://swapi.dev/api/people/?page=2",
                "previous": null,
                "results": [
                    {
                        "birth_year": "19BBY",
                        "created": "2014-12-09T13:50:51.644000Z",
                        "edited": "2014-12-20T21:17:56.891000Z",
                        "eye_color": "blue",
                        "films": [
                            "http://swapi.dev/api/films/1/",
                            "http://swapi.dev/api/films/2/",
                            "http://swapi.dev/api/films/3/",
                            "http://swapi.dev/api/films/6/"
                        ],
                        "gender": "male",
                        "hair_color": "blond",
                        "height": "172",
                        "homeworld": "http://swapi.dev/api/planets/1/",
                        "mass": "77",
                        "name": "Luke Skywalker",
                        "skin_color": "fair",
                        "species": [],
                        "starships": [
                            "http://swapi.dev/api/starships/12/",
                            "http://swapi.dev/api/starships/22/"
                        ],
                        "url": "http://swapi.dev/api/people/1/",
                        "vehicles": [
                            "http://swapi.dev/api/vehicles/14/",
                            "http://swapi.dev/api/vehicles/30/"
                        ]
                    },
                    {
                        "birth_year": "112BBY",
                        "created": "2014-12-10T15:10:51.357000Z",
                        "edited": "2014-12-20T21:17:50.309000Z",
                        "eye_color": "yellow",
                        "films": [
                            "http://swapi.dev/api/films/1/",
                            "http://swapi.dev/api/films/2/",
                            "http://swapi.dev/api/films/3/",
                            "http://swapi.dev/api/films/4/",
                            "http://swapi.dev/api/films/5/",
                            "http://swapi.dev/api/films/6/"
                        ],
                        "gender": "n/a",
                        "hair_color": "n/a",
                        "height": "167",
                        "homeworld": "http://swapi.dev/api/planets/1/",
                        "mass": "75",
                        "name": "C-3PO",
                        "skin_color": "gold",
                        "species": [
                            "http://swapi.dev/api/species/2/"
                        ],
                        "starships": [],
                        "url": "http://swapi.dev/api/people/2/",
                        "vehicles": []
                    },

                ]
            }
        }
        ]

# Dependencies
The dependencies are meant to keep it as lightweight as possible and as system support becomes available, I will try to eliminate these.
* SwiftCoroutines - for coroutine support really nice package for doing await and coroutine support. 
* SwiftyBeaver - for logging requests. Uses my fork of it to allow bundling as a `Built for Distribution` flag which does not work due to a module namespace issue,
Would use new logging announced at WWDC 2020 but that would limit the use to prerelease software. 
