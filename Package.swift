// swift-tools-version:5.0
import PackageDescription

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
        .library(name: "ReactiveMoya", targets: ["ReactiveMoya"]),
        .library(name: "RxMoya", targets: ["RxMoya"])
    ],
    dependencies: [
        .package(url: "https://github.com/Alamofire/Alamofire.git", .exact("5.0.0-rc.2")),
        .package(url: "https://github.com/ReactiveCocoa/ReactiveSwift.git", .upToNextMajor(from: ("6.0.0"))),
        .package(url: "https://github.com/ReactiveX/RxSwift.git", .upToNextMajor(from: "5.0.0")),
        .package(url: "https://github.com/Quick/Quick.git", .upToNextMajor(from: "2.0.0")),
        .package(url: "https://github.com/Quick/Nimble.git", .upToNextMajor(from: "8.0.0")),
//        .package(url: "https://github.com/AliSoftware/OHHTTPStubs.git", .branch("feature/spm-support")),
    ],
    targets: [
         .target(
            name: "Moya",
            dependencies: [
                "Alamofire"
            ]
        ),
        .target(
            name: "ReactiveMoya",
            dependencies: [
                "Moya",
                "ReactiveSwift"
            ]
        ),
        .target(
            name: "RxMoya",
            dependencies: [
                "Moya",
                "RxSwift"
            ]
        ),
        .testTarget(
            name: "MoyaTests",
            dependencies: [
                "Moya",
                "RxMoya",
                "ReactiveMoya",
                "Quick",
                "Nimble",
//                "OHHTTPStubsSwift"
            ]
        )
    ]
)
