// swift-tools-version: 6.0
import Foundation
import PackageDescription

let packageDirectory = URL(fileURLWithPath: #filePath).deletingLastPathComponent().path

let package = Package(
    name: "AeroFlow",
    defaultLocalization: "en",
    platforms: [
        .macOS(.v15)
    ],
    products: [
        .executable(
            name: "AeroFlow",
            targets: ["AeroFlowApp"]
        ),
        .executable(
            name: "aeroflowctl",
            targets: ["AeroFlowCtl"]
        )
    ],
    dependencies: [
        .package(url: "https://github.com/mattt/swift-toml.git", from: "2.0.0")
    ],
    targets: [
        .target(
            name: "AeroFlowIPC",
            path: "Sources/AeroFlowIPC",
            swiftSettings: [
                .swiftLanguageMode(.v6)
            ]
        ),

        .target(
            name: "AeroFlowLayerCorners",
            path: "Sources/AeroFlowLayerCorners",
            cSettings: [
            ]
        ),
        .target(
            name: "AeroFlowLauncherSPI",
            path: "Sources/AeroFlowLauncherSPI",
            cSettings: [
            ]
        ),
        .target(
            name: "AeroFlow",
            dependencies: [
                "AeroFlowIPC",
                "AeroFlowLayerCorners",
                "AeroFlowLauncherSPI",
                .product(name: "TOML", package: "swift-toml")
            ],
            path: "Sources/AeroFlow",
            resources: [
                .process("Resources"),
                .copy("Core/IssueReporter/Prompts")
            ],
            swiftSettings: [
                .swiftLanguageMode(.v6),
                .interoperabilityMode(.C)
            ],
            linkerSettings: [
                .linkedFramework("AppKit"),
                .linkedFramework("ApplicationServices"),
                .linkedFramework("Carbon"),
                .linkedFramework("Metal"),
                .linkedFramework("MetalKit"),
                .linkedFramework("QuartzCore"),
                .linkedLibrary("z"),
                .linkedLibrary("c++"),

                .unsafeFlags(["-F/System/Library/PrivateFrameworks", "-framework", "SkyLight"])
            ]
        ),
        .executableTarget(
            name: "AeroFlowApp",
            dependencies: ["AeroFlow"],
            path: "Sources/AeroFlowApp",
            swiftSettings: [
                .swiftLanguageMode(.v6)
            ]
        ),
        .executableTarget(
            name: "AeroFlowCtl",
            dependencies: ["AeroFlowIPC"],
            path: "Sources/AeroFlowCtl",
            resources: [
                .embedInCode("Completions/completion.zsh"),
                .embedInCode("Completions/completion.bash"),
                .embedInCode("Completions/completion.fish"),
                .embedInCode("Completions/completion.nu")
            ],
            swiftSettings: [
                .swiftLanguageMode(.v6)
            ]
        ),
        .testTarget(
            name: "AeroFlowTests",
            dependencies: ["AeroFlow", "AeroFlowCtl", "AeroFlowLayerCorners"],
            path: "Tests/AeroFlowTests",
            resources: [
                .copy("Fixtures")
            ],
            swiftSettings: [
                .swiftLanguageMode(.v6)
            ]
        )
    ]
)
