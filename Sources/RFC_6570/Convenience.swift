import RFC_3986

// MARK: - Swift Convenience Extensions

extension RFC_6570.Template {
    /// Expands the template with string values
    ///
    /// Convenience method that automatically wraps strings in Variable
    /// and returns a URI reference.
    ///
    /// Example:
    /// ```swift
    /// let template = try Template("/users/{id}")
    /// let uri = try template.expand(["id": "123"])
    /// // Returns: RFC_3986.URI("/users/123")
    /// ```
    public func expand(_ variables: [String: String]) throws -> RFC_3986.URI {
        let wrapped = variables.mapValues { RFC_6570.Variable.string($0) }
        return try expand(variables: wrapped)
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

extension RFC_6570.Variable {
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
