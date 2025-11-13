// swift-tools-version:6.0

import Foundation
import PackageDescription

extension String {
    static let rfc6570: Self = "RFC_6570"
}

extension Target.Dependency {
    static var rfc6570: Self { .target(name: .rfc6570) }
}

let package = Package(
    name: "swift-rfc-6570",
    platforms: [
        .macOS(.v14),
        .iOS(.v17),
        .tvOS(.v17),
        .watchOS(.v10)
    ],
    products: [
        .library(name: .rfc6570, targets: [.rfc6570]),
    ],
    dependencies: [
        .package(url: "https://github.com/swift-standards/swift-rfc-3986.git", from: "0.0.1"),
    ],
    targets: [
        .target(
            name: .rfc6570,
            dependencies: [
                .product(name: "RFC 3986", package: "swift-rfc-3986"),
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

extension String { var tests: Self { self + " Tests" } }
