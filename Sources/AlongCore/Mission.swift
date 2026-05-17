import Foundation

public enum MissionStatus: String, Codable, Equatable, Sendable {
    case working
    case needsApproval
    case blocked
    case monitoring
    case done
    case failed
    case cancelled
}

public enum MissionTemplateKind: String, Codable, CaseIterable, Equatable, Sendable {
    case stayWithMe
    case runWithMe
    case focusWithMe
    case captureForMe
    case custom
}

public enum MissionExecutionRole: String, Codable, Equatable, Sendable {
    case foreground
    case monitoring
    case quick
}

public struct MissionSnapshot: Codable, Equatable, Sendable {
    public let id: MissionID
    public var title: String
    public var template: MissionTemplateKind
    public var executionRole: MissionExecutionRole
    public var status: MissionStatus
    public var summary: String
    public var lastSequence: Int
    public var lastEventID: MissionEventID
    public var createdAt: Date
    public var updatedAt: Date

    public init(
        id: MissionID,
        title: String,
        template: MissionTemplateKind,
        executionRole: MissionExecutionRole = .foreground,
        status: MissionStatus,
        summary: String,
        lastSequence: Int,
        lastEventID: MissionEventID,
        createdAt: Date,
        updatedAt: Date
    ) {
        self.id = id
        self.title = title
        self.template = template
        self.executionRole = executionRole
        self.status = status
        self.summary = summary
        self.lastSequence = lastSequence
        self.lastEventID = lastEventID
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
}

public struct MissionTemplate: Codable, Equatable, Sendable {
    public let kind: MissionTemplateKind
    public let displayName: String

    public init(kind: MissionTemplateKind, displayName: String) {
        self.kind = kind
        self.displayName = displayName
    }

    public static let stayWithMe = MissionTemplate(kind: .stayWithMe, displayName: "Stay With Me")
    public static let runWithMe = MissionTemplate(kind: .runWithMe, displayName: "Run With Me")
    public static let focusWithMe = MissionTemplate(kind: .focusWithMe, displayName: "Focus With Me")
    public static let captureForMe = MissionTemplate(kind: .captureForMe, displayName: "Capture For Me")
}
