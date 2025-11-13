import Foundation
import RFC_3986
import OrderedCollections

// MARK: - Template Expansion

extension RFC_6570.Template {
    /// Expands the template with the given variables
    ///
    /// Returns a URI reference as defined by RFC 3986.
    /// Result may be an absolute URI or a relative reference depending on the template.
    ///
    /// Example:
    /// ```swift
    /// let template = try Template("/users/{id}/posts{?page,limit}")
    /// let uri = try template.expand(variables: [
    ///     "id": "123",
    ///     "page": "1",
    ///     "limit": "50"
    /// ])
    /// // Result: URI("/users/123/posts?page=1&limit=50")
    /// ```
    ///
    /// - Parameter variables: Dictionary mapping variable names to their values
    /// - Returns: The expanded URI reference
    /// - Throws: `RFC_6570.Error` if expansion fails
    public func expand(variables: [String: RFC_6570.VariableValue]) throws -> RFC_3986.URI {
        var result = ""

        for component in components {
            switch component {
            case .literal(let literal):
                result += literal

            case .expression(let expression):
                let expanded = try expandExpression(expression, variables: variables)
                result += expanded
            }
        }

        // RFC 6570 expansion always produces valid URI references (per RFC 3986 Section 4.1)
        // Use unchecked initializer for performance - our percent-encoding guarantees validity
        return RFC_3986.URI(unchecked: result)
    }

    /// Expands a single expression
    private func expandExpression(
        _ expression: Expression,
        variables: [String: RFC_6570.VariableValue]
    ) throws -> String {
        let op = expression.op
        var results: [String] = []

        for varspec in expression.varspecs {
            guard let value = variables[varspec.name], value.isDefined else {
                // Undefined variables are skipped per RFC 6570
                continue
            }

            let expanded = try expandVarSpec(varspec, value: value, operator: op)
            // Include all expansions, even empty ones (for comma-separated contexts)
            results.append(expanded)
        }

        guard !results.isEmpty else {
            return ""
        }

        // Join results with operator separator
        let joined = results.joined(separator: op.separator)

        // Add operator prefix
        return op.prefix + joined
    }

    /// Expands a single variable specification
    private func expandVarSpec(
        _ varspec: VarSpec,
        value: RFC_6570.VariableValue,
        operator op: RFC_6570.Operator
    ) throws -> String {
        switch value {
        case .string(let str):
            return try expandString(str, varspec: varspec, operator: op)

        case .list(let list):
            // Empty lists are still skipped
            guard !list.isEmpty else { return "" }
            return try expandList(list, varspec: varspec, operator: op)

        case .dictionary(let dict):
            // Empty dictionaries are still skipped
            guard !dict.isEmpty else { return "" }
            return try expandDictionary(dict, varspec: varspec, operator: op)
        }
    }

    /// Expands a string value
    private func expandString(
        _ string: String,
        varspec: VarSpec,
        operator op: RFC_6570.Operator
    ) throws -> String {
        var value = string

        // Apply prefix modifier if present
        if case .prefix(let length) = varspec.modifier {
            value = String(value.prefix(length))
        }

        // Encode the value
        let encoded = percentEncode(value, allowReserved: op.allowReserved)

        // Add variable name for named operators
        if op.named {
            // Different operators handle empty values differently:
            // - Semicolon operator (;): empty values produce just the name: "name"
            // - Query operators (?, &): empty values produce "name="
            if value.isEmpty && op == .parameter {
                // Semicolon operator: no "=" for empty values
                return varspec.name
            } else if value.isEmpty {
                // Query operators (query, continuation): include "=" for empty values
                return "\(varspec.name)="
            } else {
                // Non-empty values: always include "="
                return "\(varspec.name)=\(encoded)"
            }
        } else {
            // For non-named operators, return encoded value even if empty
            // This allows empty strings to contribute to comma-separated lists
            return encoded
        }
    }

    /// Expands a list value
    private func expandList(
        _ list: [String],
        varspec: VarSpec,
        operator op: RFC_6570.Operator
    ) throws -> String {
        guard !list.isEmpty else { return "" }

        let encoded = list.map { percentEncode($0, allowReserved: op.allowReserved) }

        if case .explode = varspec.modifier {
            // Explode modifier: expand each element separately
            if op.named {
                // Named format: var=a&var=b
                return encoded.map { "\(varspec.name)=\($0)" }.joined(separator: op.separator)
            } else {
                // Unnamed format: a,b or a.b depending on operator
                return encoded.joined(separator: op.separator)
            }
        } else {
            // No explode: comma-separated list
            let joined = encoded.joined(separator: ",")
            if op.named {
                return "\(varspec.name)=\(joined)"
            } else {
                return joined
            }
        }
    }

    /// Expands a dictionary value
    private func expandDictionary(
        _ dict: OrderedDictionary<String, String>,
        varspec: VarSpec,
        operator op: RFC_6570.Operator
    ) throws -> String {
        guard !dict.isEmpty else { return "" }

        // OrderedDictionary preserves insertion order
        if case .explode = varspec.modifier {
            // Explode modifier: key1=val1&key2=val2
            let pairs = dict.map { key, value in
                let encodedKey = percentEncode(key, allowReserved: op.allowReserved)
                let encodedValue = percentEncode(value, allowReserved: op.allowReserved)
                return "\(encodedKey)=\(encodedValue)"
            }
            return pairs.joined(separator: op.separator)
        } else {
            // No explode: comma-separated key,value pairs
            let pairs = dict.flatMap { key, value in
                let encodedKey = percentEncode(key, allowReserved: op.allowReserved)
                let encodedValue = percentEncode(value, allowReserved: op.allowReserved)
                return [encodedKey, encodedValue]
            }
            let joined = pairs.joined(separator: ",")

            if op.named {
                return "\(varspec.name)=\(joined)"
            } else {
                return joined
            }
        }
    }

    /// Percent-encodes a string according to RFC 6570 rules
    /// - Parameters:
    ///   - string: The string to encode
    ///   - allowReserved: Whether to allow reserved characters (for + and # operators)
    /// - Returns: Percent-encoded string
    private func percentEncode(_ string: String, allowReserved: Bool) -> String {
        if allowReserved {
            // For reserved expansion (+, #), allow unreserved + reserved characters
            // RFC 3986 unreserved: A-Z a-z 0-9 - . _ ~
            // RFC 3986 reserved: : / ? # [ ] @ ! $ & ' ( ) * + , ; =
            let allowed = CharacterSet(charactersIn: "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789-._~:/?#[]@!$&'()*+,;=")
            return string.addingPercentEncoding(withAllowedCharacters: allowed) ?? string
        } else {
            // For normal expansion, only allow unreserved characters
            let allowed = CharacterSet(charactersIn: "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789-._~")
            return string.addingPercentEncoding(withAllowedCharacters: allowed) ?? string
        }
    }
}
