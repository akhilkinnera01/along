import AlongCore
import Foundation

public enum MemoryScope: String, Codable, CaseIterable, Equatable, Sendable {
    case mission
    case person
    case preference
    case routine
}

public enum SensitiveMemoryCategory: String, Codable, CaseIterable, Equatable, Hashable, Sendable {
    case health
    case finance
    case credential
    case preciseLocation
    case privateRelationship
    case legal
}

public struct MemoryCandidate: Codable, Equatable, Sendable {
    public let missionID: MissionID
    public let scope: MemoryScope
    public let text: String
    public let sensitiveCategories: Set<SensitiveMemoryCategory>

    public init(
        missionID: MissionID,
        scope: MemoryScope,
        text: String,
        sensitiveCategories: Set<SensitiveMemoryCategory> = []
    ) {
        self.missionID = missionID
        self.scope = scope
        self.text = text
        self.sensitiveCategories = sensitiveCategories
    }
}

public struct MemoryRecord: Codable, Equatable, Sendable {
    public let id: String
    public let missionID: MissionID
    public let scope: MemoryScope
    public let text: String
    public let createdAt: Date

    public init(id: String, missionID: MissionID, scope: MemoryScope, text: String, createdAt: Date) {
        self.id = id
        self.missionID = missionID
        self.scope = scope
        self.text = text
        self.createdAt = createdAt
    }
}

public enum MemoryPolicyError: Error, Equatable, Sendable {
    case emptyMemory
    case silentWriteDenied
    case sensitiveCategoryDenied(Set<SensitiveMemoryCategory>)
}

public struct MemoryPolicy: Sendable {
    public let blockedCategories: Set<SensitiveMemoryCategory>

    public init(blockedCategories: Set<SensitiveMemoryCategory> = Set(SensitiveMemoryCategory.allCases)) {
        self.blockedCategories = blockedCategories
    }

    public func makeRecord(
        from candidate: MemoryCandidate,
        approvedByUser: Bool,
        at date: Date
    ) throws -> MemoryRecord {
        guard !candidate.text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            throw MemoryPolicyError.emptyMemory
        }

        guard approvedByUser else {
            throw MemoryPolicyError.silentWriteDenied
        }

        let blocked = candidate.sensitiveCategories.intersection(blockedCategories)
        guard blocked.isEmpty else {
            throw MemoryPolicyError.sensitiveCategoryDenied(blocked)
        }

        return MemoryRecord(
            id: "memory-\(UUID().uuidString)",
            missionID: candidate.missionID,
            scope: candidate.scope,
            text: candidate.text,
            createdAt: date
        )
    }
}

