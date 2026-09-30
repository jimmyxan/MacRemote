// swift-tools-version:5.9
import PackageDescription

let package = Package(
    name: "MacRemote",
    platforms: [.macOS(.v13)],
    targets: [
        .executableTarget(name: "MacRemote", path: "Sources/MacRemote")
    ]
)
