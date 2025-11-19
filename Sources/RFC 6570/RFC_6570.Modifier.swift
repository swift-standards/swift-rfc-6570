//
//  File.swift
//  swift-rfc-6570
//
//  Created by Coen ten Thije Boonkkamp on 19/11/2025.
//

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
