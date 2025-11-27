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

// MARK: - Conformances

// MARK: - Convenience Initializers
