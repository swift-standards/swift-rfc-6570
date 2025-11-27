import Testing

@testable import RFC_6570

@Suite
struct `RFC 6570 Edge Cases and Compliance Tests` {

    // MARK: - Character Encoding Tests

    @Test
    func `Percent character must be encoded as %25`() throws {
        let template = try RFC_6570.Template("{var}")
        let result = try template.expand(variables: ["var": "50%"])
        #expect(result.value == "50%25")
    }

    @Test
    func `Percent character in reserved expansion`() throws {
        let template = try RFC_6570.Template("{+var}")
        let result = try template.expand(variables: ["var": "50%"])
        #expect(result.value == "50%25")
    }

    @Test
    func `Space must be encoded as %20`() throws {
        let templateNormal = try RFC_6570.Template("{var}")
        let templateReserved = try RFC_6570.Template("{+var}")

        let resultNormal = try templateNormal.expand(variables: ["var": "hello world"])
        let resultReserved = try templateReserved.expand(variables: ["var": "hello world"])

        #expect(resultNormal.value == "hello%20world")
        #expect(resultReserved.value == "hello%20world")
    }

    @Test
    func `Unreserved characters pass through unencoded`() throws {
        let template = try RFC_6570.Template("{var}")
        let unreserved = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789-._~"
        let result = try template.expand(["var": unreserved])
        #expect(result.value == unreserved)
    }

    @Test
    func `Reserved characters encoded in normal expansion`() throws {
        let template = try RFC_6570.Template("{var}")
        let result = try template.expand(variables: ["var": ":/?#[]@!$&'()*+,;="])
        // All these should be percent-encoded
        #expect(result.value.contains("%"))
    }

    @Test
    func `Reserved characters allowed in reserved expansion`() throws {
        let template = try RFC_6570.Template("{+var}")
        let reserved = ":/?#[]@!$&'()*+,;="
        let result = try template.expand(["var": reserved])
        // These should NOT be encoded in reserved expansion (except space if present)
        #expect(result.value == reserved)
    }

    @Test
    func `Exclamation mark in reserved expansion`() throws {
        let templateNormal = try RFC_6570.Template("{var}")
        let templateReserved = try RFC_6570.Template("{+var}")

        let resultNormal = try templateNormal.expand(variables: ["var": "Hello!"])
        let resultReserved = try templateReserved.expand(variables: ["var": "Hello!"])

        #expect(resultNormal.value == "Hello%21")
        #expect(resultReserved.value == "Hello!")
    }

    // MARK: - Prefix Modifier Tests

    @Test
    func `Prefix modifier counts Unicode code points, not bytes`() throws {
        let template = try RFC_6570.Template("{var:3}")

        // ASCII characters
        let resultAscii = try template.expand(variables: ["var": "Hello"])
        #expect(resultAscii.value == "Hel")

        // Unicode characters (each is one code point)
        let resultUnicode = try template.expand(variables: ["var": "你好世界"])
        #expect(resultUnicode.value == "%E4%BD%A0%E5%A5%BD%E4%B8%96")
    }

    @Test
    func `Prefix modifier larger than string length`() throws {
        let template = try RFC_6570.Template("{var:100}")
        let result = try template.expand(variables: ["var": "short"])
        #expect(result.value == "short")
    }

    // MARK: - Undefined Value Tests

    @Test
    func `Empty string is defined per RFC 6570`() throws {
        let template = try RFC_6570.Template("{?var}")
        let result = try template.expand(variables: ["var": ""])
        #expect(result.value == "?var=")
    }

    @Test
    func `Empty list is undefined`() throws {
        let template = try RFC_6570.Template("{?list}")
        let result = try template.expand(variables: ["list": .list([])])
        #expect(result.value == "")
    }

    @Test
    func `Empty dictionary is undefined`() throws {
        let template = try RFC_6570.Template("{?dict}")
        let result = try template.expand(variables: ["dict": .dictionary([:])])
        #expect(result.value == "")
    }

    @Test
    func `Missing variable is undefined`() throws {
        let template = try RFC_6570.Template("{?var}")
        let result = try template.expand(variables: [:])
        #expect(result.value == "")
    }

    // MARK: - Template Parsing Error Tests

