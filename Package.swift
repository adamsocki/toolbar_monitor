// swift-tools-version:5.10
import PackageDescription

let package = Package(
    name: "NetMonitor",
    platforms: [.macOS(.v13)],
    targets: [
        .executableTarget(name: "NetMonitor", path: "Sources/NetMonitor")
    ]
)
