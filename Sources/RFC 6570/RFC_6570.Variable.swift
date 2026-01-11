//
//  File.swift
//  swift-rfc-6570
//
//  Created by Coen ten Thije Boonkkamp on 19/11/2025.
//

extension RFC_6570 {
    /// A value that can be used in template expansion
    public enum Variable: Hashable, Sendable {
        /// A simple string value
        case string(String)

        /// A list of string values
        case list([String])

        /// An associative array (dictionary) of string key-value pairs
        /// Note: Uses OrderedDictionary to preserve insertion order for RFC test compatibility
        case dictionary(Dictionary<String, String>.Ordered)

        /// Returns whether this value is defined per RFC 6570
        ///
        /// Note: Empty strings ARE defined. Only missing/nil values are undefined.
        /// Empty lists and dictionaries are treated as undefined.
        var isDefined: Bool {
            switch self {
            case .string: return true  // Empty strings are defined!
            case .list(let l): return !l.isEmpty
            case .dictionary(let d): return !d.isEmpty
            }
        }
    }
}

extension RFC_6570.Variable {
    /// Creates a dictionary value from a Swift Dictionary
    /// - Parameter dict: The dictionary to convert
    /// - Note: Keys will be sorted alphabetically for consistent output
    public init(dictionary: [String: String]) {
        let ordered = try! Dictionary<String, String>.Ordered( dictionary.sorted { $0.key < $1.key })
        self = .dictionary(ordered)
    }
}

extension RFC_6570.Variable: ExpressibleByStringLiteral {
    public init(stringLiteral value: String) {
        self = .string(value)
    }
}

extension RFC_6570.Variable: ExpressibleByArrayLiteral {
    public init(arrayLiteral elements: String...) {
        self = .list(elements)
    }
}

extension RFC_6570.Variable: ExpressibleByDictionaryLiteral {
    public init(dictionaryLiteral elements: (String, String)...) {
        self = .dictionary(try! Dictionary<String, String>.Ordered( elements))
    }
}

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
        case .dictionary(let d):
            return Dictionary(uniqueKeysWithValues: d.map { ($0.key, $0.value) })
        default: return nil
        }
    }
}
