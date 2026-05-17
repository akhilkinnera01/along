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

@Test
func schedulerKeepsMonitoringMissionActiveWhileQuickMissionRuns() async throws {
    let scheduler = MissionScheduler()
    let monitoring = try #require(MissionID("mission-monitoring"))
    let quick = try #require(MissionID("mission-quick"))

    let monitoringDecision = await scheduler.requestForeground(monitoring, role: .monitoring)
    let quickDecision = await scheduler.requestForeground(quick, role: .quick)

    #expect(monitoringDecision == .monitoringContinues)
    #expect(quickDecision == .granted)
    #expect(await scheduler.currentForeground() == quick)
    #expect(await scheduler.monitoringMissions().contains(monitoring))
}

@Test
func schedulerMovesForegroundMissionToMonitoringAndPromotesQueuedMission() async throws {
    let scheduler = MissionScheduler()
    let stayWithMe = try #require(MissionID("mission-stay-with-me"))
    let quick = try #require(MissionID("mission-quick"))

    _ = await scheduler.requestForeground(stayWithMe)
    _ = await scheduler.requestForeground(quick, role: .quick)

    let monitoringDecision = await scheduler.requestForeground(stayWithMe, role: .monitoring)

    #expect(monitoringDecision == .monitoringContinues)
    #expect(await scheduler.currentForeground() == quick)
    #expect(await scheduler.monitoringMissions().contains(stayWithMe))
}

@Test
func schedulerQueuesSecondQuickMission() async throws {
    let scheduler = MissionScheduler()
    let firstQuick = try #require(MissionID("mission-quick-one"))
    let secondQuick = try #require(MissionID("mission-quick-two"))

    let firstDecision = await scheduler.requestForeground(firstQuick, role: .quick)
    let secondDecision = await scheduler.requestForeground(secondQuick, role: .quick)

    #expect(firstDecision == .granted)
    #expect(secondDecision == .queued(position: 1))
    #expect(await scheduler.currentForeground() == firstQuick)
}

@Test
func schedulerReleaseLeavesMonitoringMissionActive() async throws {
    let scheduler = MissionScheduler()
    let monitoring = try #require(MissionID("mission-monitoring"))
    let quick = try #require(MissionID("mission-quick"))

    _ = await scheduler.requestForeground(monitoring, role: .monitoring)
    _ = await scheduler.requestForeground(quick, role: .quick)

    let next = await scheduler.releaseForeground(quick)

    #expect(next == nil)
    #expect(await scheduler.currentForeground() == nil)
    #expect(await scheduler.monitoringMissions().contains(monitoring))
}
