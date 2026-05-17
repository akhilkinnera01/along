import Testing
@testable import AlongCore

@Test
func stayWithMeAsksForModeWhenMissing() {
    let template = StayWithMeTemplate()
    let decision = template.draft(
        from: MissionStartRequest(template: .stayWithMe, spokenText: "Stay with me until I get home")
    )

    guard case .needsClarification(let question) = decision else {
        Issue.record("Expected a clarification question.")
        return
    }

    #expect(question.title == "How should Stay With Me check in?")
    #expect(question.options == ["Local Check-In", "Trusted Escalation"])
}

@Test
func stayWithMeDefaultsLocalCheckInDraft() {
    let template = StayWithMeTemplate()
    let decision = template.draft(
        from: MissionStartRequest(
            template: .stayWithMe,
            spokenText: "Stay with me until I get home",
            mode: .localCheckIn
        )
    )

    guard case .ready(let draft) = decision else {
        Issue.record("Expected a ready mission draft.")
        return
    }

    #expect(draft.title == "Getting Home")
    #expect(draft.template == .stayWithMe)
    #expect(draft.mode == .localCheckIn)
    #expect(draft.durationMinutes == 60)
    #expect(draft.checkInIntervalMinutes == 5)
}

@Test
func stayWithMePreservesExplicitTrustedEscalationMode() {
    let template = StayWithMeTemplate()
    let decision = template.draft(
        from: MissionStartRequest(
            template: .stayWithMe,
            spokenText: "Stay with me",
            mode: .trustedEscalation
        )
    )

    guard case .ready(let draft) = decision else {
        Issue.record("Expected a ready mission draft.")
        return
    }

    #expect(draft.mode == .trustedEscalation)
    #expect(draft.title == "Stay With Me")
}

@Test
func stayWithMeRejectsOutOfRangeDuration() {
    let template = StayWithMeTemplate()
    let decision = template.draft(
        from: MissionStartRequest(
            template: .stayWithMe,
            spokenText: "Stay with me",
            mode: .localCheckIn,
            durationMinutes: 4
        )
    )

    #expect(decision == .rejected("Duration must be between 5 and 480 minutes."))
}

@Test
func stayWithMeRejectsOutOfRangeInterval() {
    let template = StayWithMeTemplate()
    let decision = template.draft(
        from: MissionStartRequest(
            template: .stayWithMe,
            spokenText: "Stay with me",
            mode: .trustedEscalation,
            checkInIntervalMinutes: 61
        )
    )

    #expect(decision == .rejected("Check-in interval must be between 1 and 60 minutes."))
}
