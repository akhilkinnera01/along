import Foundation

public protocol MissionEventStore: Sendable {
    func append(_ event: MissionEvent) async throws
    func events(for missionID: MissionID) async throws -> [MissionEvent]
    func allMissionIDs() async throws -> [MissionID]
    func deleteMission(_ missionID: MissionID) async throws
    func exportMission(_ missionID: MissionID) async throws -> Data
}
