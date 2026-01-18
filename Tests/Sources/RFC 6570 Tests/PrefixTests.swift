import Testing

@testable import RFC_6570

@Suite
struct `Prefix Modifier Deep Dive` {

    // RFC 6570 Section 2.4.1: "If the prefix value is a number, then...
    // the expansion is limited to the first max-length characters of the variable's value"
    // IMPORTANT: This means CHARACTER COUNT, not BYTE COUNT

    @Test
    func `Prefix counts characters correctly`() throws {
        let template = try RFC_6570.Template("{var:3}")

        // Test with ASCII
        var result = try template.expand(variables: ["var": "value"])
        #expect(result.value == "val")

        // Test with emoji (each emoji is 1 character)
        result = try template.expand(variables: ["var": "👨‍👩‍👧‍👦ABC"])
        // The family emoji is actually composed of multiple code points!
        // Swift's String.prefix counts extended grapheme clusters
        print("Emoji test result: \(result)")
    }

    // Test that prefix modifier max is 9999 per RFC (4 digits)
    @Test
    func `Prefix modifier supports up to 9999`() throws {
        let template = try RFC_6570.Template("{var:9999}")
        let result = try template.expand(variables: ["var": "test"])
        #expect(result.value == "test")
    }

    // Test invalid prefix values
    @Test
    func `Five-digit prefix should fail`() {
        // RFC says max-length is 1-4 digits
        #expect(throws: RFC_6570.Error.self) {
            try RFC_6570.Template("{var:10001}")
        }
    }
}
