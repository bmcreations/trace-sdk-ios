# Trace SDK for iOS

The official iOS SDK for [Trace](https://clicktrace.io) — lightweight install attribution and deferred deep links.

## Installation

Add the package to your Xcode project via Swift Package Manager:

```
https://github.com/bmcreations/trace-sdk-ios
```

Or add it to your `Package.swift`:

```swift
dependencies: [
    .package(url: "https://github.com/bmcreations/trace-sdk-ios", from: "0.5.4")
]
```

**Requirements:** iOS 16+, Swift 5.9+

## Quick Start

```swift
import TraceSDK

@main
struct MyApp: App {
    init() {
        TraceClient.initialize(config: TraceClientConfig(
            apiKey: "tr_live_xxx",
            hashSalt: "your_hash_salt"
        ))
    }

    var body: some Scene {
        WindowGroup {
            TraceProvider {
                ContentView()
            }
        }
    }
}
```

## Features

- **Install attribution** — automatic first-open attribution via install referrer, click ID, and probabilistic fingerprinting
- **Deferred deep links** — capture intent at click time, deliver on first app open
- **SwiftUI integration** — `TraceProvider`, `TraceRouteMapper`, and `.onDeepLink()` view modifier
- **Type-safe routing** — map deep link paths to your app's route types with pattern matching
- **Event tracking** — post-install event reporting
- **SKAdNetwork** — conversion value updates
- **Privacy controls** — opt-out support for GDPR/ATT compliance
- **Test mode** — `.test()` config for development without an API key

## Deep Link Routing

```swift
TraceRouteMapper<AppRoute> { mapper in
    mapper.route("/product/{id}") { params in
        .product(id: params.require("id"))
    }
    mapper.route("/checkout") { params in
        .checkout(promo: params["promo"])
    }
}
```

## Test Mode

```swift
let config: TraceClientConfig = .test(
    simulatedDeepLink: TraceDeepLink(
        path: "/product/demo-123",
        params: ["source": "sample"],
        isDeferred: true
    )
)
TraceClient.initialize(config: config)
```

## Documentation

- [iOS SDK Guide](https://clicktrace.io/docs/sdk/ios)
- [Deep Links](https://clicktrace.io/docs/sdk/deep-links)
- [Configuration](https://clicktrace.io/docs/sdk/configuration)
- [Sample App](https://github.com/bmcreations/trace-samples/tree/main/ios)

## Architecture

This package is a Swift wrapper around the shared [Trace KMP SDK](https://github.com/bmcreations/trace). The core attribution and networking logic lives in the Kotlin Multiplatform codebase, compiled to an XCFramework (`TraceKMP`) and distributed as a binary target.
