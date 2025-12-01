//
//  File.swift
//  swift-rfc-6570
//
//  Created by Coen ten Thije Boonkkamp on 19/11/2025.
//

extension RFC_6570 {
    /// Template expression operators as defined in RFC 6570 Section 3.2
    public enum Operator: String, Hashable, Sendable, CaseIterable {
        /// Simple string expansion (no operator)
        /// Example: `{var}` → `value`
        case simple = ""

        /// Reserved string expansion
        /// Example: `{+var}` → `value` (reserved chars not encoded)
        case reserved = "+"

        /// Fragment expansion
        /// Example: `{#var}` → `#value`
        case fragment = "#"

        /// Label expansion with dot-prefix
        /// Example: `{.var}` → `.value`
        case label = "."

        /// Path segment expansion
        /// Example: `{/var}` → `/value`
        case path = "/"

        /// Path-style parameter expansion
        /// Example: `{;var}` → `;var=value`
        case parameter = ";"

        /// Query expansion
        /// Example: `{?var}` → `?var=value`
        case query = "?"

        /// Query continuation
        /// Example: `{&var}` → `&var=value`
        case continuation = "&"

        /// The string prefix for this operator
        var prefix: String {
            switch self {
            case .simple: return ""
            case .reserved: return ""
            case .fragment: return "#"
            case .label: return "."
            case .path: return "/"
            case .parameter: return ";"
            case .query: return "?"
            case .continuation: return "&"
            }
        }

        /// The separator between multiple values for this operator
        var separator: String {
            switch self {
            case .simple, .reserved, .fragment: return ","
            case .label: return "."
            case .path: return "/"
            case .parameter: return ";"
            case .query, .continuation: return "&"
            }
        }

        /// Whether this operator uses named parameters (key=value format)
        var named: Bool {
            switch self {
            case .simple, .reserved, .fragment, .label, .path: return false
            case .parameter, .query, .continuation: return true
            }
        }

        /// Whether this operator allows reserved characters
        var allowReserved: Bool {
            switch self {
            case .simple, .label, .path, .parameter, .query, .continuation: return false
            case .reserved, .fragment: return true
            }
        }
    }
}

extension RFC_6570.Operator {
    /// Whether this operator includes empty values in output
    public var includesEmptyValues: Bool {
        switch self {
        case .query, .continuation:
            return true  // Include "=" for empty values
        case .parameter:
            return false  // Omit "=" for empty values
        default:
            return true
        }
    }
}
