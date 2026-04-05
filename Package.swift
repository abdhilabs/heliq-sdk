// swift-tools-version:6.0
import PackageDescription

let package = Package(
    name: "HeliqSDK",
    platforms: [
        .iOS(.v16),
        .macOS(.v13)
    ],
    products: [
        .library(
            name: "HeliqSDK",
            targets: ["HeliqSDK"]
        )
    ],
    dependencies: [
        .package(url: "https://github.com/web3swift-team/web3swift", from: "3.2.0")
    ],
    targets: [
        .target(
            name: "HeliqSDK",
            dependencies: [
                .product(name: "web3swift", package: "web3swift")
            ]
        ),
        .testTarget(
            name: "HeliqSDKTests",
            dependencies: ["HeliqSDK"]
        ),
        .testTarget(
            name: "HeliqSDKIntegrationTests",
            dependencies: ["HeliqSDK"]
        )
    ]
)
