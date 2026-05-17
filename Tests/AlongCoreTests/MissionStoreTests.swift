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
