import Foundation
import RFC_3986

/// Implementation of RFC 6570: URI Template
///
/// RFC 6570 defines a simple notation for describing the structure of URIs that includes
/// template variables. URI Templates allow for the definition of URI patterns with embedded
/// variables to be expanded according to specific rules for each template operator.
///
/// Example:
/// ```swift
/// let template = try RFC_6570.Template("https://api.example.com/users/{id}/posts{?page,limit}")
/// let uri = try template.expand(variables: [
///     "id": "123",
///     "page": "1",
///     "limit": "50"
/// ])
/// // Result: "https://api.example.com/users/123/posts?page=1&limit=50"
/// ```
///
/// See: https://www.rfc-editor.org/rfc/rfc6570.html
public enum RFC_6570 {}

// MARK: - Core Types

extension RFC_6570 {
    /// A URI Template as defined in RFC 6570
    ///
    /// URI Templates provide a compact syntax for describing a range of URIs through variable
    /// expansion. This implementation supports all four levels of template expressions defined
    /// in RFC 6570 Section 1.2.
    ///
    /// Template expressions can contain:
    /// - Variable names: `{var}`
    /// - Operators: `{+var}`, `{#var}`, `{.var}`, `{/var}`, `{;var}`, `{?var}`, `{&var}`
    /// - Modifiers: prefix `:n` and explode `*`
    ///
    /// Example:
    /// ```swift
    /// let template = try Template("/{path}{?query*}")
    /// let uri = try template.expand(variables: [
    ///     "path": .string("search"),
    ///     "query": .dictionary(["q": "swift", "lang": "en"])
    /// ])
    /// // Result: "/search?q=swift&lang=en"
    /// ```
    public struct Template: Hashable, Sendable {
        /// The template string
        public let value: String

        /// Parsed template components (literals and expressions)
        internal let components: [Component]

        /// Creates a URI template with validation
        /// - Parameter value: The template string
        /// - Throws: `RFC_6570.Error` if the template is invalid
        public init(_ value: String) throws {
            self.value = value
            self.components = try Self.parse(value)
        }

        /// Creates a URI template without validation (for internal use)
        internal init(unchecked value: String, components: [Component]) {
            self.value = value
            self.components = components
        }
    }
}

// MARK: - Template Components

extension RFC_6570.Template {
    /// A component of a URI template (either a literal string or an expression)
    internal enum Component: Hashable, Sendable {
        case literal(String)
        case expression(Expression)
    }

    /// A template expression: operator and list of variable specifications
    internal struct Expression: Hashable, Sendable {
        let op: RFC_6570.Operator
        let varspecs: [VarSpec]

        init(op: RFC_6570.Operator = .simple, varspecs: [VarSpec]) {
            self.op = op
            self.varspecs = varspecs
        }
    }

    /// A variable specification within an expression
    internal struct VarSpec: Hashable, Sendable {
        let name: String
        let modifier: RFC_6570.Modifier?

        init(name: String, modifier: RFC_6570.Modifier? = nil) {
            self.name = name
            self.modifier = modifier
        }
    }
}

// MARK: - Operators

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
            case .label, .path: return "."
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

// MARK: - Modifiers

extension RFC_6570 {
    /// Variable modifiers as defined in RFC 6570 Section 2.4
    public enum Modifier: Hashable, Sendable {
        /// Prefix modifier (`:n`) - limits string to first n characters
        /// Example: `{var:3}` with var="value" → `val`
        case prefix(Int)

        /// Explode modifier (`*`) - expands composite values separately
        /// Example: `{list*}` with list=["a","b"] → `a,b` or `a&b` depending on operator
        case explode
    }
}

// MARK: - Variable Values

extension RFC_6570 {
    /// A value that can be used in template expansion
    public enum VariableValue: Hashable, Sendable {
        /// A simple string value
        case string(String)

        /// A list of string values
        case list([String])

        /// An associative array (dictionary) of string key-value pairs
        case dictionary([String: String])

        /// Returns whether this value is defined (non-nil)
        var isDefined: Bool {
            switch self {
            case .string(let s): return !s.isEmpty
            case .list(let l): return !l.isEmpty
            case .dictionary(let d): return !d.isEmpty
            }
        }
    }
}

// MARK: - Errors

extension RFC_6570 {
    /// Errors that can occur during URI template operations
    public enum Error: Swift.Error, Hashable, Sendable, CustomStringConvertible {
        /// The template string is invalid
        case invalidTemplate(String)

        /// An expression in the template is malformed
        case invalidExpression(String)

        /// A variable name is invalid
        case invalidVariableName(String)

        /// A modifier is invalid
        case invalidModifier(String)

        /// Template expansion failed
        case expansionFailed(String)

        /// Template matching failed
        case matchingFailed(String)

        public var description: String {
            switch self {
            case .invalidTemplate(let msg):
                return "Invalid URI template: \(msg)"
            case .invalidExpression(let msg):
                return "Invalid expression: \(msg)"
            case .invalidVariableName(let msg):
                return "Invalid variable name: \(msg)"
            case .invalidModifier(let msg):
                return "Invalid modifier: \(msg)"
            case .expansionFailed(let msg):
                return "Template expansion failed: \(msg)"
            case .matchingFailed(let msg):
                return "Template matching failed: \(msg)"
            }
        }
    }
}

// MARK: - Conformances

extension RFC_6570.Template: Codable {
    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        let value = try container.decode(String.self)
        try self.init(value)
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(value)
    }
}

extension RFC_6570.Template: CustomStringConvertible {
    public var description: String { value }
}

extension RFC_6570.Template: CustomDebugStringConvertible {
    public var debugDescription: String {
        "RFC_6570.Template(\(value))"
    }
}

extension RFC_6570.Template: RawRepresentable {
    public var rawValue: String { value }

    public init?(rawValue: String) {
        try? self.init(rawValue)
    }
}

extension RFC_6570.Template: Comparable {
    public static func < (lhs: Self, rhs: Self) -> Bool {
        lhs.value < rhs.value
    }
}

extension RFC_6570.VariableValue: ExpressibleByStringLiteral {
    public init(stringLiteral value: String) {
        self = .string(value)
    }
}

extension RFC_6570.VariableValue: ExpressibleByArrayLiteral {
    public init(arrayLiteral elements: String...) {
        self = .list(elements)
    }
}

extension RFC_6570.VariableValue: ExpressibleByDictionaryLiteral {
    public init(dictionaryLiteral elements: (String, String)...) {
        self = .dictionary(Dictionary(uniqueKeysWithValues: elements))
    }
}
