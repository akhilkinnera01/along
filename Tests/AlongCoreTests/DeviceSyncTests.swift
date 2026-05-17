import Foundation
import Testing
@testable import AlongCore

@Test
func deviceEnvelopeRoundTripsMissionEvent() throws {
    let missionID = try #require(MissionID("mission-sync-event"))
    let eventID = try #require(MissionEventID("event-sync-start"))
    let event = MissionEvent(
        id: eventID,
        missionID: missionID,
        sequence: 1,
        kind: .missionStarted(template: .stayWithMe, title: "Stay With Me", executionRole: .monitoring),
        occurredAt: Date(timeIntervalSince1970: 10)
    )
    let envelope = DeviceEnvelope(
        id: try #require(UUID(uuidString: "00000000-0000-0000-0000-000000000001")),
        source: .watch,
        missionID: missionID,
        sequence: 1,
        kind: .missionEvent,
        payload: event,
        createdAt: Date(timeIntervalSince1970: 11)
    )

    let data = try JSONEncoder().encode(envelope)
    let decoded = try JSONDecoder().decode(DeviceEnvelope<MissionEvent>.self, from: data)

    #expect(decoded == envelope)
}

@Test
func deviceEnvelopeRoundTripsMissionSnapshot() throws {
    let missionID = try #require(MissionID("mission-sync-snapshot"))
    let eventID = try #require(MissionEventID("event-sync-snapshot"))
    let snapshot = MissionSnapshot(
        id: missionID,
        title: "Getting Home",
        template: .stayWithMe,
        executionRole: .monitoring,
        status: .monitoring,
        summary: "Next check-in soon",
        lastSequence: 2,
        lastEventID: eventID,
        createdAt: Date(timeIntervalSince1970: 20),
        updatedAt: Date(timeIntervalSince1970: 21)
    )
    let envelope = DeviceEnvelope(
        id: try #require(UUID(uuidString: "00000000-0000-0000-0000-000000000002")),
        source: .phone,
        missionID: missionID,
        sequence: 2,
        kind: .missionSnapshot,
        payload: snapshot,
        createdAt: Date(timeIntervalSince1970: 22)
    )

    let data = try JSONEncoder().encode(envelope)
    let decoded = try JSONDecoder().decode(DeviceEnvelope<MissionSnapshot>.self, from: data)

    #expect(decoded == envelope)
}

@Test
func deviceSyncAcknowledgementRoundTrips() throws {
    let acknowledgement = DeviceSyncAcknowledgement(
        envelopeID: try #require(UUID(uuidString: "00000000-0000-0000-0000-000000000003")),
        source: .phone,
        receivedSequence: 4,
        createdAt: Date(timeIntervalSince1970: 30)
    )

    let data = try JSONEncoder().encode(acknowledgement)
    let decoded = try JSONDecoder().decode(DeviceSyncAcknowledgement.self, from: data)

    #expect(decoded == acknowledgement)
}

@Test
func dedupeWindowRejectsDuplicateAndEvictsOldestID() throws {
    let firstID = try #require(UUID(uuidString: "00000000-0000-0000-0000-000000000004"))
    let secondID = try #require(UUID(uuidString: "00000000-0000-0000-0000-000000000005"))
    let thirdID = try #require(UUID(uuidString: "00000000-0000-0000-0000-000000000006"))
    var window = DedupeWindow(capacity: 2)

    let firstRecord = window.record(firstID)
    let duplicateRecord = window.record(firstID)
    let secondRecord = window.record(secondID)
    let thirdRecord = window.record(thirdID)

    #expect(firstRecord)
    #expect(!duplicateRecord)
    #expect(secondRecord)
    #expect(thirdRecord)
    #expect(!window.contains(firstID))
    #expect(window.contains(secondID))
    #expect(window.contains(thirdID))
}

@Test
func sequenceTrackerRecordsOrderedEnvelopesPerSource() throws {
    var tracker = SequenceTracker()

    try tracker.record(makeStringEnvelope(source: .watch, sequence: 1))
    try tracker.record(makeStringEnvelope(source: .watch, sequence: 2))
    try tracker.record(makeStringEnvelope(source: .phone, sequence: 1))

    #expect(tracker.lastSequence(from: .watch) == 2)
    #expect(tracker.lastSequence(from: .phone) == 1)
    #expect(tracker.nextExpectedSequence(from: .watch) == 3)
}

@Test
func sequenceTrackerRejectsGapsAndStaleSequences() throws {
    var tracker = SequenceTracker()

    try tracker.record(makeStringEnvelope(source: .watch, sequence: 1))

    #expect(throws: SequenceTrackerError.sequenceGap(source: .watch, expected: 2, actual: 3)) {
        try tracker.record(makeStringEnvelope(source: .watch, sequence: 3))
    }
    #expect(throws: SequenceTrackerError.staleSequence(source: .watch, last: 1, actual: 1)) {
        try tracker.record(makeStringEnvelope(source: .watch, sequence: 1))
    }
    #expect(throws: SequenceTrackerError.nonPositiveSequence(source: .watch, actual: 0)) {
        try tracker.record(makeStringEnvelope(source: .watch, sequence: 0))
    }
}

private func makeStringEnvelope(source: DeviceSurface, sequence: Int64) throws -> DeviceEnvelope<String> {
    DeviceEnvelope(
        id: try #require(UUID(uuidString: "00000000-0000-0000-0000-000000000100")),
        source: source,
        missionID: nil,
        sequence: sequence,
        kind: .presence,
        payload: "ready",
        createdAt: Date(timeIntervalSince1970: TimeInterval(sequence))
    )
}
