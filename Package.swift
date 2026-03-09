// swift-tools-version: 5.9
import PackageDescription

let version = "0.7.4"
let checksum = "d10d0a12f572b44c9219c81dca39d1aa09a66d1ce0f36ec80f7c92da649a383d"

let package = Package(
    name: "TraceSDK",
    platforms: [.iOS(.v16)],
    products: [
        .library(name: "TraceSDK", targets: ["TraceSDK", "TraceKMP"])
    ],
    targets: [
        .target(name: "TraceSDK", dependencies: ["TraceKMP"], path: "Sources"),
        .binaryTarget(
  name: "TraceKMP",
  url: "https://github.com/bmcreations/trace-sdk-ios/releases/download/\(version)/TraceKMP.xcframework.zip",
  checksum: checksum
        )
    ]
)
