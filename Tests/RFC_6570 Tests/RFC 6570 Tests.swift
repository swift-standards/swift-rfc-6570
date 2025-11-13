import Testing
import Foundation
@testable import RFC_6570

@Suite("RFC 6570 URI Template Tests")
struct RFC_6570_Tests {

    // MARK: - Template Parsing Tests

    @Test("Parse simple template")
    func testSimpleTemplate() throws {
        let template = try RFC_6570.Template("/{var}")
        #expect(template.value == "/{var}")
        #expect(template.components.count == 2)
    }

    @Test("Parse template with literals and expressions")
    func testMixedTemplate() throws {
        let template = try RFC_6570.Template("/users/{id}/posts")
        // Should be: "/users/", "{id}", "/posts"
        #expect(template.components.count == 3)
    }

    @Test("Parse template with query parameters")
    func testQueryTemplate() throws {
        let template = try RFC_6570.Template("/search{?q,page}")
        #expect(template.value == "/search{?q,page}")
    }

    @Test("Invalid template throws error")
    func testInvalidTemplate() {
        #expect(throws: RFC_6570.Error.self) {
            try RFC_6570.Template("{invalid")
        }
    }

    @Test("Empty expression throws error")
    func testEmptyExpression() {
        #expect(throws: RFC_6570.Error.self) {
            try RFC_6570.Template("{}")
        }
    }

    // MARK: - Basic Expansion Tests

    @Test("Expand simple variable")
    func testSimpleExpansion() throws {
        let template = try RFC_6570.Template("/{var}")
        let uri = try template.expand(variables: ["var": "value"])
        #expect(uri == "/value")
    }

    @Test("Expand multiple variables")
    func testMultipleVariables() throws {
        let template = try RFC_6570.Template("/users/{id}/posts/{postId}")
        let uri = try template.expand(variables: [
            "id": "123",
            "postId": "456"
        ])
        #expect(uri == "/users/123/posts/456")
    }

    @Test("Expand with undefined variable")
    func testUndefinedVariable() throws {
        let template = try RFC_6570.Template("/{var}/{other}")
        let uri = try template.expand(variables: ["var": "value"])
        // Undefined variables are skipped
        #expect(uri == "/value/")
    }

    // MARK: - Operator Tests

    @Test("Simple expansion operator")
    func testSimpleOperator() throws {
        let template = try RFC_6570.Template("{var}")
        let uri = try template.expand(variables: ["var": "value"])
        #expect(uri == "value")
    }

    @Test("Reserved expansion operator")
    func testReservedOperator() throws {
        let template = try RFC_6570.Template("{+var}")
        let uri = try template.expand(variables: ["var": "hello world"])
        // Space should be encoded even in reserved expansion
        #expect(uri == "hello%20world")
    }

    @Test("Fragment expansion operator")
    func testFragmentOperator() throws {
        let template = try RFC_6570.Template("{#var}")
        let uri = try template.expand(variables: ["var": "section"])
        #expect(uri == "#section")
    }

    @Test("Query expansion operator")
    func testQueryOperator() throws {
        let template = try RFC_6570.Template("{?var}")
        let uri = try template.expand(variables: ["var": "value"])
        #expect(uri == "?var=value")
    }

    @Test("Query with multiple variables")
    func testQueryMultipleVars() throws {
        let template = try RFC_6570.Template("{?x,y}")
        let uri = try template.expand(variables: [
            "x": "1",
            "y": "2"
        ])
        #expect(uri == "?x=1&y=2")
    }

    // MARK: - List Expansion Tests

    @Test("List with simple expansion")
    func testListSimple() throws {
        let template = try RFC_6570.Template("{list}")
        let uri = try template.expand(variables: [
            "list": .list(["red", "green", "blue"])
        ])
        #expect(uri == "red,green,blue")
    }

    @Test("List with explode modifier")
    func testListExplode() throws {
        let template = try RFC_6570.Template("{list*}")
        let uri = try template.expand(variables: [
            "list": .list(["red", "green", "blue"])
        ])
        #expect(uri == "red,green,blue")
    }

    @Test("List with query and explode")
    func testListQueryExplode() throws {
        let template = try RFC_6570.Template("{?list*}")
        let uri = try template.expand(variables: [
            "list": .list(["red", "green", "blue"])
        ])
        #expect(uri == "?list=red&list=green&list=blue")
    }

    // MARK: - Dictionary Expansion Tests

    @Test("Dictionary with query and explode")
    func testDictQueryExplode() throws {
        let template = try RFC_6570.Template("{?dict*}")
        let uri = try template.expand(variables: [
            "dict": .dictionary(["lang": "en", "sort": "date"])
        ])
        // Dictionary keys are sorted
        #expect(uri == "?lang=en&sort=date")
    }

    // MARK: - Modifier Tests

    @Test("Prefix modifier")
    func testPrefixModifier() throws {
        let template = try RFC_6570.Template("{var:3}")
        let uri = try template.expand(variables: ["var": "value"])
        #expect(uri == "val")
    }

    // MARK: - RFC 6570 Appendix A - Comprehensive Test Suite

    /// Standard variable definitions from RFC 6570 Section 3.2
    private static let standardVars: [String: RFC_6570.VariableValue] = [
        "var": "value",
        "hello": "Hello World!",
        "half": "50%",
        "empty": "",
        "who": "fred",
        "base": "http://example.com/home/",
        "path": "/foo/bar",
        "dub": "me/too",
        "v": "6",
        "x": "1024",
        "y": "768",
        "list": .list(["red", "green", "blue"]),
        "keys": .dictionary(["semi": ";", "dot": ".", "comma": ","]),
        "dom": .list(["example", "com"]),
        "count": .list(["one", "two", "three"]),
        "empty_keys": .dictionary([:])
    ]

    // MARK: - 3.2.2 Simple String Expansion: {var}

    @Test("RFC 6570 Section 3.2.2 - Simple String Expansion", arguments: [
        ("{var}", "value"),
        ("{hello}", "Hello%20World%21"),
        ("{half}", "50%25"),
        ("O{empty}X", "OX"),
        ("O{undef}X", "OX"),
        ("{x,y}", "1024,768"),
        ("{x,hello,y}", "1024,Hello%20World%21,768"),
        ("?{x,empty}", "?1024,"),
        ("?{x,undef}", "?1024"),
        ("?{undef,y}", "?768"),
        ("{var:3}", "val"),
        ("{var:30}", "value"),
        ("{list}", "red,green,blue"),
        ("{list*}", "red,green,blue"),
        ("{keys}", "semi,%3B,dot,.,comma,%2C"),
        ("{keys*}", "semi=%3B,dot=.,comma=%2C"),
    ])
    func testSimpleStringExpansion(template: String, expected: String) throws {
        let tpl = try RFC_6570.Template(template)
        let result = try tpl.expand(variables: Self.standardVars)
        #expect(result == expected)
    }

    // MARK: - 3.2.3 Reserved Expansion: {+var}

    @Test("RFC 6570 Section 3.2.3 - Reserved Expansion", arguments: [
        ("{+var}", "value"),
        ("{+hello}", "Hello%20World!"),
        ("{+half}", "50%25"),
        ("{base}index", "http%3A%2F%2Fexample.com%2Fhome%2Findex"),
        ("{+base}index", "http://example.com/home/index"),
        ("O{+empty}X", "OX"),
        ("O{+undef}X", "OX"),
        ("{+path}/here", "/foo/bar/here"),
        ("here?ref={+path}", "here?ref=/foo/bar"),
        ("up{+path}{var}/here", "up/foo/barvalue/here"),
        ("{+x,hello,y}", "1024,Hello%20World!,768"),
        ("{+path,x}/here", "/foo/bar,1024/here"),
        ("{+path:6}/here", "/foo/b/here"),
        ("{+list}", "red,green,blue"),
        ("{+list*}", "red,green,blue"),
        ("{+keys}", "semi,;,dot,.,comma,,"),
        ("{+keys*}", "semi=;,dot=.,comma=,"),
    ])
    func testReservedExpansion(template: String, expected: String) throws {
        let tpl = try RFC_6570.Template(template)
        let result = try tpl.expand(variables: Self.standardVars)
        #expect(result == expected)
    }

    // MARK: - 3.2.4 Fragment Expansion: {#var}

    @Test("RFC 6570 Section 3.2.4 - Fragment Expansion", arguments: [
        ("{#var}", "#value"),
        ("{#hello}", "#Hello%20World!"),
        ("{#half}", "#50%25"),
        ("foo{#empty}", "foo#"),
        ("foo{#undef}", "foo"),
        ("{#x,hello,y}", "#1024,Hello%20World!,768"),
        ("{#path,x}/here", "#/foo/bar,1024/here"),
        ("{#path:6}/here", "#/foo/b/here"),
        ("{#list}", "#red,green,blue"),
        ("{#list*}", "#red,green,blue"),
        ("{#keys}", "#semi,;,dot,.,comma,,"),
        ("{#keys*}", "#semi=;,dot=.,comma=,"),
    ])
    func testFragmentExpansion(template: String, expected: String) throws {
        let tpl = try RFC_6570.Template(template)
        let result = try tpl.expand(variables: Self.standardVars)
        #expect(result == expected)
    }

    // MARK: - 3.2.5 Label Expansion with Dot-Prefix: {.var}

    @Test("RFC 6570 Section 3.2.5 - Label Expansion", arguments: [
        ("{.who}", ".fred"),
        ("{.who,who}", ".fred.fred"),
        ("{.half,who}", ".50%25.fred"),
        ("www{.dom*}", "www.example.com"),
        ("X{.var}", "X.value"),
        ("X{.empty}", "X."),
        ("X{.undef}", "X"),
        ("X{.var:3}", "X.val"),
        ("X{.list}", "X.red,green,blue"),
        ("X{.list*}", "X.red.green.blue"),
        ("X{.keys}", "X.semi,%3B,dot,.,comma,%2C"),
        ("X{.keys*}", "X.semi=%3B.dot=..comma=%2C"),
        ("X{.empty_keys}", "X"),
        ("X{.empty_keys*}", "X"),
    ])
    func testLabelExpansion(template: String, expected: String) throws {
        let tpl = try RFC_6570.Template(template)
        let result = try tpl.expand(variables: Self.standardVars)
        #expect(result == expected)
    }

    // MARK: - 3.2.6 Path Segment Expansion: {/var}

    @Test("RFC 6570 Section 3.2.6 - Path Segment Expansion", arguments: [
        ("{/who}", "/fred"),
        ("{/who,who}", "/fred/fred"),
        ("{/half,who}", "/50%25/fred"),
        ("{/who,dub}", "/fred/me%2Ftoo"),
        ("{/var}", "/value"),
        ("{/var,empty}", "/value/"),
        ("{/var,undef}", "/value"),
        ("{/var,x}/here", "/value/1024/here"),
        ("{/var:1,var}", "/v/value"),
        ("{/list}", "/red,green,blue"),
        ("{/list*}", "/red/green/blue"),
        ("{/list*,path:4}", "/red/green/blue/%2Ffoo"),
        ("{/keys}", "/semi,%3B,dot,.,comma,%2C"),
        ("{/keys*}", "/semi=%3B/dot=./comma=%2C"),
    ])
    func testPathSegmentExpansion(template: String, expected: String) throws {
        let tpl = try RFC_6570.Template(template)
        let result = try tpl.expand(variables: Self.standardVars)
        #expect(result == expected)
    }

    // MARK: - 3.2.7 Path-Style Parameter Expansion: {;var}

    @Test("RFC 6570 Section 3.2.7 - Path-Style Parameter Expansion", arguments: [
        ("{;who}", ";who=fred"),
        ("{;half}", ";half=50%25"),
        ("{;empty}", ";empty"),
        ("{;v,empty,who}", ";v=6;empty;who=fred"),
        ("{;v,bar,who}", ";v=6;who=fred"),
        ("{;x,y}", ";x=1024;y=768"),
        ("{;x,y,empty}", ";x=1024;y=768;empty"),
        ("{;x,y,undef}", ";x=1024;y=768"),
        ("{;hello:5}", ";hello=Hello"),
        ("{;list}", ";list=red,green,blue"),
        ("{;list*}", ";list=red;list=green;list=blue"),
        ("{;keys}", ";keys=semi,%3B,dot,.,comma,%2C"),
        ("{;keys*}", ";semi=%3B;dot=.;comma=%2C"),
    ])
    func testPathStyleParameterExpansion(template: String, expected: String) throws {
        let tpl = try RFC_6570.Template(template)
        let result = try tpl.expand(variables: Self.standardVars)
        #expect(result == expected)
    }

    // MARK: - 3.2.8 Form-Style Query Expansion: {?var}

    @Test("RFC 6570 Section 3.2.8 - Form-Style Query Expansion", arguments: [
        ("{?who}", "?who=fred"),
        ("{?half}", "?half=50%25"),
        ("{?x,y}", "?x=1024&y=768"),
        ("{?x,y,empty}", "?x=1024&y=768&empty="),
        ("{?x,y,undef}", "?x=1024&y=768"),
        ("{?var:3}", "?var=val"),
        ("{?list}", "?list=red,green,blue"),
        ("{?list*}", "?list=red&list=green&list=blue"),
        ("{?keys}", "?keys=semi,%3B,dot,.,comma,%2C"),
        ("{?keys*}", "?semi=%3B&dot=.&comma=%2C"),
    ])
    func testFormStyleQueryExpansion(template: String, expected: String) throws {
        let tpl = try RFC_6570.Template(template)
        let result = try tpl.expand(variables: Self.standardVars)
        #expect(result == expected)
    }

    // MARK: - 3.2.9 Form-Style Query Continuation: {&var}

    @Test("RFC 6570 Section 3.2.9 - Form-Style Query Continuation", arguments: [
        ("{&who}", "&who=fred"),
        ("{&half}", "&half=50%25"),
        ("?fixed=yes{&x}", "?fixed=yes&x=1024"),
        ("{&x,y,empty}", "&x=1024&y=768&empty="),
        ("{&x,y,undef}", "&x=1024&y=768"),
        ("{&var:3}", "&var=val"),
        ("{&list}", "&list=red,green,blue"),
        ("{&list*}", "&list=red&list=green&list=blue"),
        ("{&keys}", "&keys=semi,%3B,dot,.,comma,%2C"),
        ("{&keys*}", "&semi=%3B&dot=.&comma=%2C"),
    ])
    func testFormStyleQueryContinuation(template: String, expected: String) throws {
        let tpl = try RFC_6570.Template(template)
        let result = try tpl.expand(variables: Self.standardVars)
        #expect(result == expected)
    }
}

