// swift-tools-version: 5.10

import PackageDescription

let package = Package(
    name: "AIPromptDock",
    platforms: [.macOS(.v14)],
    products: [
        .executable(name: "AIPromptDock", targets: ["AIPromptDock"])
    ],
    targets: [
        .executableTarget(
            name: "AIPromptDock",
            path: "Sources/AIPromptDock"
        )
    ],
    swiftLanguageVersions: [.v5]
)
