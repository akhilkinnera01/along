import Foundation

public struct MissionEvent: Codable, Equatable, Sendable {
    public let id: MissionEventID
    public let missionID: MissionID
    public let sequence: Int
    public let kind: MissionEventKind
    public let occurredAt: Date

    public init(
        id: MissionEventID,
        missionID: MissionID,
        sequence: Int,
        kind: MissionEventKind,
        occurredAt: Date
    ) {
        self.id = id
        self.missionID = missionID
        self.sequence = sequence
        self.kind = kind
        self.occurredAt = occurredAt
    }
}

public enum MissionEventType: String, Codable, Equatable, Sendable {
    case missionStarted
    case statusChanged
    case summaryChanged
    case approvalRequested
    case approvalResolved
    case agentTurnStarted
    case agentTurnCompleted
    case agentTurnFailed
    case toolStarted
    case toolCompleted
    case toolFailed
}

public enum MissionEventKind: Codable, Equatable, Sendable {
    case missionStarted(template: MissionTemplateKind, title: String)
    case statusChanged(MissionStatus)
    case summaryChanged(String)
    case approvalRequested(ApprovalID, String)
    case approvalResolved(ApprovalID, Bool)
    case agentTurnStarted(String)
    case agentTurnCompleted(String)
    case agentTurnFailed(RuntimeFailure)
    case toolStarted(String)
    case toolCompleted(String)
    case toolFailed(String, RuntimeFailure)

    public var type: MissionEventType {
        switch self {
        case .missionStarted:
            return .missionStarted
        case .statusChanged:
            return .statusChanged
        case .summaryChanged:
            return .summaryChanged
        case .approvalRequested:
            return .approvalRequested
        case .approvalResolved:
            return .approvalResolved
        case .agentTurnStarted:
            return .agentTurnStarted
        case .agentTurnCompleted:
            return .agentTurnCompleted
        case .agentTurnFailed:
            return .agentTurnFailed
        case .toolStarted:
            return .toolStarted
        case .toolCompleted:
            return .toolCompleted
        case .toolFailed:
            return .toolFailed
        }
    }

    private enum CodingKeys: String, CodingKey {
        case type
        case template
        case title
        case status
        case summary
        case approvalID
        case approved
        case input
        case failure
        case toolName
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let type = try container.decode(MissionEventType.self, forKey: .type)

        switch type {
        case .missionStarted:
            self = .missionStarted(
                template: try container.decode(MissionTemplateKind.self, forKey: .template),
                title: try container.decode(String.self, forKey: .title)
            )
        case .statusChanged:
            self = .statusChanged(try container.decode(MissionStatus.self, forKey: .status))
        case .summaryChanged:
            self = .summaryChanged(try container.decode(String.self, forKey: .summary))
        case .approvalRequested:
            self = .approvalRequested(
                try container.decode(ApprovalID.self, forKey: .approvalID),
                try container.decode(String.self, forKey: .title)
            )
        case .approvalResolved:
            self = .approvalResolved(
                try container.decode(ApprovalID.self, forKey: .approvalID),
                try container.decode(Bool.self, forKey: .approved)
            )
        case .agentTurnStarted:
            self = .agentTurnStarted(try container.decode(String.self, forKey: .input))
        case .agentTurnCompleted:
            self = .agentTurnCompleted(try container.decode(String.self, forKey: .summary))
        case .agentTurnFailed:
            self = .agentTurnFailed(try container.decode(RuntimeFailure.self, forKey: .failure))
        case .toolStarted:
            self = .toolStarted(try container.decode(String.self, forKey: .toolName))
        case .toolCompleted:
            self = .toolCompleted(try container.decode(String.self, forKey: .toolName))
        case .toolFailed:
            self = .toolFailed(
                try container.decode(String.self, forKey: .toolName),
                try container.decode(RuntimeFailure.self, forKey: .failure)
            )
        }
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(type, forKey: .type)

        switch self {
        case .missionStarted(let template, let title):
            try container.encode(template, forKey: .template)
            try container.encode(title, forKey: .title)
        case .statusChanged(let status):
            try container.encode(status, forKey: .status)
        case .summaryChanged(let summary):
            try container.encode(summary, forKey: .summary)
        case .approvalRequested(let approvalID, let title):
            try container.encode(approvalID, forKey: .approvalID)
            try container.encode(title, forKey: .title)
        case .approvalResolved(let approvalID, let approved):
            try container.encode(approvalID, forKey: .approvalID)
            try container.encode(approved, forKey: .approved)
        case .agentTurnStarted(let input):
            try container.encode(input, forKey: .input)
        case .agentTurnCompleted(let summary):
            try container.encode(summary, forKey: .summary)
        case .agentTurnFailed(let failure):
            try container.encode(failure, forKey: .failure)
        case .toolStarted(let toolName):
            try container.encode(toolName, forKey: .toolName)
        case .toolCompleted(let toolName):
            try container.encode(toolName, forKey: .toolName)
        case .toolFailed(let toolName, let failure):
            try container.encode(toolName, forKey: .toolName)
            try container.encode(failure, forKey: .failure)
        }
    }
}
