// swift-tools-version: 6.1
import PackageDescription

let package = Package(
    name: "AlongKit",
    platforms: [
        .iOS(.v17),
        .watchOS(.v10),
        .macOS(.v14)
    ],
    products: [
        .library(name: "AlongCore", targets: ["AlongCore"]),
        .library(name: "AlongApple", targets: ["AlongApple"]),
        .library(name: "AlongMemory", targets: ["AlongMemory"]),
        .library(name: "AlongOpenAI", targets: ["AlongOpenAI"]),
        .library(name: "AlongGemini", targets: ["AlongGemini"])
    ],
    targets: [
        .target(name: "AlongCore"),
        .target(name: "AlongApple", dependencies: ["AlongCore"]),
        .target(name: "AlongMemory", dependencies: ["AlongCore"]),
        .target(name: "AlongOpenAI", dependencies: ["AlongCore"]),
        .target(name: "AlongGemini", dependencies: ["AlongCore"]),
        .testTarget(name: "AlongCoreTests", dependencies: ["AlongCore"]),
        .testTarget(name: "AlongAppleTests", dependencies: ["AlongApple", "AlongCore"]),
        .testTarget(name: "AlongMemoryTests", dependencies: ["AlongMemory"]),
        .testTarget(
            name: "AlongProviderTests",
            dependencies: ["AlongCore", "AlongOpenAI", "AlongGemini"]
        )
    ],
    swiftLanguageModes: [.v6]
)
