// swift-tools-version:5.5
import PackageDescription

let package = Package(
    name: "Wav2Text",
    platforms: [
        .macOS(.v12)
    ],
    dependencies: [],
    targets: [
        .executableTarget(
            name: "Wav2Text",
            dependencies: [],
            resources: [
                .process("Resources/Info.plist")
            ]
        )
    ]
) 