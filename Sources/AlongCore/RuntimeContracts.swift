import Foundation

public struct ModelRequest: Equatable, Sendable {
    public let missionID: MissionID
    public let userInput: String
    public let tools: [ToolDescription]

    public init(missionID: MissionID, userInput: String, tools: [ToolDescription]) {
        self.missionID = missionID
        self.userInput = userInput
        self.tools = tools
    }
}

public struct ModelResponse: Equatable, Sendable {
    public let text: String
    public let toolCalls: [ToolCall]

    public init(text: String, toolCalls: [ToolCall] = []) {
        self.text = text
        self.toolCalls = toolCalls
    }
}

public protocol ModelProvider: Sendable {
    func respond(to request: ModelRequest) async throws -> ModelResponse
}

public struct ToolName: Hashable, Codable, Sendable, CustomStringConvertible {
    public let rawValue: String

    public init?(_ rawValue: String) {
        let value = rawValue.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !value.isEmpty, value.count <= 80 else {
            return nil
        }
        self.rawValue = value
    }

    public var description: String {
        rawValue
    }
}

public enum ToolSafety: String, Codable, Equatable, Sendable {
    case readOnly
    case localWrite
    case externalWrite

    public var requiresApproval: Bool {
        switch self {
        case .readOnly:
            return false
        case .localWrite, .externalWrite:
            return true
        }
    }
}

public struct ToolDescription: Equatable, Sendable {
    public let name: ToolName
    public let safety: ToolSafety
    public let summary: String

    public init(name: ToolName, safety: ToolSafety, summary: String) {
        self.name = name
        self.safety = safety
        self.summary = summary
    }
}

public struct ToolArguments: Equatable, Sendable {
    public let values: [String: String]

    public init(_ values: [String: String] = [:]) {
        self.values = values
    }
}

public struct ToolCall: Equatable, Sendable {
    public let name: ToolName
    public let arguments: ToolArguments

    public init(name: ToolName, arguments: ToolArguments = ToolArguments()) {
        self.name = name
        self.arguments = arguments
    }
}

public struct ToolContext: Sendable {
    public let missionID: MissionID

    public init(missionID: MissionID) {
        self.missionID = missionID
    }
}

public struct ToolResult: Equatable, Sendable {
    public let name: ToolName
    public let summary: String

    public init(name: ToolName, summary: String) {
        self.name = name
        self.summary = summary
    }
}

public protocol Tool: Sendable {
    var description: ToolDescription { get }
    func run(arguments: ToolArguments, context: ToolContext) async throws -> ToolResult
}

public enum ToolRegistryError: Error, Equatable, Sendable {
    case duplicateTool(ToolName)
    case missingTool(ToolName)
}

public actor ToolRegistry {
    private var tools: [ToolName: any Tool]

    public init(tools: [any Tool] = []) throws {
        self.tools = [:]
        for tool in tools {
            let name = tool.description.name
            guard self.tools[name] == nil else {
                throw ToolRegistryError.duplicateTool(name)
            }
            self.tools[name] = tool
        }
    }

    public func register(_ tool: any Tool) throws {
        let name = tool.description.name
        guard tools[name] == nil else {
            throw ToolRegistryError.duplicateTool(name)
        }
        tools[name] = tool
    }

    public func tool(named name: ToolName) -> (any Tool)? {
        tools[name]
    }

    public func descriptions() -> [ToolDescription] {
        tools.values
            .map(\.description)
            .sorted { $0.name.rawValue < $1.name.rawValue }
    }
}

public struct ApprovalRequest: Equatable, Sendable {
    public let id: ApprovalID
    public let missionID: MissionID
    public let title: String
    public let summary: String

    public init(id: ApprovalID = .unique(), missionID: MissionID, title: String, summary: String) {
        self.id = id
        self.missionID = missionID
        self.title = title
        self.summary = summary
    }
}

public struct ApprovalResponse: Equatable, Sendable {
    public let approved: Bool

    public init(approved: Bool) {
        self.approved = approved
    }
}

public protocol ApprovalBroker: Sendable {
    func requestApproval(_ request: ApprovalRequest) async throws -> ApprovalResponse
}
