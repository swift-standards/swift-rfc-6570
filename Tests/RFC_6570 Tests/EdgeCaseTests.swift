import Testing
import Foundation
@testable import RFC_6570

@Suite("RFC 6570 Edge Cases and Compliance Tests")
struct EdgeCaseTests {

    // MARK: - Character Encoding Tests

    @Test("Percent character must be encoded as %25")
    func testPercentEncoding() throws {
        let template = try RFC_6570.Template("{var}")
        let result = try template.expand(variables: ["var": "50%"])
        #expect(result.value == "50%25")
    }

    @Test("Percent character in reserved expansion")
    func testPercentInReserved() throws {
        let template = try RFC_6570.Template("{+var}")
        let result = try template.expand(variables: ["var": "50%"])
        #expect(result.value == "50%25")
    }

    @Test("Space must be encoded as %20")
    func testSpaceEncoding() throws {
        let templateNormal = try RFC_6570.Template("{var}")
        let templateReserved = try RFC_6570.Template("{+var}")

        let resultNormal = try templateNormal.expand(variables: ["var": "hello world"])
        let resultReserved = try templateReserved.expand(variables: ["var": "hello world"])

        #expect(resultNormal == "hello%20world")
        #expect(resultReserved == "hello%20world")
    }

    @Test("Unreserved characters pass through unencoded")
    func testUnreservedCharacters() throws {
        let template = try RFC_6570.Template("{var}")
        let unreserved = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789-._~"
        let result = try template.expand(["var": unreserved])
        #expect(result.value == unreserved)
    }

    @Test("Reserved characters encoded in normal expansion")
    func testReservedCharsNormalExpansion() throws {
        let template = try RFC_6570.Template("{var}")
        let result = try template.expand(variables: ["var": ":/?#[]@!$&'()*+,;="])
        // All these should be percent-encoded
        #expect(result.value.contains("%"))
    }

    @Test("Reserved characters allowed in reserved expansion")
    func testReservedCharsReservedExpansion() throws {
        let template = try RFC_6570.Template("{+var}")
        let reserved = ":/?#[]@!$&'()*+,;="
        let result = try template.expand(["var": reserved])
        // These should NOT be encoded in reserved expansion (except space if present)
        #expect(result.value == reserved)
    }

    @Test("Exclamation mark in reserved expansion")
    func testExclamationMark() throws {
        let templateNormal = try RFC_6570.Template("{var}")
        let templateReserved = try RFC_6570.Template("{+var}")

        let resultNormal = try templateNormal.expand(variables: ["var": "Hello!"])
        let resultReserved = try templateReserved.expand(variables: ["var": "Hello!"])

        #expect(resultNormal == "Hello%21")
        #expect(resultReserved == "Hello!")
    }

    // MARK: - Prefix Modifier Tests

    @Test("Prefix modifier counts Unicode code points, not bytes")
    func testPrefixUnicode() throws {
        let template = try RFC_6570.Template("{var:3}")

        // ASCII characters
        let resultAscii = try template.expand(variables: ["var": "Hello"])
        #expect(resultAscii == "Hel")

        // Unicode characters (each is one code point)
        let resultUnicode = try template.expand(variables: ["var": "你好世界"])
        #expect(resultUnicode == "%E4%BD%A0%E5%A5%BD%E4%B8%96")
    }

    @Test("Prefix modifier larger than string length")
    func testPrefixLargerThanString() throws {
        let template = try RFC_6570.Template("{var:100}")
        let result = try template.expand(variables: ["var": "short"])
        #expect(result.value == "short")
    }

    // MARK: - Undefined Value Tests

    @Test("Empty string is defined per RFC 6570")
    func testEmptyStringIsDefined() throws {
        let template = try RFC_6570.Template("{?var}")
        let result = try template.expand(variables: ["var": ""])
        #expect(result.value == "?var=")
    }

    @Test("Empty list is undefined")
    func testEmptyListUndefined() throws {
        let template = try RFC_6570.Template("{?list}")
        let result = try template.expand(variables: ["list": .list([])])
        #expect(result.value == "")
    }

    @Test("Empty dictionary is undefined")
    func testEmptyDictUndefined() throws {
        let template = try RFC_6570.Template("{?dict}")
        let result = try template.expand(variables: ["dict": .dictionary([:])])
        #expect(result.value == "")
    }

    @Test("Missing variable is undefined")
    func testMissingVariable() throws {
        let template = try RFC_6570.Template("{?var}")
        let result = try template.expand(variables: [:])
        #expect(result.value == "")
    }

    // MARK: - Template Parsing Error Tests

