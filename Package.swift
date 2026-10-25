// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "LifeIsShortCore",
    platforms: [.macOS(.v15), .iOS("27.0")],
    products: [.library(name: "LifeIsShortCore", targets: ["LifeIsShortCore"])],
    targets: [
        .target(name: "LifeIsShortCore", path: "LifeIsShort/Shared/Core"),
        .testTarget(name: "LifeIsShortCoreTests", dependencies: ["LifeIsShortCore"], path: "Tests/Core")
    ]
)
