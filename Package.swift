// swift-tools-version: 5.9
import PackageDescription

let version = "0.5.2"
let checksum = "e759b0aeeb95003fe9d43d2a5e40ddd76c9c2e6b0201cc09c056853fdee82291"

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
