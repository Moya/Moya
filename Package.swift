// swift-tools-version:5.3

import PackageDescription

let rocketIfNeeded: [Package.Dependency]

#if os(OSX) || os(Linux)
rocketIfNeeded = [
    .package(url: "https://github.com/shibapm/Rocket", .upToNextMajor(from: "1.2.0")) // dev
]
#else
rocketIfNeeded = []
#endif

let package = Package(
    name: "Moya",
    platforms: [
        .macOS(.v10_12),
        .iOS(.v10),
        .tvOS(.v10),
        .watchOS(.v3)
    ],
    products: [
        .library(name: "Moya", targets: ["Moya"]),
        .library(name: "CombineMoya", targets: ["CombineMoya"]),
        .library(name: "ReactiveMoya", targets: ["ReactiveMoya"]),
        .library(name: "RxMoya", targets: ["RxMoya"])
    ],
    dependencies: [
        .package(url: "https://github.com/Alamofire/Alamofire.git", .upToNextMajor(from: "5.4.3")),
        .package(url: "https://github.com/ReactiveCocoa/ReactiveSwift.git", .upToNextMajor(from: "6.6.1")),
        .package(url: "https://github.com/ReactiveX/RxSwift.git", .upToNextMajor(from: "6.2.0")),
        .package(url: "https://github.com/Quick/Quick.git", .upToNextMajor(from: "4.0.0")), // dev
        .package(url: "https://github.com/Quick/Nimble.git", .upToNextMajor(from: "9.2.0")), // dev
        .package(url: "https://github.com/AliSoftware/OHHTTPStubs.git", .upToNextMajor(from: "9.0.0")) // dev
    ] + rocketIfNeeded,
    targets: [
        .target(
            name: "Moya",
            dependencies: [
                .product(name: "Alamofire", package: "Alamofire")
            ]
        ),
        .target(
            name: "CombineMoya",
            dependencies: [
                "Moya"
            ]
        ),
        .target(
            name: "ReactiveMoya",
            dependencies: [
                "Moya",
                .product(name: "ReactiveSwift", package: "ReactiveSwift")
            ]
        ),
        .target(
            name: "RxMoya",
            dependencies: [
                "Moya",
                .product(name: "RxSwift", package: "RxSwift")
            ]
        ),
        .testTarget(
            name: "MoyaTests",  // dev
            dependencies: [
                "Moya",
                "CombineMoya",
                "ReactiveMoya",
                "RxMoya",
                .product(name: "Quick", package: "Quick"),
                .product(name: "Nimble", package: "Nimble"),
                .product(name: "OHHTTPStubsSwift", package: "OHHTTPStubs")
            ]
        )
    ]
)

#if canImport(PackageConfig)
import PackageConfig

let config = PackageConfiguration([
    "rocket": [
        "before": [
            "scripts/update_changelog.sh",
            "scripts/update_podspec.sh"
        ],
        "after": [
            "rake create_release\\[\"$VERSION\"\\]",
            "scripts/update_docs_website.sh"
        ]
    ]
]).write()
#endif
