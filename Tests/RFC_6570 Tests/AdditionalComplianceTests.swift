// Test specific edge cases mentioned in RFC 6570

import Testing
import Foundation
@testable import RFC_6570

@Suite("Additional RFC 6570 Compliance Tests")
struct AdditionalComplianceTests {

    // Test that prefix modifier doesn't apply to composite values
    @Test("Prefix modifier should not apply to lists")
    func testPrefixNotApplicableToList() throws {
        // Per RFC: prefix modifier not applicable to composite values
        // The implementation should either ignore it or the parser should reject it
        // Let's test if parser accepts it (which is fine - it just won't apply)
        let template = try RFC_6570.Template("{list:3}")
        let result = try template.expand(variables: [
            "list": .list(["red", "green", "blue"])
        ])
        // Prefix should not truncate the list, entire list should be output
        #expect(result == "red,green,blue")
    }

    // Test max-length validation (should be 1-4 digits per RFC)
    @Test("Prefix modifier can have up to 4 digits")
    func testPrefixMaxDigits() throws {
        let template = try RFC_6570.Template("{var:9999}")
        let result = try template.expand(variables: ["var": "test"])
        #expect(result == "test")
    }

    // Test that both modifiers cannot be combined
    @Test("Cannot combine prefix and explode modifiers")
    func testCannotCombineModifiers() {
        // RFC doesn't explicitly forbid this, but {var:3*} doesn't make sense
        // Let's see what the parser does
        #expect(throws: RFC_6570.Error.self) {
            try RFC_6570.Template("{var:3*}")
        }
    }

    // Test reserved character set completeness
    @Test("All reserved characters in fragment expansion")
    func testAllReservedChars() throws {
        let template = try RFC_6570.Template("{#var}")
        let reserved = ":/?#[]@!$&'()*+,;="
        let result = try template.expand(variables: ["var": .string(reserved)])
        #expect(result == "#:/?#[]@!$&'()*+,;=")
    }

    // Test that variable values remain static
    @Test("Multiple uses of same variable")
    func testVariableValueConsistency() throws {
        let template = try RFC_6570.Template("{var}{var}{var}")
        let result = try template.expand(variables: ["var": "test"])
        #expect(result == "testtesttest")
    }

    // Test comma in varspec list
    @Test("Multiple variables in one expression")
    func testMultipleVarsInExpression() throws {
        let template = try RFC_6570.Template("{?a,b,c}")
        let result = try template.expand(variables: [
            "a": "1",
            "b": "2",
            "c": "3"
        ])
        #expect(result == "?a=1&b=2&c=3")
    }

    // Test that literal text is preserved
    @Test("Literal text between expressions")
    func testLiteralPreservation() throws {
        let template = try RFC_6570.Template("http://example.com{/path}{?query}")
        let result = try template.expand(variables: [
            "path": "users",
            "query": "active"
        ])
        #expect(result == "http://example.com/users?query=active")
    }

    // Test semicolon operator behavior with lists
    @Test("Semicolon operator with list explode")
    func testSemicolonListExplode() throws {
        let template = try RFC_6570.Template("{;list*}")
        let result = try template.expand(variables: [
            "list": .list(["a", "b", "c"])
        ])
        #expect(result == ";list=a;list=b;list=c")
    }

    // Test that pct-encoded characters in variable names work
    @Test("Percent-encoded variable names")
    func testPercentEncodedVarName() throws {
        let template = try RFC_6570.Template("{var%20name}")
        let result = try template.expand(variables: ["var%20name": "value"])
        #expect(result == "value")
    }

    // Test case sensitivity of variable names
    @Test("Variable names are case-sensitive")
    func testCaseSensitiveVarNames() throws {
        let template = try RFC_6570.Template("{Var}{var}{VAR}")
        let result = try template.expand(variables: [
            "Var": "A",
            "var": "B",
            "VAR": "C"
        ])
        #expect(result == "ABC")
    }
}
