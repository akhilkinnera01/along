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

@Test
func geminiProviderSendsGenerateContentRequest() async throws {
    let missionID = try #require(MissionID("mission-gemini-http"))
    let endpointBase = try #require(URL(string: "https://example.test/v1beta"))
    let expectedURL = try #require(URL(string: "https://example.test/v1beta/models/gemini-test:generateContent"))
    let provider = GeminiProvider(
        apiKey: "test-key",
        model: "gemini-test",
        endpointBase: endpointBase,
        httpClient: { request in
            #expect(request.url == expectedURL)
            #expect(request.httpMethod == "POST")
            #expect(request.value(forHTTPHeaderField: "x-goog-api-key") == "test-key")
            #expect(request.value(forHTTPHeaderField: "Content-Type") == "application/json")

            let body = try #require(request.httpBody)
            let json = try #require(JSONSerialization.jsonObject(with: body) as? [String: Any])
            let contents = try #require(json["contents"] as? [[String: Any]])
            let firstContent = try #require(contents.first)
            let parts = try #require(firstContent["parts"] as? [[String: Any]])
            let firstPart = try #require(parts.first)

            #expect(firstPart["text"] as? String == "hello")

            return GeminiHTTPResponse(statusCode: 200, data: geminiTextResponse("ready"))
        }
    )

    let response = try await provider.respond(
        to: ModelRequest(missionID: missionID, userInput: "hello", tools: [])
    )

    #expect(response.text == "ready")
}

@Test
func geminiProviderRejectsFailedStatus() async throws {
    let missionID = try #require(MissionID("mission-gemini-failed"))
    let provider = GeminiProvider(
        apiKey: "test-key",
        model: "gemini-test",
        httpClient: { _ in GeminiHTTPResponse(statusCode: 403, data: Data()) }
    )

    await #expect(throws: GeminiProviderError.requestFailed(statusCode: 403)) {
        _ = try await provider.respond(
            to: ModelRequest(missionID: missionID, userInput: "hello", tools: [])
        )
    }
}

@Test
func geminiProviderRejectsMissingText() async throws {
    let missionID = try #require(MissionID("mission-gemini-missing-text"))
    let provider = GeminiProvider(
        apiKey: "test-key",
        model: "gemini-test",
        httpClient: { _ in GeminiHTTPResponse(statusCode: 200, data: Data(#"{"candidates":[]}"#.utf8)) }
    )

    await #expect(throws: GeminiProviderError.missingText) {
        _ = try await provider.respond(
            to: ModelRequest(missionID: missionID, userInput: "hello", tools: [])
        )
    }
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

private func geminiTextResponse(_ text: String) -> Data {
    Data(
        """
        {
          "candidates": [
            {
              "content": {
                "parts": [
                  {
                    "text": "\(text)"
                  }
                ]
              }
            }
          ]
        }
        """.utf8
    )
}
