import Foundation
import RFC_3986

// MARK: - Swift Convenience Extensions

extension RFC_6570.Template {
    /// Expands the template with string values
    ///
    /// Convenience method that automatically wraps strings in VariableValue
    /// and returns a URI reference.
    ///
    /// Example:
    /// ```swift
    /// let template = try Template("/users/{id}")
    /// let uri = try template.expand(["id": "123"])
    /// // Returns: RFC_3986.URI("/users/123")
    /// ```
    public func expand(_ variables: [String: String]) throws -> RFC_3986.URI {
        let wrapped = variables.mapValues { RFC_6570.VariableValue.string($0) }
        return try expand(variables: wrapped)
    }
}

// MARK: - String Extensions

extension String {
    /// Creates a URI template from this string
    ///
    /// Example:
    /// ```swift
    /// let template = try "/users/{id}/posts".asURITemplate()
    /// ```
    public func asURITemplate() throws -> RFC_6570.Template {
        try RFC_6570.Template(self)
    }
}

// MARK: - URL Extensions

extension URL {
    /// Creates a URL by expanding a URI template with variables
    ///
    /// Example:
    /// ```swift
    /// let url = try URL(template: "https://api.example.com/users/{id}", variables: ["id": "123"])
    /// ```
    public init(template: String, variables: [String: String]) throws {
        let tpl = try RFC_6570.Template(template)
        let uri = try tpl.expand(variables)
        guard let url = URL(string: uri.value) else {
            throw RFC_6570.Error.expansionFailed("Result is not a valid URL: \(uri.value)")
        }
        self = url
    }

    /// Creates a URL by expanding a URI template with variable values
    public init(template: String, variables: [String: RFC_6570.VariableValue]) throws {
        let tpl = try RFC_6570.Template(template)
        let uri = try tpl.expand(variables: variables)
        guard let url = URL(string: uri.value) else {
            throw RFC_6570.Error.expansionFailed("Result is not a valid URL: \(uri.value)")
        }
        self = url
    }

    /// Creates a URL by expanding an existing template with variables
    ///
    /// Example:
    /// ```swift
    /// let template = try RFC_6570.Template("https://api.example.com/users/{id}")
    /// let url = try URL(template: template, variables: ["id": "123"])
    /// ```
    public init(template: RFC_6570.Template, variables: [String: String]) throws {
        let uri = try template.expand(variables)
        guard let url = URL(string: uri.value) else {
            throw RFC_6570.Error.expansionFailed("Result is not a valid URL: \(uri.value)")
        }
        self = url
    }

    /// Creates a URL by expanding an existing template with variable values
    public init(template: RFC_6570.Template, variables: [String: RFC_6570.VariableValue]) throws {
        let uri = try template.expand(variables: variables)
        guard let url = URL(string: uri.value) else {
            throw RFC_6570.Error.expansionFailed("Result is not a valid URL: \(uri.value)")
        }
        self = url
    }
}

// MARK: - Operator Convenience

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

// MARK: - Variable Value Conveniences

extension RFC_6570.VariableValue {
    /// Returns the value as a string if possible
    public var stringValue: String? {
        switch self {
        case .string(let s): return s
        default: return nil
        }
    }

    /// Returns the value as a list if possible
    public var listValue: [String]? {
        switch self {
        case .list(let l): return l
        default: return nil
        }
    }

    /// Returns the value as a dictionary if possible
    public var dictionaryValue: [String: String]? {
        switch self {
        case .dictionary(let d): return Dictionary(uniqueKeysWithValues: d.map { ($0.key, $0.value) })
        default: return nil
        }
    }
}

// MARK: - Error Extensions

extension RFC_6570.Error: LocalizedError {
    public var errorDescription: String? {
        description
    }

    public var failureReason: String? {
        switch self {
        case .invalidTemplate(let msg):
            return "The template string contains invalid syntax: \(msg)"
        case .invalidExpression(let msg):
            return "An expression is malformed: \(msg)"
        case .invalidVariableName(let msg):
            return "A variable name is invalid: \(msg)"
        case .invalidModifier(let msg):
            return "A modifier is invalid: \(msg)"
        case .expansionFailed(let msg):
            return "Template expansion failed: \(msg)"
        case .matchingFailed(let msg):
            return "Template matching failed: \(msg)"
        }
    }

    public var recoverySuggestion: String? {
        switch self {
        case .invalidTemplate:
            return "Check that all braces are properly closed and expressions are valid"
        case .invalidExpression:
            return "Ensure expressions contain valid variable names separated by commas"
        case .invalidVariableName:
            return "Variable names must contain only letters, digits, underscores, and percent-encoded characters"
        case .invalidModifier:
            return "Modifiers must be either a prefix (:n) or explode (*)"
        case .expansionFailed:
            return "Verify all required variables are provided"
        case .matchingFailed:
            return "Ensure the URI matches the template pattern"
        }
    }
}
