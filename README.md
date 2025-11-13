# swift-rfc-6570

[![CI](https://github.com/swift-standards/swift-rfc-6570/workflows/CI/badge.svg)](https://github.com/swift-standards/swift-rfc-6570/actions)
![Development Status](https://img.shields.io/badge/status-active--development-blue.svg)
![Swift 6.0](https://img.shields.io/badge/Swift-6.0-orange.svg)
![Platforms](https://img.shields.io/badge/platforms-macOS%20%7C%20iOS-lightgrey.svg)

Swift implementation of [RFC 6570: URI Template](https://www.rfc-editor.org/rfc/rfc6570.html)

## Overview

RFC 6570 defines a simple notation for describing the structure of URIs that includes template variables. URI Templates allow for the definition of URI patterns with embedded variables to be expanded according to specific rules for each template operator.

This implementation provides:
- ✅ Full template parsing and validation
- ✅ Variable expansion (all levels 1-4)
- ✅ All eight operators (`{}`, `{+}`, `{#}`, `{.}`, `{/}`, `{;}`, `{?}`, `{&}`)
- ✅ List and associative array support
- ✅ Modifiers (prefix `:n` and explode `*`)
- ✅ Swift 6 strict concurrency support
- ✅ Full Sendable conformance
- ✅ Comprehensive test coverage (89 tests, 106 RFC examples)
- ✅ RFC compliance: 95% (Grade A-)
- ✅ Convenient Swift API with Foundation URL integration
- 🚧 Template matching (reverse operation for routing) - In development

## Installation

### Swift Package Manager

```swift
dependencies: [
    .package(url: "https://github.com/swift-standards/swift-rfc-6570.git", from: "0.1.0")
]
```

## Usage

### Basic Template Expansion

```swift
import RFC_6570

let template = try RFC_6570.Template("/users/{id}/posts")
let uri = try template.expand(variables: ["id": "123"])
// Result: "/users/123/posts"
```

### Convenience String Expansion

For simple string-only variables, use the convenient overload:

```swift
let template = try RFC_6570.Template("/users/{id}/posts/{postId}")
let uri = try template.expand(["id": "123", "postId": "456"])
// Result: "/users/123/posts/456"
```

### Expand to URL

Create a Foundation `URL` directly using initializer extensions:

```swift
// Create URL from template string
let url = try URL(template: "https://api.example.com/users/{id}", variables: ["id": "123"])
// Result: URL("https://api.example.com/users/123")

// Or expand an existing template to URL
let template = try RFC_6570.Template("https://api.example.com/users/{id}")
let url = try URL(template: template, variables: ["id": "123"])
```

### Query Parameters

```swift
let template = try RFC_6570.Template("/search{?q,page,limit}")
let uri = try template.expand(variables: [
    "q": "swift",
    "page": "1",
    "limit": "50"
])
// Result: "/search?q=swift&page=1&limit=50"
```

### List Values

```swift
let template = try RFC_6570.Template("/tags/{tags*}")
let uri = try template.expand(variables: [
    "tags": .list(["swift", "ios", "macos"])
])
// Result: "/tags/swift/ios/macos"
```

### Dictionary Values

```swift
let template = try RFC_6570.Template("/search{?filters*}")
let uri = try template.expand(variables: [
    "filters": .dictionary(["lang": "en", "sort": "date"])
])
// Result: "/search?lang=en&sort=date"
```

### All Operators

```swift
// Simple expansion
"{var}" → "value"

// Reserved expansion (allows :/?#[]@!$&'()*+,;=)
"{+var}" → "value"

// Fragment expansion
"{#var}" → "#value"

// Label expansion with dot-prefix
"{.var}" → ".value"

// Path segment expansion
"{/var}" → "/value"

// Path-style parameter expansion
"{;var}" → ";var=value"

// Query expansion
"{?var}" → "?var=value"

// Query continuation
"{&var}" → "&var=value"
```

### Modifiers

```swift
// Prefix modifier (limit to n characters)
let template = try Template("{var:3}")
let uri = try template.expand(variables: ["var": "value"])
// Result: "val"

// Explode modifier (expand lists/dicts separately)
let template = try Template("{?list*}")
let uri = try template.expand(variables: ["list": .list(["a", "b", "c"])])
// Result: "?list=a&list=b&list=c"
```

## RFC Compliance

This implementation conforms to RFC 6570 with the following status:

- ✅ **Level 1**: Simple string expansion
- ✅ **Level 2**: Reserved string expansion
- ✅ **Level 3**: Multiple operators (fragment, label, path)
- ✅ **Level 4**: All operators with value modifiers

### Implemented Sections

- ✅ Section 2: Syntax (template parsing)
- ✅ Section 3: Expansion (all operators and modifiers)
- 🚧 Template Matching (reverse operation - not defined in RFC, custom extension)

### Known Limitations

- Template matching is heuristic-based as the RFC only defines expansion, not matching
- Some ambiguous template patterns may not match reliably without type hints

## Development Status

This package is under active development as part of the [swift-standards](https://github.com/swift-standards) project.

## Related RFCs

- [RFC 3986](https://www.rfc-editor.org/rfc/rfc3986.html) - URI Generic Syntax (dependency)
- [RFC 6570](https://www.rfc-editor.org/rfc/rfc6570.html) - URI Template (this implementation)

## License

Apache License 2.0

## Contributing

Contributions are welcome! Please see [CONTRIBUTING.md](CONTRIBUTING.md) for guidelines.
