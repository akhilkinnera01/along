public enum SchedulerDecision: Equatable, Sendable {
    case granted
    case alreadyForeground
    case monitoringContinues
    case queued(position: Int)
}

public actor MissionScheduler {
    private var foregroundMissionID: MissionID?
    private var monitoringMissionIDs: Set<MissionID>
    private var queue: [MissionID]

    public init(queue: [MissionID] = [], monitoringMissionIDs: Set<MissionID> = []) {
        self.queue = queue
        self.monitoringMissionIDs = monitoringMissionIDs
    }

    public func requestForeground(
        _ missionID: MissionID,
        role: MissionExecutionRole = .foreground
    ) -> SchedulerDecision {
        if role == .monitoring {
            monitoringMissionIDs.insert(missionID)
            queue.removeAll { $0 == missionID }
            if foregroundMissionID == missionID {
                foregroundMissionID = queue.isEmpty ? nil : queue.removeFirst()
            }
            return .monitoringContinues
        }

        if foregroundMissionID == missionID {
            return .alreadyForeground
        }

        if foregroundMissionID == nil {
            monitoringMissionIDs.remove(missionID)
            foregroundMissionID = missionID
            return .granted
        }

        if let index = queue.firstIndex(of: missionID) {
            return .queued(position: index + 1)
        }

        queue.append(missionID)
        monitoringMissionIDs.remove(missionID)
        return .queued(position: queue.count)
    }

    @discardableResult
    public func releaseForeground(_ missionID: MissionID) -> MissionID? {
        guard foregroundMissionID == missionID else {
            queue.removeAll { $0 == missionID }
            monitoringMissionIDs.remove(missionID)
            return foregroundMissionID
        }

        foregroundMissionID = queue.isEmpty ? nil : queue.removeFirst()
        return foregroundMissionID
    }

    public func currentForeground() -> MissionID? {
        foregroundMissionID
    }

    public func monitoringMissions() -> [MissionID] {
        Array(monitoringMissionIDs)
    }
}
