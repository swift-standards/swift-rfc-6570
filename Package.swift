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
        .macOS(.v26),
        .iOS(.v26),
        .tvOS(.v26),
        .watchOS(.v26)
    ],
    products: [
        .library(name: .rfc6570, targets: [.rfc6570]),
    ],
    dependencies: [
        .package(path: "../../swift-foundations/swift-ascii"),
        .package(path: "../swift-rfc-3986"),
        .package(path: "../../swift-primitives/swift-container-primitives"),
    ],
    targets: [
        .target(
            name: .rfc6570,
            dependencies: [
                .product(name: "ASCII", package: "swift-ascii"),
                .product(name: "RFC 3986", package: "swift-rfc-3986"),
                .product(name: "Container Primitives", package: "swift-container-primitives"),
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
