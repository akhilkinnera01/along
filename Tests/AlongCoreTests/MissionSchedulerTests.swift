import Testing
@testable import AlongCore

@Test
func schedulerAllowsOneForegroundMission() async throws {
    let scheduler = MissionScheduler()
    let first = try #require(MissionID("mission-first"))
    let second = try #require(MissionID("mission-second"))

    let firstDecision = await scheduler.requestForeground(first)
    let secondDecision = await scheduler.requestForeground(second)

    #expect(firstDecision == .granted)
    #expect(secondDecision == .queued(position: 1))
    #expect(await scheduler.currentForeground() == first)

    let next = await scheduler.releaseForeground(first)

    #expect(next == second)
    #expect(await scheduler.currentForeground() == second)
}
