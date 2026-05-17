import Foundation

public struct MissionID: Hashable, Codable, Sendable, CustomStringConvertible {
    public let rawValue: String

    public init?(_ rawValue: String) {
        let value = rawValue.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !value.isEmpty, value.count <= 128 else {
            return nil
        }
        self.rawValue = value
    }

    public static func unique() -> MissionID {
        MissionID(unchecked: "mission-\(UUID().uuidString)")
    }

    public var description: String {
        rawValue
    }

    private init(unchecked rawValue: String) {
        self.rawValue = rawValue
    }
}

public struct MissionEventID: Hashable, Codable, Sendable, CustomStringConvertible {
    public let rawValue: String

    public init?(_ rawValue: String) {
        let value = rawValue.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !value.isEmpty, value.count <= 128 else {
            return nil
        }
        self.rawValue = value
    }

    public static func unique() -> MissionEventID {
        MissionEventID(unchecked: "event-\(UUID().uuidString)")
    }

    public var description: String {
        rawValue
    }

    private init(unchecked rawValue: String) {
        self.rawValue = rawValue
    }
}

public struct ApprovalID: Hashable, Codable, Sendable, CustomStringConvertible {
    public let rawValue: String

    public init?(_ rawValue: String) {
        let value = rawValue.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !value.isEmpty, value.count <= 128 else {
            return nil
        }
        self.rawValue = value
    }

    public static func unique() -> ApprovalID {
        ApprovalID(unchecked: "approval-\(UUID().uuidString)")
    }

    public var description: String {
        rawValue
    }

    private init(unchecked rawValue: String) {
        self.rawValue = rawValue
    }
}

