import Foundation

// MARK: - Template Parsing

extension RFC_6570.Template {
    /// Parses a template string into components
    /// - Parameter template: The template string to parse
    /// - Returns: Array of template components (literals and expressions)
    /// - Throws: `RFC_6570.Error` if the template is invalid
    internal static func parse(_ template: String) throws -> [Component] {
        var components: [Component] = []
        var currentLiteral = ""
        var index = template.startIndex

        while index < template.endIndex {
            let char = template[index]

            if char == "{" {
                // Save any accumulated literal
                if !currentLiteral.isEmpty {
                    components.append(.literal(currentLiteral))
                    currentLiteral = ""
                }

                // Find matching closing brace
                guard let closingIndex = template[index...].firstIndex(of: "}") else {
                    throw RFC_6570.Error.invalidTemplate("Unclosed expression starting at position \(template.distance(from: template.startIndex, to: index))")
                }

                // Parse expression
                let exprStart = template.index(after: index)
                let exprString = String(template[exprStart..<closingIndex])
                let expression = try parseExpression(exprString)
                components.append(.expression(expression))

                index = template.index(after: closingIndex)
            } else if char == "}" {
                throw RFC_6570.Error.invalidTemplate("Unexpected '}' at position \(template.distance(from: template.startIndex, to: index))")
            } else {
                currentLiteral.append(char)
                index = template.index(after: index)
            }
        }

        // Save any remaining literal
        if !currentLiteral.isEmpty {
            components.append(.literal(currentLiteral))
        }

        return components
    }

    /// Parses an expression string (content between { and })
    /// - Parameter expression: The expression string (without braces)
    /// - Returns: Parsed expression
    /// - Throws: `RFC_6570.Error` if the expression is invalid
    private static func parseExpression(_ expression: String) throws -> Expression {
        guard !expression.isEmpty else {
            throw RFC_6570.Error.invalidExpression("Empty expression")
        }

        var remaining = expression

        // Check for operator prefix
        let op: RFC_6570.Operator
        if let first = remaining.first,
           let foundOperator = RFC_6570.Operator(rawValue: String(first)) {
            op = foundOperator
            remaining.removeFirst()
        } else {
            op = .simple
        }

        // Parse variable specifications
        let varspecStrings = remaining.split(separator: ",")
        guard !varspecStrings.isEmpty else {
            throw RFC_6570.Error.invalidExpression("No variables in expression")
        }

        let varspecs = try varspecStrings.map { try parseVarSpec(String($0)) }

        return Expression(op: op, varspecs: varspecs)
    }

    /// Parses a variable specification
    /// - Parameter varspec: The variable specification string
    /// - Returns: Parsed variable specification
    /// - Throws: `RFC_6570.Error` if the specification is invalid
    private static func parseVarSpec(_ varspec: String) throws -> VarSpec {
        guard !varspec.isEmpty else {
            throw RFC_6570.Error.invalidVariableName("Empty variable name")
        }

        var name = varspec
        var modifier: RFC_6570.Modifier? = nil

        // Check for explode modifier
        if name.hasSuffix("*") {
            modifier = .explode
            name.removeLast()
        }
        // Check for prefix modifier
        else if let colonIndex = name.firstIndex(of: ":") {
            let prefixString = name[name.index(after: colonIndex)...]
            // RFC 6570 Section 2.4.1: max-length is 1 to 4 digits (max value 9999)
            guard prefixString.count >= 1 && prefixString.count <= 4,
                  let prefixLength = Int(prefixString),
                  prefixLength > 0 else {
                throw RFC_6570.Error.invalidModifier("Invalid prefix length: \(prefixString)")
            }
            modifier = .prefix(prefixLength)
            name = String(name[..<colonIndex])
        }

        // Validate variable name (RFC 6570 Section 2.3: varchar)
        guard isValidVariableName(name) else {
            throw RFC_6570.Error.invalidVariableName("Invalid variable name: \(name)")
        }

        return VarSpec(name: name, modifier: modifier)
    }

    /// Validates a variable name according to RFC 6570 Section 2.3
    /// varchar = ( ALPHA / DIGIT / "_" / pct-encoded )
    /// - Parameter name: The variable name to validate
    /// - Returns: Whether the name is valid
    private static func isValidVariableName(_ name: String) -> Bool {
        guard !name.isEmpty else { return false }

        for char in name {
            if char.isLetter || char.isNumber || char == "_" || char == "." {
                continue
            } else if char == "%" {
                // Could validate percent-encoding here if needed
                continue
            } else {
                return false
            }
        }

        return true
    }
}
