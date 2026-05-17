import Foundation
import Testing
@testable import AlongCore

@Test
func missionStoreUsesInjectedIDGenerator() async throws {
    let missionID = try #require(MissionID("mission-generated"))
    let firstEventID = try #require(MissionEventID("event-started"))
    let generator = SequenceIDGenerator(
        missionIDs: [missionID],
        eventIDs: [firstEventID],
        approvalIDs: [try #require(ApprovalID("approval-unused"))]
    )
    let store = MissionStore(idGenerator: generator)

    let snapshot = try await store.createMission(
        title: "Stay With Me",
        template: .stayWithMe,
        at: Date(timeIntervalSince1970: 0)
    )
    let events = try await store.events(for: missionID)

    #expect(snapshot.id == missionID)
    #expect(snapshot.lastEventID == firstEventID)
    #expect(events.map(\.id) == [firstEventID])
}

@Test
func agentLoopUsesInjectedApprovalIDGenerator() async throws {
    let missionID = try #require(MissionID("mission-approval-id"))
    let sendMessage = try #require(ToolName("send_message"))
    let approvalID = try #require(ApprovalID("approval-fixed"))
    let store = MissionStore()
    let scheduler = MissionScheduler()
    let registry = try ToolRegistry(tools: [
        RecordingTool(
            description: ToolDescription(
                name: sendMessage,
                safety: .externalWrite,
                summary: "Send a message"
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
                text: "Message ready.",
                toolCalls: [ToolCall(name: sendMessage)]
            )
        ),
        toolRegistry: registry,
        approvalBroker: FixedApprovalBroker(approved: true),
        idGenerator: SequenceIDGenerator(
            missionIDs: [missionID],
            eventIDs: [],
            approvalIDs: [approvalID]
        ),
        now: { Date(timeIntervalSince1970: 1) }
    )

    _ = try await loop.runTurn(missionID: missionID, userInput: "Tell Sam I am late")
    let events = try await store.events(for: missionID)

    #expect(events.contains { event in
        if case .approvalRequested(let id, _) = event.kind {
            return id == approvalID
        }
        return false
    })
}

private final class SequenceIDGenerator: IDGenerator, @unchecked Sendable {
    private let lock = NSLock()
    private var missionIDs: [MissionID]
    private var eventIDs: [MissionEventID]
    private var approvalIDs: [ApprovalID]

    init(missionIDs: [MissionID], eventIDs: [MissionEventID], approvalIDs: [ApprovalID]) {
        self.missionIDs = missionIDs
        self.eventIDs = eventIDs
        self.approvalIDs = approvalIDs
    }

    func nextMissionID() -> MissionID {
        lock.withLock {
            missionIDs.isEmpty ? MissionID.unique() : missionIDs.removeFirst()
        }
    }

    func nextMissionEventID() -> MissionEventID {
        lock.withLock {
            eventIDs.isEmpty ? MissionEventID.unique() : eventIDs.removeFirst()
        }
    }

    func nextApprovalID() -> ApprovalID {
        lock.withLock {
            approvalIDs.isEmpty ? ApprovalID.unique() : approvalIDs.removeFirst()
        }
    }
}

private struct FixedProvider: ModelProvider {
    let response: ModelResponse

    func respond(to request: ModelRequest) async throws -> ModelResponse {
        response
    }
}

private actor RecordingTool: Tool {
    let description: ToolDescription

    init(description: ToolDescription) {
        self.description = description
    }

    func run(arguments: ToolArguments, context: ToolContext) async throws -> ToolResult {
        ToolResult(name: description.name, summary: "sent")
    }
}

private struct FixedApprovalBroker: ApprovalBroker {
    let approved: Bool

    func requestApproval(_ request: ApprovalRequest) async throws -> ApprovalResponse {
        ApprovalResponse(approved: approved)
    }
}
