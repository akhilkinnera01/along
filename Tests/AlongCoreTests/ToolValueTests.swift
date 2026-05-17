import Foundation
import Testing
@testable import AlongCore

@Test
func toolArgumentsRoundTripJSONCompatibleValues() throws {
    let arguments = ToolArguments([
        "body": .string("Running late"),
        "urgent": .bool(true),
        "count": .int(2),
        "confidence": .double(0.75),
        "items": .array([.string("one"), .null]),
        "metadata": .object([
            "source": .string("watch"),
            "retry": .bool(false)
        ])
    ])

    let data = try JSONEncoder().encode(arguments)
    let decoded = try JSONDecoder().decode(ToolArguments.self, from: data)

    #expect(decoded == arguments)
}

@Test
func toolValueDecodesPlainJSONObjects() throws {
    let data = Data(
        #"{"values":{"title":"Stay With Me","minutes":5,"enabled":true,"notes":null}}"#
            .utf8
    )

    let decoded = try JSONDecoder().decode(ToolArguments.self, from: data)

    #expect(decoded.values["title"] == .string("Stay With Me"))
    #expect(decoded.values["minutes"] == .int(5))
    #expect(decoded.values["enabled"] == .bool(true))
    #expect(decoded.values["notes"] == .null)
}

