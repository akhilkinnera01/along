import Foundation
import Testing
@testable import AlongCore

@Test
func agentLoopStoresSanitizedProviderFailure() async throws {
    let store = MissionStore()
    let scheduler = MissionScheduler()
    let missionID = try #require(MissionID("mission-provider-failure"))
    let registry = try ToolRegistry()

    try await store.createMission(
        id: missionID,
        title: "Stay With Me",
        template: .stayWithMe,
        at: Date(timeIntervalSince1970: 0)
    )

    let loop = AgentLoop(
        store: store,
        scheduler: scheduler,
        modelProvider: FailingProvider(),
        toolRegistry: registry,
        approvalBroker: FixedApprovalBroker(approved: true),
        now: { Date(timeIntervalSince1970: 1) }
    )

    await #expect(throws: AgentLoopError.self) {
        _ = try await loop.runTurn(missionID: missionID, userInput: "Start")
    }

    let failure = try await lastTurnFailure(in: store, missionID: missionID)

    #expect(failure.code == .providerFailed)
    #expect(failure.message == "Model provider request failed.")
    #expect(!failure.message.contains("sensitive-provider-value"))
}

@Test
func agentLoopStoresSanitizedToolFailure() async throws {
    let store = MissionStore()
    let scheduler = MissionScheduler()
    let missionID = try #require(MissionID("mission-tool-failure"))
    let toolName = try #require(ToolName("read_status"))
    let registry = try ToolRegistry(tools: [
        FailingTool(
            description: ToolDescription(
                name: toolName,
                safety: .readOnly,
                summary: "Read status"
            )
        )
    ])

    try await store.createMission(
        id: missionID,
        title: "Stay With Me",
        template: .stayWithMe,
        at: Date(timeIntervalSince1970: 0)
    )

    let loop = AgentLoop(
        store: store,
        scheduler: scheduler,
        modelProvider: FixedProvider(
            response: ModelResponse(
                text: "Checking status.",
                toolCalls: [ToolCall(name: toolName)]
            )
        ),
        toolRegistry: registry,
        approvalBroker: FixedApprovalBroker(approved: true),
        now: { Date(timeIntervalSince1970: 1) }
    )

    await #expect(throws: AgentLoopError.self) {
        _ = try await loop.runTurn(missionID: missionID, userInput: "Check status")
    }

    let events = try await store.events(for: missionID)
    let toolFailure = try #require(events.compactMap { event -> RuntimeFailure? in
        if case .toolFailed(_, let failure) = event.kind {
            return failure
        }
        return nil
    }.last)
    let turnFailure = try await lastTurnFailure(in: store, missionID: missionID)

    #expect(toolFailure.code == .toolFailed)
    #expect(toolFailure.message == "Tool execution failed.")
    #expect(turnFailure.code == .toolFailed)
    #expect(!toolFailure.message.contains("sensitive-provider-value"))
}

private func lastTurnFailure(in store: MissionStore, missionID: MissionID) async throws -> RuntimeFailure {
    let events = try await store.events(for: missionID)
    return try #require(events.compactMap { event -> RuntimeFailure? in
        if case .agentTurnFailed(let failure) = event.kind {
            return failure
        }
        return nil
    }.last)
}

private struct SecretFailure: Error, CustomStringConvertible {
    var description: String {
        "provider failed with sensitive-provider-value"
    }
}

private struct FailingProvider: ModelProvider {
    func respond(to request: ModelRequest) async throws -> ModelResponse {
        throw SecretFailure()
    }
}

private actor FailingTool: Tool {
    let description: ToolDescription

    init(description: ToolDescription) {
        self.description = description
    }

    func run(arguments: ToolArguments, context: ToolContext) async throws -> ToolResult {
        throw SecretFailure()
    }
}

private struct FixedProvider: ModelProvider {
    let response: ModelResponse

    func respond(to request: ModelRequest) async throws -> ModelResponse {
        response
    }
}

private struct FixedApprovalBroker: ApprovalBroker {
    let approved: Bool

    func requestApproval(_ request: ApprovalRequest) async throws -> ApprovalResponse {
        ApprovalResponse(approved: approved)
    }
}
