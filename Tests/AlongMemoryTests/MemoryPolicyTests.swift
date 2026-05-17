import Foundation
import Testing
@testable import AlongCore
@testable import AlongMemory

@Test
func memoryPolicyRejectsSilentWrites() throws {
    let missionID = try #require(MissionID("mission-memory"))
    let policy = MemoryPolicy(blockedCategories: [])
    let candidate = MemoryCandidate(
        missionID: missionID,
        scope: .preference,
        text: "Prefers quiet haptics"
    )

    #expect(throws: MemoryPolicyError.silentWriteDenied) {
        try policy.makeRecord(
            from: candidate,
            approvedByUser: false,
            at: Date(timeIntervalSince1970: 0)
        )
    }
}

@Test
func memoryPolicyRejectsSensitiveCategoriesByDefault() throws {
    let missionID = try #require(MissionID("mission-sensitive"))
    let policy = MemoryPolicy()
    let candidate = MemoryCandidate(
        missionID: missionID,
        scope: .person,
        text: "Sensitive detail",
        sensitiveCategories: [.health]
    )

    #expect(throws: MemoryPolicyError.sensitiveCategoryDenied([.health])) {
        try policy.makeRecord(
            from: candidate,
            approvedByUser: true,
            at: Date(timeIntervalSince1970: 0)
        )
    }
}

@Test
func memoryPolicyCreatesApprovedNonSensitiveRecord() throws {
    let missionID = try #require(MissionID("mission-approved"))
    let policy = MemoryPolicy(blockedCategories: [])
    let candidate = MemoryCandidate(
        missionID: missionID,
        scope: .routine,
        text: "Starts focus blocks at 9 AM"
    )

    let record = try policy.makeRecord(
        from: candidate,
        approvedByUser: true,
        at: Date(timeIntervalSince1970: 0)
    )

    #expect(record.missionID == missionID)
    #expect(record.scope == .routine)
    #expect(record.text == "Starts focus blocks at 9 AM")
}
