import AlongApple
import AlongCore
import Foundation
import Testing

@Test
func localMissionStoreAppendsAndReadsEvents() async throws {
    let fixture = try LocalMissionStoreFixture()
    defer { try? fixture.cleanUp() }
    let missionID = try #require(MissionID("mission-local-store"))
    let events = try makeEvents(for: missionID)

    for event in events {
        try await fixture.store.append(event)
    }

    #expect(try await fixture.store.events(for: missionID) == events)
}

@Test
func localMissionStoreListsMissionIDs() async throws {
    let fixture = try LocalMissionStoreFixture()
    defer { try? fixture.cleanUp() }
    let firstMissionID = try #require(MissionID("mission-a"))
    let secondMissionID = try #require(MissionID("mission-b"))

    try await fixture.store.append(makeStartEvent(id: "event-a", missionID: firstMissionID))
    try await fixture.store.append(makeStartEvent(id: "event-b", missionID: secondMissionID))

    #expect(try await fixture.store.allMissionIDs() == [firstMissionID, secondMissionID])
}

@Test
func localMissionStoreDeletesMissionHistory() async throws {
    let fixture = try LocalMissionStoreFixture()
    defer { try? fixture.cleanUp() }
    let missionID = try #require(MissionID("mission-delete"))

    for event in try makeEvents(for: missionID) {
        try await fixture.store.append(event)
    }

    try await fixture.store.deleteMission(missionID)

    #expect(try await fixture.store.events(for: missionID).isEmpty)
    #expect(try await fixture.store.allMissionIDs().isEmpty)
}

@Test
func localMissionStoreExportsMissionHistoryAsJSON() async throws {
    let fixture = try LocalMissionStoreFixture()
    defer { try? fixture.cleanUp() }
    let missionID = try #require(MissionID("mission-export"))
    let events = try makeEvents(for: missionID)

    for event in events {
        try await fixture.store.append(event)
    }

    let data = try await fixture.store.exportMission(missionID)
    let decoded = try JSONDecoder().decode([MissionEvent].self, from: data)

    #expect(decoded == events)
}

@Test
func localMissionStoreDoesNotUseRawMissionIDAsFilePath() async throws {
    let fixture = try LocalMissionStoreFixture()
    defer { try? fixture.cleanUp() }
    let missionID = try #require(MissionID("../escape"))
    let event = try makeStartEvent(id: "event-escape", missionID: missionID)

    try await fixture.store.append(event)

    let parentURL = fixture.directoryURL.deletingLastPathComponent()
    let escapedURL = parentURL.appendingPathComponent("escape")

    #expect(!FileManager.default.fileExists(atPath: escapedURL.path))
    #expect(try await fixture.store.events(for: missionID) == [event])
}

private struct LocalMissionStoreFixture {
    let directoryURL: URL
    let store: LocalMissionStore

    init() throws {
        self.directoryURL = FileManager.default.temporaryDirectory
            .appendingPathComponent("along-local-store-\(UUID().uuidString)", isDirectory: true)
        self.store = try LocalMissionStore(directoryURL: directoryURL)
    }

    func cleanUp() throws {
        if FileManager.default.fileExists(atPath: directoryURL.path) {
            try FileManager.default.removeItem(at: directoryURL)
        }
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
