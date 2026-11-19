// swift-tools-version: 6.0

import Foundation
import PackageDescription

var packageDependencies: [Package.Dependency] = []
var targetDependencies: [Target.Dependency] = []

#if !os(macOS)
packageDependencies += [
    .package(
        name: "CrossSwiftUI",
        path: ProcessInfo.processInfo.environment["CROSS_SWIFTUI_PATH"]
            ?? "../crossswift")
]

let crossSwiftProducts = [
    "CrossFoundation", "CoreFoundation", "Darwin", "ApplicationServices",
    "ServiceManagement", "Security", "CloudKit", "EventKit",
    "AVFoundation", "AVKit", "CoreAudio", "AudioToolbox", "CoreMedia",
    "CoreServices", "CoreText", "ImageIO", "ColorSync", "PDFKit",
    "QuickLookUI", "QuickLookThumbnailing", "Network", "SystemConfiguration",
    "AuthenticationServices", "JavaScriptCore", "IOKit", "Compression",
    "System", "AppleArchive", "Accelerate", "notify", "CommonCrypto",
    "FoundationModels", "NaturalLanguage", "Translation",
    "AppKit", "CrossAppKit", "Carbon", "CoreGraphics",
    "UniformTypeIdentifiers", "OSLog", "os", "Combine", "CryptoKit", "SwiftUI"
]

targetDependencies += crossSwiftProducts.map { .product(name: $0, package: "CrossSwiftUI") }
#endif

#if os(Windows)
targetDependencies += [
    .product(name: "SQLite3", package: "CrossSwiftUI"),
    .product(name: "CAppKitWindows", package: "CrossSwiftUI")
]
#endif

let package = Package(
    name: "Tinycast",
    platforms: [.macOS("26.0")],
    products: [
        .executable(name: "Tinycast", targets: ["Tinycast"])
    ],
    dependencies: packageDependencies,
    targets: [
        .executableTarget(
            name: "Tinycast",
            dependencies: targetDependencies,
            path: "Tinycast",
            exclude: [
                "Assets.xcassets",
                "Info.plist",
                "Resources",
                "Tinycast.entitlements",
                "TinycastCloud.entitlements",
                "tinycast.icon",
                "Features/Clipboard/Service/ClipboardTextExtractor.swift",
                "Features/Clipboard/Service/ClipboardTextHelper.swift",
                "Features/Dictation/Helper",
                "Features/FileSearch/Helper"
            ],
            linkerSettings: [
                .unsafeFlags(["-Xlinker", "/STACK:16777216"], .when(platforms: [.windows]))
            ]
        )
    ],
    cxxLanguageStandard: .cxx17
)
