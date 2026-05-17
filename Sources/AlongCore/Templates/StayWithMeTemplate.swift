public struct StayWithMeTemplate: WatchMeTemplate {
    public let kind: MissionTemplateKind = .stayWithMe
    public let displayName = "Stay With Me"

    public init() {}

    public func draft(from request: MissionStartRequest) -> MissionStartDecision {
        guard request.template == kind else {
            return .rejected("Template mismatch.")
        }

        guard let mode = request.mode else {
            return .needsClarification(
                ClarifyingQuestion(
                    title: "How should Stay With Me check in?",
                    options: ["Local Check-In", "Trusted Escalation"]
                )
            )
        }

        switch WatchMeTemplateRules.duration(from: request, default: 60) {
        case .rejected(let message):
            return .rejected(message)
        case .accepted(let duration):
            switch WatchMeTemplateRules.interval(from: request, default: 5) {
            case .rejected(let message):
                return .rejected(message)
            case .accepted(let interval):
                return .ready(
                    MissionDraft(
                        title: title(for: request.spokenText),
                        template: kind,
                        mode: mode,
                        durationMinutes: duration,
                        checkInIntervalMinutes: interval
                    )
                )
            }
        }
    }

    private func title(for spokenText: String) -> String {
        if spokenText.lowercased().contains("home") {
            return "Getting Home"
        }
        return displayName
    }
}
