// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "MusicKeyBoard",
    platforms: [
        .macOS(.v14)
    ],
    products: [
        .executable(name: "MusicKeyBoard", targets: ["MusicKeyBoard"])
    ],
    targets: [
        .executableTarget(
            name: "MusicKeyBoard",
            path: "MusicKeyBoard",
            resources: [
                .copy("Resources")
            ]
        )
    ]
)
