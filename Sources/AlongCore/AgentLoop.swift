import Foundation

public enum AgentLoopError: Error, Equatable, Sendable {
    case missionQueued(position: Int)
    case missingTool(ToolName)
    case approvalDenied(ApprovalID)
}

public struct AgentTurnResult: Equatable, Sendable {
    public let missionID: MissionID
    public let responseText: String
    public let toolResults: [ToolResult]

    public init(missionID: MissionID, responseText: String, toolResults: [ToolResult]) {
        self.missionID = missionID
        self.responseText = responseText
        self.toolResults = toolResults
    }
}

public actor AgentLoop {
    private let store: MissionStore
    private let scheduler: MissionScheduler
    private let modelProvider: any ModelProvider
    private let toolRegistry: ToolRegistry
    private let approvalBroker: any ApprovalBroker
    private let now: @Sendable () -> Date

    public init(
        store: MissionStore,
        scheduler: MissionScheduler,
        modelProvider: any ModelProvider,
        toolRegistry: ToolRegistry,
        approvalBroker: any ApprovalBroker,
        now: @escaping @Sendable () -> Date = Date.init
    ) {
        self.store = store
        self.scheduler = scheduler
        self.modelProvider = modelProvider
        self.toolRegistry = toolRegistry
        self.approvalBroker = approvalBroker
        self.now = now
    }

    public func runTurn(missionID: MissionID, userInput: String) async throws -> AgentTurnResult {
        let decision = await scheduler.requestForeground(missionID)
        switch decision {
        case .granted, .alreadyForeground:
            break
        case .queued(let position):
            throw AgentLoopError.missionQueued(position: position)
        }

        do {
            let result = try await executeTurn(missionID: missionID, userInput: userInput)
            await scheduler.releaseForeground(missionID)
            return result
        } catch {
            _ = try? await store.append(.agentTurnFailed(String(describing: error)), to: missionID, at: now())
            await scheduler.releaseForeground(missionID)
            throw error
        }
    }

    private func executeTurn(missionID: MissionID, userInput: String) async throws -> AgentTurnResult {
        try await store.append(.agentTurnStarted(userInput), to: missionID, at: now())

        let request = ModelRequest(
            missionID: missionID,
            userInput: userInput,
            tools: await toolRegistry.descriptions()
        )
        let response = try await modelProvider.respond(to: request)
        let context = ToolContext(missionID: missionID)
        var toolResults: [ToolResult] = []

        for call in response.toolCalls {
            guard let tool = await toolRegistry.tool(named: call.name) else {
                throw AgentLoopError.missingTool(call.name)
            }

            if tool.description.safety.requiresApproval {
                let approval = ApprovalRequest(
                    missionID: missionID,
                    title: "Approve \(call.name.rawValue)",
                    summary: tool.description.summary
                )
                try await store.append(
                    .approvalRequested(approval.id, approval.title),
                    to: missionID,
                    at: now()
                )

                let response = try await approvalBroker.requestApproval(approval)
                try await store.append(
                    .approvalResolved(approval.id, response.approved),
                    to: missionID,
                    at: now()
                )

                guard response.approved else {
                    throw AgentLoopError.approvalDenied(approval.id)
                }
            }

            try await store.append(.toolStarted(call.name.rawValue), to: missionID, at: now())
            let result = try await tool.run(arguments: call.arguments, context: context)
            toolResults.append(result)
            try await store.append(.toolCompleted(call.name.rawValue), to: missionID, at: now())
        }

        try await store.append(.agentTurnCompleted(response.text), to: missionID, at: now())
        return AgentTurnResult(missionID: missionID, responseText: response.text, toolResults: toolResults)
    }
}
