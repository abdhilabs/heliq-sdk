// swift-tools-version:6.1
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
    .package(url: "https://github.com/argentlabs/web3.swift", exact: "2.0.0")
  ],
  targets: [
    .target(
      name: "HeliqSDK",
      dependencies: [
        .product(name: "web3.swift", package: "web3.swift")
      ],
      exclude: ["Info.plist"]
    ),
    .testTarget(
      name: "HeliqSDKTests",
      dependencies: ["HeliqSDK"],
      exclude: ["Info.plist"],
      resources: [.process("Fixtures/Perps")]
    ),
    .testTarget(
      name: "HeliqSDKIntegrationTests",
      dependencies: ["HeliqSDK"],
      exclude: ["Info.plist"]
    )
  ]
)
