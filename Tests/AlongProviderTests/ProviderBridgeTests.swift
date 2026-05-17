import Testing
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
