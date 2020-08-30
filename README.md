# Pigeon 🐦

[![CI Status](https://img.shields.io/travis/fmo91/Pigeon.svg?style=flat)](https://travis-ci.org/fmo91/Pigeon)
[![Version](https://img.shields.io/cocoapods/v/Pigeon.svg?style=flat)](https://cocoapods.org/pods/Pigeon)
[![License](https://img.shields.io/cocoapods/l/Pigeon.svg?style=flat)](https://cocoapods.org/pods/Pigeon)
[![Platform](https://img.shields.io/cocoapods/p/Pigeon.svg?style=flat)](https://cocoapods.org/pods/Pigeon)

## Introduction

Pigeon is a SwiftUI and UIKit library that relies on Combine to deal with asynchronous data. It is heavily inspired by [React Query](https://react-query.tanstack.com/).

## In a nutshell

With Pigeon you can:

- Fetch server side APIs.
- Cache server responses using interchangeable and configurable cache providers.
- Share server data among different, unconnected components in your app.
- Mutate server side resources.
- Invalidate cache and refetch data.
- Manage paginated data sources
- Pigeon is agnostic on what you use for fetching data.

All of that working against a very simple interface that uses the very convenient `ObservableObject` Combine protocol.

## What is Pigeon?

Pigeon is all about Queries and Mutations. Queries are objects that are responsible of fetching server data, and Mutations are objects that are responsible of modifying server data. Both Queries and Mutations are `ObservableObject` conforming, meaning both of them are fully compatible with SwiftUI and that their states are observable.

Queries are identified by a `QueryKey`. Pigeon uses `QueryKey` objects to cache query results, link them internally and invalidate queries when they need to be refetched.

A very important thing in Pigeon is that you can use whatever you want to fetch data from wherever you need. Pigeon don't force you to use `Alamofire` or `URLSession` or `GraphQL` or even `CoreData`. You can fetch the data from where you need using the most appropriate tool. The only thing you need to use is `Combine` publishers.

The last thing I want to note and then we can go straight to code. Pigeon can optionally cache your responses: you can let Pigeon store the responses for your fetches and it will populate your app with data with almost zero-config.

## Quick Start

In the core of Pigeon is the `Query` ObservableObject. Let's explore the 'hello world' of Pigeon:

```swift
// 1
struct User: Codable, Identifiable {
    let id: Int
    let name: String
}

struct UsersList: View {
    // 2
    @ObservedObject var users = Query<Void, [User]>(
        // 3    
        key: QueryKey(value: "users"),
        // 4
        fetcher: {
            URLSession.shared
                .dataTaskPublisher(for: URL(string: "https://jsonplaceholder.typicode.com/users")!)
                .map(\.data)
                .decode(type: [User].self, decoder: JSONDecoder())
                .receive(on: DispatchQueue.main)
                .eraseToAnyPublisher()
        }
    )
    
    var body: some View {
        // 5
        List(users.state.value ?? []) { user in
            Text(user.name)
        }.onAppear(perform: {
            // 6
            self.users.refetch(request: ())
        })
    }
}
```

1. We start by defining a `Codable` structure that will store our server side data. This is not related to `Pigeon` itself, but is still needed for our example to work.
2. We define a `Query` that will store our array of `User`. `Query` takes two generic parameters: `Request` (`Void` in this example, since the fetch action won't receive any parameters) and `Response` which is the type of our data (`[User]` in this example).
3. Data is cached by default in Pigeon. The `QueryKey` is a simple wrapper around the `String` that identifies our piece of state.
4. `Query` also receives a `fetcher`, which is a function that we have to define. `fetcher` takes the `Request` and returns a Combine `Publisher` holding the `Response`. Note that we can put whatever custom login in the `fetcher`. In this case, we use `URLSession` to get an array of `User` from an API.
5. `Query` contains a state, that is either: `idle` (if it just starts), `loading` (if the fetcher is running), `failed` (which also contains an `Error`), or `succeed` (which also contains the `Response`). `value` is just a convenience property that returns a `Response` in case it exists, or `nil` otherwise.

```swift
// ...
    var body: some View {
        // 5
        switch users.state {
            case .idle, .loading:
                return AnyView(Text("Loading..."))
            case .failed:
                return AnyView(Text("Oops..."))
            case let .succeed(users):
                return AnyView(
                    List(users) { user in
                        Text(user.name)
                    }
                )
        }
    }
// ...
```

**Note: If you find this ugly, then you might be interested in `QueryRenderer`. Keep scrolling!**

6. In this example, we are firing our `Query` manually, using `refetch`. However, we can also configure our `Query` so it fires immediately like this:

```swift
struct UsersList: View {
    @ObservedObject var users = Query<Void, [User]>(
        key: QueryKey(value: "users"),
        // Changing the query behavior, we can tell the query to 
        // start fetching as soon as it initializes. 
        behavior: .startImmediately(()),
        fetcher: {
            URLSession.shared
                .dataTaskPublisher(for: URL(string: "https://jsonplaceholder.typicode.com/users")!)
                .map(\.data)
                .decode(type: [User].self, decoder: JSONDecoder())
                .receive(on: DispatchQueue.main)
                .eraseToAnyPublisher()
        }
    )
    
    var body: some View {
        List(users.state.value ?? []) { user in
            Text(user.name)
        }
    }
}
```

## Queries and Query Consumers

In addition to Queries, Pigeon has another type, `Consumer` that doesn't provide any kind of fetching capability, but just provides the capability to consume, and react to changes in Queries with the same `QueryKey` that it subscribes to. Please note that the `Query` dependency injection is done internally, and that the state is not duplicated.

```swift
struct ContentView: View {
    @ObservedObject var users = Query<Void, [User]>(
        key: QueryKey(value: "users"),
        behavior: .startImmediately(()),
        fetcher: {
            URLSession.shared
                .dataTaskPublisher(for: URL(string: "https://jsonplaceholder.typicode.com/users/")!)
                .map(\.data)
                .decode(type: [User].self, decoder: JSONDecoder())
                .receive(on: DispatchQueue.main)
                .eraseToAnyPublisher()
        }
    )
    
    var body: some View {
        UsersList()
    }
}

struct UsersList: View {
    @ObservedObject var users = Query<Void, [User]>.Consumer(key: QueryKey(value: "users"))
    
    var body: some View {
        List(users.state.value ?? []) { user in
            Text(user.name)
        }
    }
}

struct User: Codable, Identifiable {
    let id: Int
    let name: String
}
```

## Polling

Pigeon provides a way to fetching data using the fetcher every N seconds. That's achieved with the `pollingBehavior` property in the `Query` class. Default is `.noPolling`. Let's see an example:

```swift
@ObservedObject var users = Query<Void, [User]>(
    key: QueryKey(value: "users"),
    behavior: .startImmediately(()),
    pollingBehavior: .pollEvery(2),
    fetcher: {
        URLSession.shared
            .dataTaskPublisher(for: URL(string: "https://jsonplaceholder.typicode.com/users")!)
            .map(\.data)
            .decode(type: [User].self, decoder: JSONDecoder())
            .receive(on: DispatchQueue.main)
            .eraseToAnyPublisher()
    }
)
```

That query will trigger its fetcher every 2 seconds.

## Mutations

In addition to allow queries, Pigeon also provides a way to mutate server data, and force to refetch affected queries.

```swift
@ObservedObject var sampleMutation = Mutation<Int, User> { (number) -> AnyPublisher<User, Error> in
    Just(User(id: number, name: "Pepe"))
        .tryMap({ $0 })
        .eraseToAnyPublisher()
}

// ...

sampleMutation.execute(with: 10) { (user: User, invalidate) in
    // Invalidate triggers a new query on the "users" key
    invalidate(QueryKey(value: "users"), .lastData)
}
```

## Convenient keys

You can also define more convenient keys by extending `QueryKey` like this:

```swift
extension QueryKey {
    static let users: QueryKey = QueryKey(value: "users")
}
```

So then you can use it like this:

```swift
struct UsersList: View {
    @ObservedObject var users = QueryConsumer<[User]>(key: .users)
    
    var body: some View {
        List(users.state.value ?? []) { user in
            Text(user.name)
        }
    }
}
```

## Paginated Queries

A very frequent scenario when fetching server data is pagination. Pigeon provides a special type of `Query` for this use case: `PaginatedQuery`. `PaginatedQuery` is generic on three types:

- **Request**: The type that is required in order to perform the fetch 
- **PageIdentifier**: a `PaginatedQueryKey` conforming type, that identifies the current page. By default, Pigeon provides two `PaginatedQueryKey` alternatives: `NumericPaginatedQueryKey` (page 1, page 2, ...) and `LimitOffsetPaginatedQueryKey` (limit: 20, offset: 40, for instance). If these don't match your needs, then you can create a new type that implements `PaginatedQueryKey` and customize its behavior.
- **Response**: The response type. This type needs to conform `Sequence` in order to be suitable for use in `PaginatedQuery`.

Let's jump on an example:

```swift
@ObservedObject private var users = PaginatedQuery<Void, LimitOffsetPaginatedQueryKey, [User]>(
    key: QueryKey(value: "users"),
    firstPage: LimitOffsetPaginatedQueryKey(
        limit: 20,
        offset: 0
    ),
    fetcher: { (request, page) in
        // ...
    }
)
```

This is an example of a `PaginatedQuery`. There are a couple of important things to note here:

- `key` works in the exact same way as in the regular `Query` type.
- `firstPage` should receive the first possible page for your fetcher.
- `fetcher` works exactly the same way as in `Query` BUT it also receives the page to be fetched.

On top of all the functionality that `Query `provides, `PaginatedQuery` allow you a couple of more things:

```swift
// If you want to fetch the next page.
users.fetchNextPage()

// If you need to fetch the first page again (this will reset the current state for your query)
users.refetch(request /* some Request */)
```

**An important thing to note is that `PaginatedQuery` can not be cached at this moment.**

## Dependency on Codable

An important restriction in Pigeon `Query` type is that the `Response` must be `Codable`. That is because of the cachable nature of server side data. Data can be cached, and in order to be cached, we need it to be `Codable`.

## Cache

Cache is deeply integrated into Pigeon mechanics. All data in Pigeon `Query` objects can be cached since it's codable, and then used for state rehydration in the next app startup.

Let's see an example: 

```swift
@ObservedObject private var cards = PaginatedQuery<Void, NumericPaginatedQueryKey, [Card]>(
    key: QueryKey(value: "cards"),
    firstPage: NumericPaginatedQueryKey(current: 0),
    behavior: .startImmediately(()),
    cache: UserDefaultsQueryCache.shared,
    cacheConfig: QueryCacheConfig(
        invalidationPolicy: .expiresAfter(1000),
        usagePolicy: .useInsteadOfFetching
    ),
    fetcher: { request, page in
        print("Fetching page no. \(page)")
        return GetCardsRequest()
            .execute()
            .map(\.cards)
            .eraseToAnyPublisher()
    }
)
```

This is from the Example folder in this project. If you see in the `cacheConfig`:

```swift
cacheConfig: QueryCacheConfig(
    invalidationPolicy: .expiresAfter(1000),
    usagePolicy: .useInsteadOfFetching
),
```

It's almost self-explanatory: Pigeon will use the cache if possible and if its data is valid, instead of fetching. And the data will be considered valid until 1000 seconds from saved.

Pigeon provides two invalidation policies:

```swift
public enum InvalidationPolicy {
    case notExpires
    case expiresAfter(TimeInterval)
}
```

and three usage policies: 

```swift
public enum UsagePolicy {
    case useInsteadOfFetching
    case useIfFetchFails
    case useAndThenFetch
}
```

Right now, two cache providers are included in the project: `InMemoryQueryCache` and `UserDefaultsQueryCache`, but you can create your own cache by implementing `QueryCacheType`  in a custom type.

## Query Renderers

If you saw the state rendering in the Quick Start section:

```swift
// ...
    var body: some View {
        // 5
        switch users.state {
            case .idle, .loading:
                return AnyView(Text("Loading..."))
            case .failed:
                return AnyView(Text("Oops..."))
            case let .succeed(users):
                return AnyView(
                    List(users) { user in
                        Text(user.name)
                    }
                )
        }
    }
// ...
```

Then you probably felt it could have been done in a much better way. What is all that `AnyView` thing? Weird... 

Well, Pigeon provides an alternative way to do this: `QueryRenderer`. It's a protocol with three requirements:

```swift
// When Query is in loading state
var loadingView: some View { get }

// When Query is in succeed state
func successView(for response: Response) -> some View

// When Query is in failure state
func failureView(for failure: Error) -> some View
```

In exchange of that, `QueryRenderer` provides a method for rendering a `QueryState`. Let's see a full example:

```swift
struct UsersList: View {
    @ObservedObject private var users = Query<Void, [User]>(
        key: QueryKey(value: "users"),
        behavior: .startImmediately(()),
        fetcher: {
            URLSession.shared
                .dataTaskPublisher(for: URL(string: "https://jsonplaceholder.typicode.com/users/")!)
                .map(\.data)
                .decode(type: [User].self, decoder: JSONDecoder())
                .receive(on: DispatchQueue.main)
                .eraseToAnyPublisher()
        }
    )
    
    var body: some View {
        self.view(for: users.state)
    }
}

extension UsersList: QueryRenderer {
    var loadingView: some View {
        Text("Loading...")
    }
    
    func successView(for response: [User]) -> some View {
        List(response) { user in
            Text(user.name)
        }
    }
    
    func failureView(for failure: Error) -> some View {
        Text("It failed...")
    }
}

struct User: Codable, Identifiable {
    let id: Int
    let name: String
}
```

## Global defaults

You can change `QueryCacheType` and `QueryCacheConfig` global data by calling to `setGlobal` on either type.

## Example

To run the example project, clone the repo, and run `pod install` from the Example directory first.

## Requirements

Pigeon works with SwiftUI and UIKit as well. As it has a dependency in Combine, it required a minimum iOS version of 13.0.

## Installation

Pigeon is available through [CocoaPods](https://cocoapods.org). To install
it, simply add the following line to your Podfile:

```ruby
pod 'Pigeon'
```

## Author

fmo91, ortizfernandomartin@gmail.com

## License

Pigeon is available under the MIT license. See the LICENSE file for more info.
