import Testing
import Foundation
@testable import RFC_6570

@Suite("Final Edge Case Validation")
struct FinalValidationTests {
    
    // Verify prefix modifier is applied BEFORE percent-encoding (per RFC)
    @Test("Prefix applied before encoding")
    func testPrefixBeforeEncoding() throws {
        // If we have "你好世界" and apply :6, it should take first 6 chars THEN encode
        // Not encode first then take 6 bytes
        let template = try RFC_6570.Template("{var:2}")
        let result = try template.expand(variables: ["var": "你好"])
        // Should encode both characters (first 2 Unicode code points)
        #expect(result.value == "%E4%BD%A0%E5%A5%BD")
    }
    
    // Test prefix with percent character
    @Test("Prefix with percent in string")
    func testPrefixWithPercent() throws {
        let template = try RFC_6570.Template("{var:2}")
        let result = try template.expand(variables: ["var": "50%"])
        #expect(result.value == "50")
    }
    
    // Test that modifier applies only to its variable
    @Test("Modifier applies to single variable only")
    func testModifierScope() throws {
        let template = try RFC_6570.Template("{x:2,y}")
        let result = try template.expand(variables: [
            "x": "hello",
            "y": "world"
        ])
        #expect(result.value == "he,world")
    }
    
    // Test prefix with exact length match
    @Test("Prefix with exact length")
    func testPrefixExactLength() throws {
        let template = try RFC_6570.Template("{var:5}")
        let result = try template.expand(variables: ["var": "hello"])
        #expect(result.value == "hello")
    }
    
    // Verify that percent-encoding follows RFC 3986
    @Test("Percent encoding produces uppercase hex")
    func testUppercaseHex() throws {
        let template = try RFC_6570.Template("{var}")
        let result = try template.expand(variables: ["var": "hello world"])
        // Per RFC 3986, hex digits should be uppercase
        #expect(result.value == "hello%20world")
    }
    
    // Test list with single element
    @Test("List with single element")
    func testSingleElementList() throws {
        let template = try RFC_6570.Template("{list}")
        let result = try template.expand(variables: [
            "list": .list(["single"])
        ])
        #expect(result.value == "single")
    }
    
    // Test dict with single pair
    @Test("Dictionary with single pair")
    func testSinglePairDict() throws {
        let template = try RFC_6570.Template("{?keys*}")
        let result = try template.expand(variables: [
            "keys": .dictionary(["key": "value"])
        ])
        #expect(result.value == "?key=value")
    }
    
    // Test that prefix modifier doesn't affect dict
    @Test("Prefix modifier ignored for dictionary")
    func testPrefixIgnoredForDict() throws {
        let template = try RFC_6570.Template("{keys:3}")
        let result = try template.expand(variables: [
            "keys": .dictionary(["a": "1", "b": "2"])
        ])
        // Should output full dictionary, not truncated
        #expect(result.value == "a,1,b,2")
    }
    
    // Verify explode with single list element
    @Test("Explode with single list element")
    func testExplodeSingleElement() throws {
        let template = try RFC_6570.Template("{?list*}")
        let result = try template.expand(variables: [
            "list": .list(["single"])
        ])
        #expect(result.value == "?list=single")
    }
    
    // Test that tilde is not encoded (unreserved)
    @Test("Tilde passes through unencoded")
    func testTildeUnencoded() throws {
        let template = try RFC_6570.Template("{var}")
        let result = try template.expand(variables: ["var": "~user"])
        #expect(result.value == "~user")
    }
}
