public struct RunWithMeTemplate: WatchMeTemplate {
    public let kind: MissionTemplateKind = .runWithMe
    public let displayName = "Run With Me"

    public init() {}

    public func draft(from request: MissionStartRequest) -> MissionStartDecision {
        guard request.template == kind else {
            return .rejected("Template mismatch.")
        }

        switch WatchMeTemplateRules.duration(from: request, default: 40) {
        case .rejected(let message):
            return .rejected(message)
        case .accepted(let duration):
            switch WatchMeTemplateRules.interval(from: request, default: 10) {
            case .rejected(let message):
                return .rejected(message)
            case .accepted(let interval):
                return .ready(
                    MissionDraft(
                        title: displayName,
                        template: kind,
                        mode: request.mode ?? .localCheckIn,
                        durationMinutes: duration,
                        checkInIntervalMinutes: interval
                    )
                )
            }
        }
    }
}
