public enum SchedulerDecision: Equatable, Sendable {
    case granted
    case alreadyForeground
    case queued(position: Int)
}

public actor MissionScheduler {
    private var foregroundMissionID: MissionID?
    private var queue: [MissionID]

    public init(queue: [MissionID] = []) {
        self.queue = queue
    }

    public func requestForeground(_ missionID: MissionID) -> SchedulerDecision {
        if foregroundMissionID == missionID {
            return .alreadyForeground
        }

        if foregroundMissionID == nil {
            foregroundMissionID = missionID
            return .granted
        }

        if let index = queue.firstIndex(of: missionID) {
            return .queued(position: index + 1)
        }

        queue.append(missionID)
        return .queued(position: queue.count)
    }

    @discardableResult
    public func releaseForeground(_ missionID: MissionID) -> MissionID? {
        guard foregroundMissionID == missionID else {
            queue.removeAll { $0 == missionID }
            return foregroundMissionID
        }

        foregroundMissionID = queue.isEmpty ? nil : queue.removeFirst()
        return foregroundMissionID
    }

    public func currentForeground() -> MissionID? {
        foregroundMissionID
    }
}

