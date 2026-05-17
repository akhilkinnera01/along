import Foundation
import Testing
@testable import AlongCore

@Test
func missionStoreCreatesMissionAndReplaysEvents() async throws {
    let store = MissionStore()
    let missionID = try #require(MissionID("mission-test"))
    let start = Date(timeIntervalSince1970: 100)

    let snapshot = try await store.createMission(
        id: missionID,
        title: "Stay With Me",
        template: .stayWithMe,
        at: start
    )

    #expect(snapshot.status == .working)
    #expect(snapshot.lastSequence == 1)

    let updateDate = Date(timeIntervalSince1970: 120)
    try await store.append(.summaryChanged("Waiting for check-in"), to: missionID, at: updateDate)
    try await store.append(.statusChanged(.monitoring), to: missionID, at: updateDate)

    let updated = try await store.snapshot(for: missionID)
    let events = try await store.events(for: missionID)

    #expect(updated.summary == "Waiting for check-in")
    #expect(updated.status == .monitoring)
    #expect(updated.lastSequence == 3)
    #expect(events.count == 3)
}

@Test
func missionStoreRejectsDuplicateMissionIDs() async throws {
    let store = MissionStore()
    let missionID = try #require(MissionID("mission-duplicate"))
    let date = Date(timeIntervalSince1970: 0)

    try await store.createMission(id: missionID, title: "Focus With Me", template: .focusWithMe, at: date)

    await #expect(throws: MissionStoreError.missionAlreadyExists(missionID)) {
        try await store.createMission(id: missionID, title: "Focus With Me", template: .focusWithMe, at: date)
    }
}

@Test
func missionStoreReplaysValidEventHistory() throws {
    let missionID = try #require(MissionID("mission-replay"))
    let events = [
        try event(
            id: "event-1",
            missionID: missionID,
            sequence: 1,
            kind: .missionStarted(template: .stayWithMe, title: "Stay With Me")
        ),
        try event(
            id: "event-2",
            missionID: missionID,
            sequence: 2,
            kind: .summaryChanged("Waiting for check-in")
        ),
        try event(
            id: "event-3",
            missionID: missionID,
            sequence: 3,
            kind: .statusChanged(.monitoring)
        )
    ]

    let snapshot = try MissionStore.replay(events: events)

    #expect(snapshot.id == missionID)
    #expect(snapshot.title == "Stay With Me")
    #expect(snapshot.template == .stayWithMe)
    #expect(snapshot.summary == "Waiting for check-in")
    #expect(snapshot.status == .monitoring)
    #expect(snapshot.lastSequence == 3)
}

@Test
func missionStoreRejectsEmptyReplayHistory() throws {
    #expect(throws: MissionReplayError.emptyHistory) {
        _ = try MissionStore.replay(events: [])
    }
}

@Test
func missionStoreRejectsReplayWithoutStartEvent() throws {
    let missionID = try #require(MissionID("mission-no-start"))
    let events = [
        try event(
            id: "event-no-start",
            missionID: missionID,
            sequence: 1,
            kind: .statusChanged(.monitoring)
        )
    ]

    #expect(throws: MissionReplayError.firstEventNotMissionStarted) {
        _ = try MissionStore.replay(events: events)
    }
}

@Test
func missionStoreRejectsReplayWithMixedMissionIDs() throws {
    let firstMissionID = try #require(MissionID("mission-one"))
    let secondMissionID = try #require(MissionID("mission-two"))
    let events = [
        try event(
            id: "event-one",
            missionID: firstMissionID,
            sequence: 1,
            kind: .missionStarted(template: .stayWithMe, title: "Stay With Me")
        ),
        try event(
            id: "event-two",
            missionID: secondMissionID,
            sequence: 2,
            kind: .statusChanged(.monitoring)
        )
    ]

    #expect(throws: MissionReplayError.mixedMissionIDs(expected: firstMissionID, actual: secondMissionID)) {
        _ = try MissionStore.replay(events: events)
    }
}

@Test
func missionStoreRejectsReplayWithSequenceGap() throws {
    let missionID = try #require(MissionID("mission-gap"))
    let events = [
        try event(
            id: "event-one",
            missionID: missionID,
            sequence: 1,
            kind: .missionStarted(template: .stayWithMe, title: "Stay With Me")
        ),
        try event(
            id: "event-three",
            missionID: missionID,
            sequence: 3,
            kind: .statusChanged(.monitoring)
        )
    ]

    #expect(throws: MissionReplayError.sequenceGap(expected: 2, actual: 3)) {
        _ = try MissionStore.replay(events: events)
    }
}

private func event(
    id: String,
    missionID: MissionID,
    sequence: Int,
    kind: MissionEventKind
) throws -> MissionEvent {
    MissionEvent(
        id: try #require(MissionEventID(id)),
        missionID: missionID,
        sequence: sequence,
        kind: kind,
        occurredAt: Date(timeIntervalSince1970: TimeInterval(sequence))
    )
}
