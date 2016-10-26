import PackageDescription

let package = Package(
    name: "Moya",
    targets: [
        Target(
            name: "Moya"
        ),
        Target(
            name: "ReactiveMoya",
            dependencies: [
                .Target(name: "Moya")
            ]
        ),
        Target(
            name: "RxMoya",
            dependencies: [
                .Target(name: "Moya")
            ]
        )
    ],
    dependencies: [
        .Package(url: "https://github.com/Alamofire/Alamofire", majorVersion: 4),
        .Package(url: "https://github.com/ReactiveCocoa/ReactiveSwift", "1.0.0-alpha.3"),
        .Package(url: "https://github.com/ReactiveX/RxSwift", majorVersion: 3)
    ],
    exclude: [
        ".build",
        "Demo",
        "Tests"
    ]
)
