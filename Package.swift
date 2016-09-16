import PackageDescription

let package = Package(
    name: "Moya",
    targets: [
        Target(
            name: "Moya"
        ),
        Target(
            name: "RxMoya",
            dependencies: [
                .Target(name: "Moya")
            ]
        )
    ],
    dependencies: [
        .Package(url: "https://github.com/AndrewSB/RxSwift", versions: Version(3, 0, 2)...Version(4, 0, 0)),
        .Package(url: "https://github.com/Alamofire/Alamofire", versions: Version(4, 0, 0)...Version(5, 0, 0))
    ],
    exclude: [
        ".build",
    ]
)
