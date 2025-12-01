// swift-tools-version:6.2

import PackageDescription

extension String {
    static let rfc6570: Self = "RFC 6570"
}

extension Target.Dependency {
    static var rfc6570: Self { .target(name: .rfc6570) }
}

let package = Package(
    name: "swift-rfc-6570",
    platforms: [
        .macOS(.v15),
        .iOS(.v18),
        .tvOS(.v18),
        .watchOS(.v11)
    ],
    products: [
        .library(name: .rfc6570, targets: [.rfc6570]),
    ],
    dependencies: [
        .package(url: "https://github.com/swift-standards/swift-incits-4-1986", from: "0.6.0"),
        .package(url: "https://github.com/swift-standards/swift-rfc-3986", from: "0.3.0"),
        .package(url: "https://github.com/apple/swift-collections", from: "1.1.0"),
    ],
    targets: [
        .target(
            name: .rfc6570,
            dependencies: [
                .product(name: "INCITS 4 1986", package: "swift-incits-4-1986"),
                .product(name: "RFC 3986", package: "swift-rfc-3986"),
                .product(name: "OrderedCollections", package: "swift-collections"),
            ]
        ),
        .testTarget(
            name: .rfc6570.tests,
            dependencies: [
                .rfc6570
            ]
        ),
    ],
    swiftLanguageModes: [.v6]
)

extension String {
    var tests: Self { self + " Tests" }
    var foundation: Self { self + " Foundation" }
}

for target in package.targets where ![.system, .binary, .plugin].contains(target.type) {
    let existing = target.swiftSettings ?? []
    target.swiftSettings = existing + [
        .enableUpcomingFeature("ExistentialAny"),
        .enableUpcomingFeature("InternalImportsByDefault"),
        .enableUpcomingFeature("MemberImportVisibility")
    ]
}
