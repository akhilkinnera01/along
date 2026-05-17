public struct FocusWithMeTemplate: WatchMeTemplate {
    public let kind: MissionTemplateKind = .focusWithMe
    public let displayName = "Focus With Me"

    public init() {}

    public func draft(from request: MissionStartRequest) -> MissionStartDecision {
        guard request.template == kind else {
            return .rejected("Template mismatch.")
        }

        if request.mode == .trustedEscalation {
            return .rejected("Focus With Me supports local check-ins only.")
        }

        switch WatchMeTemplateRules.duration(from: request, default: 60) {
        case .rejected(let message):
            return .rejected(message)
        case .accepted(let duration):
            switch WatchMeTemplateRules.interval(from: request, default: 15) {
            case .rejected(let message):
                return .rejected(message)
            case .accepted(let interval):
                return .ready(
                    MissionDraft(
                        title: displayName,
                        template: kind,
                        mode: .localCheckIn,
                        durationMinutes: duration,
                        checkInIntervalMinutes: interval
                    )
                )
            }
        }
    }
}
