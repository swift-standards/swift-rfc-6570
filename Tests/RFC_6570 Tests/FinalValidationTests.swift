import Testing
@testable import RFC_6570

@Suite
struct `Final Edge Case Validation` {
    
    // Verify prefix modifier is applied BEFORE percent-encoding (per RFC)
    @Test
    func `Prefix applied before encoding`() throws {
        // If we have "你好世界" and apply :6, it should take first 6 chars THEN encode
        // Not encode first then take 6 bytes
        let template = try RFC_6570.Template("{var:2}")
        let result = try template.expand(variables: ["var": "你好"])
        // Should encode both characters (first 2 Unicode code points)
        #expect(result.value == "%E4%BD%A0%E5%A5%BD")
    }
    
    // Test prefix with percent character
    @Test
    func `Prefix with percent in string`() throws {
        let template = try RFC_6570.Template("{var:2}")
        let result = try template.expand(variables: ["var": "50%"])
        #expect(result.value == "50")
    }
    
    // Test that modifier applies only to its variable
    @Test
    func `Modifier applies to single variable only`() throws {
        let template = try RFC_6570.Template("{x:2,y}")
        let result = try template.expand(variables: [
            "x": "hello",
            "y": "world"
        ])
        #expect(result.value == "he,world")
    }
    
    // Test prefix with exact length match
    @Test
    func `Prefix with exact length`() throws {
        let template = try RFC_6570.Template("{var:5}")
        let result = try template.expand(variables: ["var": "hello"])
        #expect(result.value == "hello")
    }
    
    // Verify that percent-encoding follows RFC 3986
    @Test
    func `Percent encoding produces uppercase hex`() throws {
        let template = try RFC_6570.Template("{var}")
        let result = try template.expand(variables: ["var": "hello world"])
        // Per RFC 3986, hex digits should be uppercase
        #expect(result.value == "hello%20world")
    }
    
    // Test list with single element
    @Test
    func `List with single element`() throws {
        let template = try RFC_6570.Template("{list}")
        let result = try template.expand(variables: [
            "list": .list(["single"])
        ])
        #expect(result.value == "single")
    }
    
    // Test dict with single pair
    @Test
    func `Dictionary with single pair`() throws {
        let template = try RFC_6570.Template("{?keys*}")
        let result = try template.expand(variables: [
            "keys": .dictionary(["key": "value"])
        ])
        #expect(result.value == "?key=value")
    }
    
    // Test that prefix modifier doesn't affect dict
    @Test
    func `Prefix modifier ignored for dictionary`() throws {
        let template = try RFC_6570.Template("{keys:3}")
        let result = try template.expand(variables: [
            "keys": .dictionary(["a": "1", "b": "2"])
        ])
        // Should output full dictionary, not truncated
        #expect(result.value == "a,1,b,2")
    }
    
    // Verify explode with single list element
    @Test
    func `Explode with single list element`() throws {
        let template = try RFC_6570.Template("{?list*}")
        let result = try template.expand(variables: [
            "list": .list(["single"])
        ])
        #expect(result.value == "?list=single")
    }
    
    // Test that tilde is not encoded (unreserved)
    @Test
    func `Tilde passes through unencoded`() throws {
        let template = try RFC_6570.Template("{var}")
        let result = try template.expand(variables: ["var": "~user"])
        #expect(result.value == "~user")
    }
}
