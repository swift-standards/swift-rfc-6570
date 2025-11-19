// Test specific edge cases mentioned in RFC 6570

import Testing
@testable import RFC_6570

@Suite
struct `Additional RFC 6570 Compliance Tests` {

    // Test that prefix modifier doesn't apply to composite values
    @Test
    func `Prefix modifier should not apply to lists`() throws {
        // Per RFC: prefix modifier not applicable to composite values
        // The implementation should either ignore it or the parser should reject it
        // Let's test if parser accepts it (which is fine - it just won't apply)
        let template = try RFC_6570.Template("{list:3}")
        let result = try template.expand(variables: [
            "list": .list(["red", "green", "blue"])
        ])
        // Prefix should not truncate the list, entire list should be output
        #expect(result.value == "red,green,blue")
    }

    // Test max-length validation (should be 1-4 digits per RFC)
    @Test
    func `Prefix modifier can have up to 4 digits`() throws {
        let template = try RFC_6570.Template("{var:9999}")
        let result = try template.expand(variables: ["var": "test"])
        #expect(result.value == "test")
    }

    // Test that both modifiers cannot be combined
    @Test
    func `Cannot combine prefix and explode modifiers`() {
        // RFC doesn't explicitly forbid this, but {var:3*} doesn't make sense
        // Let's see what the parser does
        #expect(throws: RFC_6570.Error.self) {
            try RFC_6570.Template("{var:3*}")
        }
    }

    // Test reserved character set completeness
    @Test
    func `All reserved characters in fragment expansion`() throws {
        let template = try RFC_6570.Template("{#var}")
        let reserved = ":/?#[]@!$&'()*+,;="
        let result = try template.expand(variables: ["var": .string(reserved)])
        #expect(result.value == "#:/?#[]@!$&'()*+,;=")
    }

    // Test that variable values remain static
    @Test
    func `Multiple uses of same variable`() throws {
        let template = try RFC_6570.Template("{var}{var}{var}")
        let result = try template.expand(variables: ["var": "test"])
        #expect(result.value == "testtesttest")
    }

    // Test comma in varspec list
    @Test
    func `Multiple variables in one expression`() throws {
        let template = try RFC_6570.Template("{?a,b,c}")
        let result = try template.expand(variables: [
            "a": "1",
            "b": "2",
            "c": "3"
        ])
        #expect(result.value == "?a=1&b=2&c=3")
    }

    // Test that literal text is preserved
    @Test
    func `Literal text between expressions`() throws {
        let template = try RFC_6570.Template("http://example.com{/path}{?query}")
        let result = try template.expand(variables: [
            "path": "users",
            "query": "active"
        ])
        #expect(result.value == "http://example.com/users?query=active")
    }

    // Test semicolon operator behavior with lists
    @Test
    func `Semicolon operator with list explode`() throws {
        let template = try RFC_6570.Template("{;list*}")
        let result = try template.expand(variables: [
            "list": .list(["a", "b", "c"])
        ])
        #expect(result.value == ";list=a;list=b;list=c")
    }

    // Test that pct-encoded characters in variable names work
    @Test
    func `Percent-encoded variable names`() throws {
        let template = try RFC_6570.Template("{var%20name}")
        let result = try template.expand(variables: ["var%20name": "value"])
        #expect(result.value == "value")
    }

    // Test case sensitivity of variable names
    @Test
    func `Variable names are case-sensitive`() throws {
        let template = try RFC_6570.Template("{Var}{var}{VAR}")
        let result = try template.expand(variables: [
            "Var": "A",
            "var": "B",
            "VAR": "C"
        ])
        #expect(result.value == "ABC")
    }
}
