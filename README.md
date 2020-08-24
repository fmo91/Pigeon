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
- Use the networking library of your choice, being it Alamofire, WS or good ol' URLSession.

All of that working against a very simple interface that uses the very convenient `ObservableObject` Combine protocol.

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
5. `Query` contains a state, that is either: `none` (if it just starts), `loading` (if the fetcher is running), `failed` (which also contains an `Error`), or `succeed` (which also contains the `Response`). `value` is just a convenience property that returns a `Response` in case it exists, or `nil` otherwise.
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

## Example

To run the example project, clone the repo, and run `pod install` from the Example directory first.

## Requirements

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
