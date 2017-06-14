import PackageDescription

let package = Package(
    name: "Moya",
    targets: [
        Target(
            name: "Moya"
        ),
        Target(
            name: "ReactiveMoya",
            dependencies: ["Moya"]
        ),
        Target(
            name: "RxMoya",
            dependencies: ["Moya"]
        )
    ],
    dependencies: [
        .Package(url: "https://github.com/Alamofire/Alamofire.git", majorVersion: 4),
        .Package(url: "https://github.com/ReactiveCocoa/ReactiveSwift.git", majorVersion: 1),
        .Package(url: "https://github.com/ReactiveX/RxSwift.git", majorVersion: 3),
        .Package(url: "https://github.com/antitypical/Result.git", majorVersion: 3)
    ],
    exclude: [
        "Tests"
    ]
)
