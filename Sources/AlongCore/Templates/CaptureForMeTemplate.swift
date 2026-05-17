public struct CaptureForMeTemplate: WatchMeTemplate {
    public let kind: MissionTemplateKind = .captureForMe
    public let displayName = "Capture For Me"

    public init() {}

    public func draft(from request: MissionStartRequest) -> MissionStartDecision {
        guard request.template == kind else {
            return .rejected("Template mismatch.")
        }

        if request.mode == .trustedEscalation {
            return .rejected("Capture For Me supports local capture only.")
        }

        switch WatchMeTemplateRules.duration(from: request, default: 60) {
        case .rejected(let message):
            return .rejected(message)
        case .accepted(let duration):
            return .ready(
                MissionDraft(
                    title: displayName,
                    template: kind,
                    mode: .localCheckIn,
                    durationMinutes: duration,
                    checkInIntervalMinutes: nil
                )
            )
        }
    }
}
