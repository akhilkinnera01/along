import Foundation
import Testing
@testable import AlongCore

@Test
func agentLoopRequestsApprovalBeforeExternalToolRun() async throws {
    let store = MissionStore()
    let scheduler = MissionScheduler()
    let missionID = try #require(MissionID("mission-agent"))
    let sendMessage = try #require(ToolName("send_message"))
    let tool = RecordingTool(
        description: ToolDescription(
            name: sendMessage,
            safety: .externalWrite,
            summary: "Send a message"
        )
    )
    let registry = try ToolRegistry(tools: [tool])
    let provider = FixedProvider(
        response: ModelResponse(
            text: "Message ready.",
            toolCalls: [ToolCall(name: sendMessage, arguments: ToolArguments(["body": .string("Running late")]))]
        )
    )
    let approvals = FixedApprovalBroker(approved: true)

    try await store.createMission(
        id: missionID,
        title: "Stay With Me",
        template: .stayWithMe,
        at: Date(timeIntervalSince1970: 0)
    )

    let loop = AgentLoop(
        store: store,
        scheduler: scheduler,
        modelProvider: provider,
        toolRegistry: registry,
        approvalBroker: approvals,
        now: { Date(timeIntervalSince1970: 1) }
    )

    let result = try await loop.runTurn(missionID: missionID, userInput: "Tell Sam I am late")
    let events = try await store.events(for: missionID)

    #expect(result.responseText == "Message ready.")
    #expect(result.toolResults.count == 1)
    #expect(await tool.runCount == 1)
    #expect(events.contains { event in
        if case .approvalRequested = event.kind {
            return true
        }
        return false
    })
}

@Test
func agentLoopStopsWhenApprovalIsDenied() async throws {
    let store = MissionStore()
    let scheduler = MissionScheduler()
    let missionID = try #require(MissionID("mission-denied"))
    let sendMessage = try #require(ToolName("send_message"))
    let tool = RecordingTool(
        description: ToolDescription(
            name: sendMessage,
            safety: .externalWrite,
            summary: "Send a message"
        )
    )
    let registry = try ToolRegistry(tools: [tool])
    let provider = FixedProvider(
        response: ModelResponse(
            text: "Message ready.",
            toolCalls: [ToolCall(name: sendMessage)]
        )
    )
    let approvals = FixedApprovalBroker(approved: false)

    try await store.createMission(
        id: missionID,
        title: "Stay With Me",
        template: .stayWithMe,
        at: Date(timeIntervalSince1970: 0)
    )

    let loop = AgentLoop(
        store: store,
        scheduler: scheduler,
        modelProvider: provider,
        toolRegistry: registry,
        approvalBroker: approvals,
        now: { Date(timeIntervalSince1970: 1) }
    )

    await #expect(throws: AgentLoopError.self) {
        try await loop.runTurn(missionID: missionID, userInput: "Tell Sam I am late")
    }
    #expect(await tool.runCount == 0)
}

private struct FixedProvider: ModelProvider {
    let response: ModelResponse

    func respond(to request: ModelRequest) async throws -> ModelResponse {
        response
    }
}

private actor RecordingTool: Tool {
    let description: ToolDescription
    private(set) var runCount = 0

    init(description: ToolDescription) {
        self.description = description
    }

    func run(arguments: ToolArguments, context: ToolContext) async throws -> ToolResult {
        runCount += 1
        return ToolResult(name: description.name, summary: "sent")
    }
}

private struct FixedApprovalBroker: ApprovalBroker {
    let approved: Bool

    func requestApproval(_ request: ApprovalRequest) async throws -> ApprovalResponse {
        ApprovalResponse(approved: approved)
    }
}
