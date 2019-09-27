// swift-tools-version:5.0
// This Package.swift is split for production use and development separately.
// Basically SPM fetches testing dependencies even though they are not needed for the main target. And because
// of that, sometimes the build fails as the build system wants to build XCTest or other frameworks for main bundle...
// TL;DR waiting for SE-0226 to be implemented: https://github.com/apple/swift-evolution/blob/master/proposals/0226-package-manager-target-based-dep-resolution.md
//
// In the meantime:
//     - when you include our library as a dependency SPM won't fetch testing libraries
//     - when you want to test the library use `TEST=1 swift test` and it should work properly

import PackageDescription
import class Foundation.ProcessInfo

let shouldTest = ProcessInfo.processInfo.environment["TEST"] == "1"

func resolveDependencies() -> [Package.Dependency] {
    let baseDependencies: [Package.Dependency] = [
        .package(url: "https://github.com/Alamofire/Alamofire.git", .exact("5.0.0-rc.2")),
        .package(url: "https://github.com/Moya/ReactiveSwift.git", .upToNextMajor(from: "6.1.0")),
        .package(url: "https://github.com/ReactiveX/RxSwift.git", .upToNextMajor(from: "5.0.0"))
    ]

    if shouldTest {
        let testDependencies: [Package.Dependency] = [
            .package(url: "https://github.com/Quick/Quick.git", .upToNextMajor(from: "2.0.0")),
            .package(url: "https://github.com/Quick/Nimble.git", .upToNextMajor(from: "8.0.0")),
            .package(url: "https://github.com/AliSoftware/OHHTTPStubs.git", .branch("feature/spm-support"))
        ]

        return baseDependencies + testDependencies
    } else {
        return baseDependencies
    }
}

func resolveTargets() -> [Target] {
    let baseTargets: [Target] = [
        .target(name: "Moya", dependencies: ["Alamofire"]),
        .target(name: "ReactiveMoya", dependencies: ["Moya", "ReactiveSwift"]),
        .target(name: "RxMoya", dependencies: ["Moya", "RxSwift"])
    ]

    if shouldTest {
        let testTargets: [Target] = [
            .testTarget(name: "MoyaTests", dependencies: [
                "Moya",
                "RxMoya",
                "ReactiveMoya",
                "Quick",
                "Nimble",
                "OHHTTPStubsSwift"
            ])
        ]

        return baseTargets + testTargets
    } else {
        return baseTargets
    }
}

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
    dependencies: resolveDependencies(),
    targets: resolveTargets()
)
