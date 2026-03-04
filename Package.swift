// swift-tools-version: 5.9
import PackageDescription

let version = "0.3.1"
let checksum = "3238df21bdcbd1c03b2d341c7e30f85a1fc321a248036a1fcbca3fa449ace4b6"

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