@Suite("URI Template Operators")
struct OperatorTests {

    @Test("All operators have correct prefixes")
    func testOperatorPrefixes() {
        #expect(RFC_6570.Operator.simple.prefix == "")
        #expect(RFC_6570.Operator.reserved.prefix == "")
        #expect(RFC_6570.Operator.fragment.prefix == "#")
        #expect(RFC_6570.Operator.label.prefix == ".")
        #expect(RFC_6570.Operator.path.prefix == "/")
        #expect(RFC_6570.Operator.parameter.prefix == ";")
        #expect(RFC_6570.Operator.query.prefix == "?")
        #expect(RFC_6570.Operator.continuation.prefix == "&")
    }

    @Test("All operators have correct separators")
    func testOperatorSeparators() {
        #expect(RFC_6570.Operator.simple.separator == ",")
        #expect(RFC_6570.Operator.reserved.separator == ",")
        #expect(RFC_6570.Operator.fragment.separator == ",")
        #expect(RFC_6570.Operator.label.separator == ".")
        #expect(RFC_6570.Operator.path.separator == "/")
        #expect(RFC_6570.Operator.parameter.separator == ";")
        #expect(RFC_6570.Operator.query.separator == "&")
        #expect(RFC_6570.Operator.continuation.separator == "&")
    }
}

@Suite("Variable Value Tests")
struct VariableValueTests {

    @Test("String value is defined")
    func testStringDefined() {
        let value: RFC_6570.VariableValue = "hello"
        #expect(value.isDefined)
    }

    @Test("Empty string is defined per RFC 6570")
    func testEmptyStringIsDefined() {
        // Per RFC 6570, empty strings ARE defined (only undefined/nil values are undefined)
        let value: RFC_6570.VariableValue = ""
        #expect(value.isDefined)
    }

    @Test("List value is defined")
    func testListDefined() {
        let value: RFC_6570.VariableValue = ["a", "b", "c"]
        #expect(value.isDefined)
    }

    @Test("Dictionary value is defined")
    func testDictDefined() {
        let value: RFC_6570.VariableValue = ["key": "value"]
        #expect(value.isDefined)
    }
}
