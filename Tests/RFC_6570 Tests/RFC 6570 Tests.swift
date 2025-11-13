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

    // MARK: - RFC 6570 Section 3.2.2 Examples

    @Test("RFC Level 1 examples", arguments: [
        ("{var}", ["var": "value"], "value"),
        ("{hello}", ["hello": "Hello World!"], "Hello%20World%21"),
    ])
    func testLevel1Examples(
        template: String,
        vars: [String: RFC_6570.VariableValue],
        expected: String
    ) throws {
        let tpl = try RFC_6570.Template(template)
        let result = try tpl.expand(variables: vars)
        #expect(result == expected)
    }

    @Test("RFC Level 2 examples", arguments: [
        ("{+var}", ["var": "value"], "value"),
        ("{+hello}", ["hello": "Hello World!"], "Hello%20World!"),
    ])
    func testLevel2Examples(
        template: String,
        vars: [String: RFC_6570.VariableValue],
        expected: String
    ) throws {
        let tpl = try RFC_6570.Template(template)
        let result = try tpl.expand(variables: vars)
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
        #expect(RFC_6570.Operator.query.separator == "&")
        #expect(RFC_6570.Operator.path.separator == ".")
    }
}

@Suite("Variable Value Tests")
struct VariableValueTests {

    @Test("String value is defined")
    func testStringDefined() {
        let value: RFC_6570.VariableValue = "hello"
        #expect(value.isDefined)
    }

    @Test("Empty string is not defined")
    func testEmptyStringNotDefined() {
        let value: RFC_6570.VariableValue = ""
        #expect(!value.isDefined)
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
