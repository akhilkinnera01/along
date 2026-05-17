import Foundation

public enum MissionStoreError: Error, Equatable, Sendable {
    case missionAlreadyExists(MissionID)
    case missionNotFound(MissionID)
}

public actor MissionStore {
    private var records: [MissionID: MissionRecord]
    private let idGenerator: any IDGenerator

    public init(records: [MissionID: MissionRecord] = [:], idGenerator: any IDGenerator = UUIDIDGenerator()) {
        self.records = records
        self.idGenerator = idGenerator
    }

    @discardableResult
    public func createMission(
        id: MissionID? = nil,
        title: String,
        template: MissionTemplateKind,
        at date: Date
    ) throws -> MissionSnapshot {
        let missionID = id ?? idGenerator.nextMissionID()
        guard records[missionID] == nil else {
            throw MissionStoreError.missionAlreadyExists(missionID)
        }

        let event = MissionEvent(
            id: idGenerator.nextMissionEventID(),
            missionID: missionID,
            sequence: 1,
            kind: .missionStarted(template: template, title: title),
            occurredAt: date
        )

        let snapshot = MissionSnapshot(
            id: missionID,
            title: title,
            template: template,
            status: .working,
            summary: "",
            lastSequence: event.sequence,
            lastEventID: event.id,
            createdAt: date,
            updatedAt: date
        )

        records[missionID] = MissionRecord(snapshot: snapshot, events: [event])
        return snapshot
    }

    @discardableResult
    public func append(
        _ kind: MissionEventKind,
        to missionID: MissionID,
        at date: Date
    ) throws -> MissionEvent {
        guard var record = records[missionID] else {
            throw MissionStoreError.missionNotFound(missionID)
        }

        let event = MissionEvent(
            id: idGenerator.nextMissionEventID(),
            missionID: missionID,
            sequence: record.snapshot.lastSequence + 1,
            kind: kind,
            occurredAt: date
        )

        record.events.append(event)
        record.snapshot = MissionReducer.apply(event, to: record.snapshot)
        records[missionID] = record
        return event
    }

    public func snapshot(for missionID: MissionID) throws -> MissionSnapshot {
        guard let record = records[missionID] else {
            throw MissionStoreError.missionNotFound(missionID)
        }
        return record.snapshot
    }

    public func snapshots() -> [MissionSnapshot] {
        records.values
            .map(\.snapshot)
            .sorted { $0.updatedAt > $1.updatedAt }
    }

    public func events(for missionID: MissionID) throws -> [MissionEvent] {
        guard let record = records[missionID] else {
            throw MissionStoreError.missionNotFound(missionID)
        }
        return record.events
    }
}

public struct MissionRecord: Codable, Equatable, Sendable {
    public var snapshot: MissionSnapshot
    public var events: [MissionEvent]

    public init(snapshot: MissionSnapshot, events: [MissionEvent]) {
        self.snapshot = snapshot
        self.events = events
    }
}

enum MissionReducer {
    static func apply(_ event: MissionEvent, to snapshot: MissionSnapshot) -> MissionSnapshot {
        var next = snapshot
        next.lastSequence = event.sequence
        next.lastEventID = event.id
        next.updatedAt = event.occurredAt

        switch event.kind {
        case .missionStarted(let template, let title):
            next.template = template
            next.title = title
            next.status = .working
        case .statusChanged(let status):
            next.status = status
        case .summaryChanged(let summary):
            next.summary = summary
        case .approvalRequested:
            next.status = .needsApproval
        case .approvalResolved(_, true):
            next.status = .working
        case .approvalResolved(_, false):
            next.status = .blocked
        case .agentTurnStarted:
            next.status = .working
        case .agentTurnCompleted(let summary):
            next.status = .monitoring
            next.summary = summary
        case .agentTurnFailed:
            next.status = .failed
        case .toolStarted:
            next.status = .working
        case .toolCompleted:
            next.status = .working
        case .toolFailed:
            next.status = .blocked
        }

        return next
    }
}
