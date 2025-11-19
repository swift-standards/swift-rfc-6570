//
//  File.swift
//  swift-rfc-6570
//
//  Created by Coen ten Thije Boonkkamp on 19/11/2025.
//

import Foundation

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
    public init(template: String, variables: [String: RFC_6570.Variable]) throws {
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
    public init(template: RFC_6570.Template, variables: [String: RFC_6570.Variable]) throws {
        let uri = try template.expand(variables: variables)
        guard let url = URL(string: uri.value) else {
            throw RFC_6570.Error.expansionFailed("Result is not a valid URL: \(uri.value)")
        }
        self = url
    }
}
