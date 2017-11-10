// swift-tools-version:4.0
import PackageDescription

let package = Package(
    name: "Moya",
    products: [
        .library(name: "Moya", targets: ["Moya"]),
        .library(name: "ReactiveMoya", targets: ["ReactiveMoya"]),
        .library(name: "RxMoya", targets: ["RxMoya"]),
    ],
    dependencies: [
        .package(url: "https://github.com/Alamofire/Alamofire.git", .upToNextMajor(from: "4.1.0")),
        .package(url: "https://github.com/antitypical/Result.git", .upToNextMajor(from: "3.0.0")),
        .package(url: "https://github.com/ReactiveCocoa/ReactiveSwift.git", .upToNextMajor(from: "2.0.0")),
        .package(url: "https://github.com/ReactiveX/RxSwift.git", .upToNextMajor(from: "4.0.0")),
    ],
    targets: [
         .target(
            name: "Moya",
            dependencies: [
                "Alamofire",
                "Result"],
            exclude: [
                "Tests",
                "Sources/Supporting Files",
                "Examples"]),
        .target(
            name: "ReactiveMoya",
            dependencies: [
                "Moya",
                "ReactiveSwift"],
            exclude: [
                "Tests",
                "Sources/Supporting Files",
                "Examples"]),
        .target(
            name: "RxMoya",
            dependencies: [
                "Moya",
                "RxSwift"],
            exclude: [
                "Tests",
                "Sources/Supporting Files",
                "Examples"])                
    ],
    swiftLanguageVersions: [3, 4]
)