    @Test("Unclosed brace throws error")
    func testUnclosedBrace() {
        #expect(throws: RFC_6570.Error.self) {
            try RFC_6570.Template("{var")
        }
    }

    @Test("Unexpected closing brace throws error")
    func testUnexpectedClosingBrace() {
        #expect(throws: RFC_6570.Error.self) {
            try RFC_6570.Template("test}")
        }
    }

    @Test("Empty expression throws error")
    func testEmptyExpression() {
        #expect(throws: RFC_6570.Error.self) {
            try RFC_6570.Template("{}")
        }
    }

    // MARK: - Variable Name Validation Tests

    @Test("Variable name with underscore is valid")
    func testUnderscoreInVariableName() throws {
        let template = try RFC_6570.Template("{var_name}")
        let result = try template.expand(variables: ["var_name": "test"])
        #expect(result.value == "test")
    }

    @Test("Variable name with dot is valid")
    func testDotInVariableName() throws {
        let template = try RFC_6570.Template("{var.name}")
        let result = try template.expand(variables: ["var.name": "test"])
        #expect(result.value == "test")
    }

    @Test("Variable name with percent-encoding is valid")
    func testPercentEncodedVariableName() throws {
        // RFC 6570 Section 2.3: variable names MAY contain pct-encoded characters
        let template = try RFC_6570.Template("{var%20name}")
        let result = try template.expand(variables: ["var%20name": "test"])
        #expect(result.value == "test")
    }

    @Test("Variable name with hyphen is invalid")
    func testHyphenInVariableName() {
        #expect(throws: RFC_6570.Error.self) {
            try RFC_6570.Template("{var-name}")
        }
    }

    // MARK: - Modifier Validation Tests

    @Test("Zero-length prefix is invalid")
    func testZeroLengthPrefix() {
        #expect(throws: RFC_6570.Error.self) {
            try RFC_6570.Template("{var:0}")
        }
    }

    @Test("Non-numeric prefix is invalid")
    func testNonNumericPrefix() {
        #expect(throws: RFC_6570.Error.self) {
            try RFC_6570.Template("{var:abc}")
        }
    }

    @Test("Negative prefix is invalid")
    func testNegativePrefix() {
        #expect(throws: RFC_6570.Error.self) {
            try RFC_6570.Template("{var:-5}")
        }
    }

    // MARK: - Operator Combination Tests

    @Test("Multiple undefined variables in expression")
    func testMultipleUndefinedVars() throws {
        let template = try RFC_6570.Template("{?x,y,z}")
        let result = try template.expand(variables: ["y": "2"])
        #expect(result.value == "?y=2")
    }

    @Test("All undefined variables produce empty result")
    func testAllUndefinedVars() throws {
        let template = try RFC_6570.Template("{?x,y,z}")
        let result = try template.expand(variables: [:])
        #expect(result.value == "")
    }

    @Test("Fragment operator with empty value")
    func testFragmentWithEmpty() throws {
        let template = try RFC_6570.Template("{#var}")
        let result = try template.expand(variables: ["var": ""])
        #expect(result.value == "#")
    }

    // MARK: - List and Dictionary Edge Cases

    @Test("List with empty string elements")
    func testListWithEmptyElements() throws {
        let template = try RFC_6570.Template("{list}")
        let result = try template.expand(variables: ["list": .list(["a", "", "c"])])
        #expect(result.value == "a,,c")
    }

    @Test("Dictionary with empty values")
    func testDictWithEmptyValues() throws {
        let template = try RFC_6570.Template("{?keys*}")
        let result = try template.expand(variables: [
            "keys": .dictionary(["a": "1", "b": "", "c": "3"])
        ])
        // Should handle empty values in dictionary
        #expect(result.value.contains("b="))
    }

    @Test("List explode with path operator")
    func testListExplodeWithPath() throws {
        let template = try RFC_6570.Template("{/list*}")
        let result = try template.expand(variables: ["list": .list(["a", "b", "c"])])
        #expect(result.value == "/a/b/c")
    }

    // MARK: - Special Character Combinations

    @Test("Slash in path segment is encoded")
    func testSlashInPathSegment() throws {
        let template = try RFC_6570.Template("{/var}")
        let result = try template.expand(variables: ["var": "a/b"])
        #expect(result.value == "/a%2Fb")
    }

    @Test("Equals in query value is encoded")
    func testEqualsInQueryValue() throws {
        let template = try RFC_6570.Template("{?var}")
        let result = try template.expand(variables: ["var": "a=b"])
        #expect(result.value == "?var=a%3Db")
    }

    @Test("Ampersand in query value is encoded")
    func testAmpersandInQueryValue() throws {
        let template = try RFC_6570.Template("{?var}")
        let result = try template.expand(variables: ["var": "a&b"])
        #expect(result.value == "?var=a%26b")
    }

    // MARK: - Multiple Expressions in One Template

    @Test("Multiple expressions with different operators")
    func testMultipleExpressions() throws {
        let template = try RFC_6570.Template("{/path}{?query}{#fragment}")
        let result = try template.expand(variables: [
            "path": "search",
            "query": "test",
            "fragment": "section"
        ])
        #expect(result.value == "/search?query=test#section")
    }

    @Test("Adjacent expressions")
    func testAdjacentExpressions() throws {
        let template = try RFC_6570.Template("{var1}{var2}")
        let result = try template.expand(variables: [
            "var1": "hello",
            "var2": "world"
        ])
        #expect(result.value == "helloworld")
    }
}
