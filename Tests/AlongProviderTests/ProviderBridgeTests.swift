import Testing
import Foundation
@testable import AlongCore
@testable import AlongOpenAI
@testable import AlongGemini

@Test
func openAIProviderDelegatesToInjectedResponder() async throws {
    let missionID = try #require(MissionID("mission-openai"))
    let provider = OpenAIProvider { request in
        #expect(request.missionID == missionID)
        return ModelResponse(text: "ok")
    }

    let response = try await provider.respond(
        to: ModelRequest(missionID: missionID, userInput: "hello", tools: [])
    )

    #expect(response.text == "ok")
}

@Test
func openAIProviderSendsResponsesRequest() async throws {
    let missionID = try #require(MissionID("mission-openai-http"))
    let endpoint = try #require(URL(string: "https://example.test/v1/responses"))
    let provider = OpenAIProvider(
        apiKey: "test-key",
        model: "gpt-test",
        endpoint: endpoint,
        httpClient: { request in
            #expect(request.url == endpoint)
            #expect(request.httpMethod == "POST")
            #expect(request.value(forHTTPHeaderField: "Authorization") == "Bearer test-key")
            #expect(request.value(forHTTPHeaderField: "Content-Type") == "application/json")

            let body = try #require(request.httpBody)
            let json = try #require(JSONSerialization.jsonObject(with: body) as? [String: Any])

            #expect(json["model"] as? String == "gpt-test")
            #expect(json["input"] as? String == "hello")

            return OpenAIHTTPResponse(statusCode: 200, data: openAITextResponse("ready"))
        }
    )

    let response = try await provider.respond(
        to: ModelRequest(missionID: missionID, userInput: "hello", tools: [])
    )

    #expect(response.text == "ready")
}

@Test
func openAIProviderRejectsFailedStatus() async throws {
    let missionID = try #require(MissionID("mission-openai-failed"))
    let provider = OpenAIProvider(
        apiKey: "test-key",
        model: "gpt-test",
        httpClient: { _ in OpenAIHTTPResponse(statusCode: 401, data: Data()) }
    )

    await #expect(throws: OpenAIProviderError.requestFailed(statusCode: 401)) {
        _ = try await provider.respond(
            to: ModelRequest(missionID: missionID, userInput: "hello", tools: [])
        )
    }
}

@Test
func openAIProviderRejectsMissingText() async throws {
    let missionID = try #require(MissionID("mission-openai-missing-text"))
    let provider = OpenAIProvider(
        apiKey: "test-key",
        model: "gpt-test",
        httpClient: { _ in OpenAIHTTPResponse(statusCode: 200, data: Data(#"{"output":[]}"#.utf8)) }
    )

    await #expect(throws: OpenAIProviderError.missingText) {
        _ = try await provider.respond(
            to: ModelRequest(missionID: missionID, userInput: "hello", tools: [])
        )
    }
}

@Test
func geminiProviderDelegatesToInjectedResponder() async throws {
    let missionID = try #require(MissionID("mission-gemini"))
    let provider = GeminiProvider { request in
        #expect(request.missionID == missionID)
        return ModelResponse(text: "ok")
    }

    let response = try await provider.respond(
        to: ModelRequest(missionID: missionID, userInput: "hello", tools: [])
    )

    #expect(response.text == "ok")
}

private func openAITextResponse(_ text: String) -> Data {
    Data(
        """
        {
          "output": [
            {
              "content": [
                {
                  "type": "output_text",
                  "text": "\(text)"
                }
              ]
            }
          ]
        }
        """.utf8
    )
}