    @Test
    func `Unclosed brace throws error`() {
        #expect(throws: RFC_6570.Error.self) {
            try RFC_6570.Template("{var")
        }
    }

    @Test
    func `Unexpected closing brace throws error`() {
        #expect(throws: RFC_6570.Error.self) {
            try RFC_6570.Template("test}")
        }
    }

    @Test
    func `Empty expression throws error`() {
        #expect(throws: RFC_6570.Error.self) {
            try RFC_6570.Template("{}")
        }
    }

    // MARK: - Variable Name Validation Tests

    @Test
    func `Variable name with underscore is valid`() throws {
        let template = try RFC_6570.Template("{var_name}")
        let result = try template.expand(variables: ["var_name": "test"])
        #expect(result.value == "test")
    }

    @Test
    func `Variable name with dot is valid`() throws {
        let template = try RFC_6570.Template("{var.name}")
        let result = try template.expand(variables: ["var.name": "test"])
        #expect(result.value == "test")
    }

    @Test
    func `Variable name with percent-encoding is valid`() throws {
        // RFC 6570 Section 2.3: variable names MAY contain pct-encoded characters
        let template = try RFC_6570.Template("{var%20name}")
        let result = try template.expand(variables: ["var%20name": "test"])
        #expect(result.value == "test")
    }

    @Test
    func `Variable name with hyphen is invalid`() {
        #expect(throws: RFC_6570.Error.self) {
            try RFC_6570.Template("{var-name}")
        }
    }

    // MARK: - Modifier Validation Tests

    @Test
    func `Zero-length prefix is invalid`() {
        #expect(throws: RFC_6570.Error.self) {
            try RFC_6570.Template("{var:0}")
        }
    }

    @Test
    func `Non-numeric prefix is invalid`() {
        #expect(throws: RFC_6570.Error.self) {
            try RFC_6570.Template("{var:abc}")
        }
    }

    @Test
    func `Negative prefix is invalid`() {
        #expect(throws: RFC_6570.Error.self) {
            try RFC_6570.Template("{var:-5}")
        }
    }

    // MARK: - Operator Combination Tests

    @Test
    func `Multiple undefined variables in expression`() throws {
        let template = try RFC_6570.Template("{?x,y,z}")
        let result = try template.expand(variables: ["y": "2"])
        #expect(result.value == "?y=2")
    }

    @Test
    func `All undefined variables produce empty result`() throws {
        let template = try RFC_6570.Template("{?x,y,z}")
        let result = try template.expand(variables: [:])
        #expect(result.value == "")
    }

    @Test
    func `Fragment operator with empty value`() throws {
        let template = try RFC_6570.Template("{#var}")
        let result = try template.expand(variables: ["var": ""])
        #expect(result.value == "#")
    }

    // MARK: - List and Dictionary Edge Cases

    @Test
    func `List with empty string elements`() throws {
        let template = try RFC_6570.Template("{list}")
        let result = try template.expand(variables: ["list": .list(["a", "", "c"])])
        #expect(result.value == "a,,c")
    }

    @Test
    func `Dictionary with empty values`() throws {
        let template = try RFC_6570.Template("{?keys*}")
        let result = try template.expand(variables: [
            "keys": .dictionary(["a": "1", "b": "", "c": "3"])
        ])
        // Should handle empty values in dictionary
        #expect(result.value.contains("b="))
    }

    @Test
    func `List explode with path operator`() throws {
        let template = try RFC_6570.Template("{/list*}")
        let result = try template.expand(variables: ["list": .list(["a", "b", "c"])])
        #expect(result.value == "/a/b/c")
    }

    // MARK: - Special Character Combinations

    @Test
    func `Slash in path segment is encoded`() throws {
        let template = try RFC_6570.Template("{/var}")
        let result = try template.expand(variables: ["var": "a/b"])
        #expect(result.value == "/a%2Fb")
    }

    @Test
    func `Equals in query value is encoded`() throws {
        let template = try RFC_6570.Template("{?var}")
        let result = try template.expand(variables: ["var": "a=b"])
        #expect(result.value == "?var=a%3Db")
    }

    @Test
    func `Ampersand in query value is encoded`() throws {
        let template = try RFC_6570.Template("{?var}")
        let result = try template.expand(variables: ["var": "a&b"])
        #expect(result.value == "?var=a%26b")
    }

    // MARK: - Multiple Expressions in One Template

    @Test
    func `Multiple expressions with different operators`() throws {
        let template = try RFC_6570.Template("{/path}{?query}{#fragment}")
        let result = try template.expand(variables: [
            "path": "search",
            "query": "test",
            "fragment": "section",
        ])
        #expect(result.value == "/search?query=test#section")
    }

    @Test
    func `Adjacent expressions`() throws {
        let template = try RFC_6570.Template("{var1}{var2}")
        let result = try template.expand(variables: [
            "var1": "hello",
            "var2": "world",
        ])
        #expect(result.value == "helloworld")
    }
}
