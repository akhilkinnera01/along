import Foundation
import Testing
@testable import AlongCore

@Test
func missionEventStoreAppendsAndReadsEventsInSequence() async throws {
    let store: any MissionEventStore = InMemoryMissionEventStore()
    let missionID = try #require(MissionID("mission-store-contract"))
    let events = try makeEvents(for: missionID)

    for event in events {
        try await store.append(event)
    }

    #expect(try await store.events(for: missionID) == events)
}

@Test
func missionEventStoreListsUniqueMissionIDs() async throws {
    let store: any MissionEventStore = InMemoryMissionEventStore()
    let firstMissionID = try #require(MissionID("mission-a"))
    let secondMissionID = try #require(MissionID("mission-b"))

    try await store.append(makeStartEvent(id: "event-a", missionID: firstMissionID))
    try await store.append(makeStartEvent(id: "event-b", missionID: secondMissionID))
    try await store.append(makeStatusEvent(id: "event-c", missionID: firstMissionID, sequence: 2))

    #expect(try await store.allMissionIDs() == [firstMissionID, secondMissionID])
}

@Test
func missionEventStoreDeletesMissionHistory() async throws {
    let store: any MissionEventStore = InMemoryMissionEventStore()
    let missionID = try #require(MissionID("mission-delete"))
    let events = try makeEvents(for: missionID)

    for event in events {
        try await store.append(event)
    }

    try await store.deleteMission(missionID)

    #expect(try await store.events(for: missionID).isEmpty)
    #expect(try await store.allMissionIDs().isEmpty)
}

@Test
func missionEventStoreExportsMissionHistoryAsJSON() async throws {
    let store: any MissionEventStore = InMemoryMissionEventStore()
    let missionID = try #require(MissionID("mission-export"))
    let events = try makeEvents(for: missionID)

    for event in events {
        try await store.append(event)
    }

    let data = try await store.exportMission(missionID)
    let decoded = try JSONDecoder().decode([MissionEvent].self, from: data)

    #expect(decoded == events)
}

private actor InMemoryMissionEventStore: MissionEventStore {
    private var eventsByMissionID: [MissionID: [MissionEvent]] = [:]

    func append(_ event: MissionEvent) {
        eventsByMissionID[event.missionID, default: []].append(event)
        eventsByMissionID[event.missionID]?.sort { $0.sequence < $1.sequence }
    }

    func events(for missionID: MissionID) -> [MissionEvent] {
        eventsByMissionID[missionID] ?? []
    }

    func allMissionIDs() -> [MissionID] {
        eventsByMissionID.keys.sorted { $0.rawValue < $1.rawValue }
    }

    func deleteMission(_ missionID: MissionID) {
        eventsByMissionID.removeValue(forKey: missionID)
    }

    func exportMission(_ missionID: MissionID) throws -> Data {
        try JSONEncoder().encode(eventsByMissionID[missionID] ?? [])
    }
}

private func makeEvents(for missionID: MissionID) throws -> [MissionEvent] {
    [
        try makeStartEvent(id: "event-1", missionID: missionID),
        try makeStatusEvent(id: "event-2", missionID: missionID, sequence: 2)
    ]
}

private func makeStartEvent(id: String, missionID: MissionID) throws -> MissionEvent {
    MissionEvent(
        id: try #require(MissionEventID(id)),
        missionID: missionID,
        sequence: 1,
        kind: .missionStarted(template: .stayWithMe, title: "Stay With Me", executionRole: .monitoring),
        occurredAt: Date(timeIntervalSince1970: 1)
    )
}

private func makeStatusEvent(id: String, missionID: MissionID, sequence: Int) throws -> MissionEvent {
    MissionEvent(
        id: try #require(MissionEventID(id)),
        missionID: missionID,
        sequence: sequence,
        kind: .statusChanged(.monitoring),
        occurredAt: Date(timeIntervalSince1970: TimeInterval(sequence))
    )
}
