import Testing
@testable import AlongCore

@Test
func runWithMeAcceptsDurationAndDefaultsInterval() {
    let template = RunWithMeTemplate()
    let decision = template.draft(
        from: MissionStartRequest(
            template: .runWithMe,
            spokenText: "Watch my run for 40 minutes",
            durationMinutes: 40
        )
    )

    guard case .ready(let draft) = decision else {
        Issue.record("Expected a ready mission draft.")
        return
    }

    #expect(draft.title == "Run With Me")
    #expect(draft.template == .runWithMe)
    #expect(draft.mode == .localCheckIn)
    #expect(draft.durationMinutes == 40)
    #expect(draft.checkInIntervalMinutes == 10)
}

@Test
func focusWithMeDefaultsToLocalMode() {
    let template = FocusWithMeTemplate()
    let decision = template.draft(
        from: MissionStartRequest(
            template: .focusWithMe,
            spokenText: "Keep me focused for one hour",
            durationMinutes: 60
        )
    )

    guard case .ready(let draft) = decision else {
        Issue.record("Expected a ready mission draft.")
        return
    }

    #expect(draft.title == "Focus With Me")
    #expect(draft.template == .focusWithMe)
    #expect(draft.mode == .localCheckIn)
    #expect(draft.checkInIntervalMinutes == 15)
}

@Test
func focusWithMeRejectsTrustedEscalation() {
    let template = FocusWithMeTemplate()
    let decision = template.draft(
        from: MissionStartRequest(
            template: .focusWithMe,
            spokenText: "Keep me focused for one hour",
            mode: .trustedEscalation
        )
    )

    #expect(decision == .rejected("Focus With Me supports local check-ins only."))
}

@Test
func captureForMeCreatesLocalCaptureDraft() {
    let template = CaptureForMeTemplate()
    let decision = template.draft(
        from: MissionStartRequest(
            template: .captureForMe,
            spokenText: "Capture this before I forget"
        )
    )

    guard case .ready(let draft) = decision else {
        Issue.record("Expected a ready mission draft.")
        return
    }

    #expect(draft.title == "Capture For Me")
    #expect(draft.template == .captureForMe)
    #expect(draft.mode == .localCheckIn)
    #expect(draft.checkInIntervalMinutes == nil)
}
