//
//  File.swift
//  swift-rfc-6570
//
//  Created by Coen ten Thije Boonkkamp on 19/11/2025.
//

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
