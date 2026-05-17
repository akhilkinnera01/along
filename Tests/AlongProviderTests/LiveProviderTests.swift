import Foundation
import Testing
@testable import AlongCore
@testable import AlongGemini
@testable import AlongOpenAI

@Test
func openAILiveProviderRespondsWhenKeyIsSet() async throws {
    guard let apiKey = providerKey(named: "ALONG_OPENAI_API_KEY") else {
        return
    }

    let missionID = try #require(MissionID("mission-openai-live"))
    let model = providerModel(named: "ALONG_OPENAI_MODEL") ?? OpenAIProvider.defaultModel
    let provider = OpenAIProvider(apiKey: apiKey, model: model)

    let response = try await provider.respond(
        to: ModelRequest(missionID: missionID, userInput: "Reply with one short word.", tools: [])
    )

    #expect(!response.text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
}

@Test
func geminiLiveProviderRespondsWhenKeyIsSet() async throws {
    guard let apiKey = providerKey(named: "ALONG_GEMINI_API_KEY") else {
        return
    }

    let missionID = try #require(MissionID("mission-gemini-live"))
    let model = providerModel(named: "ALONG_GEMINI_MODEL") ?? GeminiProvider.defaultModel
    let provider = GeminiProvider(apiKey: apiKey, model: model)

    let response = try await provider.respond(
        to: ModelRequest(missionID: missionID, userInput: "Reply with one short word.", tools: [])
    )

    #expect(!response.text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
}

private func providerKey(named name: String) -> String? {
    let value = ProcessInfo.processInfo.environment[name]?.trimmingCharacters(in: .whitespacesAndNewlines)
    guard let value, !value.isEmpty else {
        return nil
    }
    return value
}

private func providerModel(named name: String) -> String? {
    providerKey(named: name)
}
