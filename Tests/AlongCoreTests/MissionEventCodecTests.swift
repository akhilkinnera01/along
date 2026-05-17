import Foundation
import Testing
@testable import AlongCore

@Test
func missionEventKindEncodesExplicitType() throws {
    let kind = MissionEventKind.statusChanged(.monitoring)
    let data = try JSONEncoder().encode(kind)
    let json = try #require(String(data: data, encoding: .utf8))

    #expect(json.contains(#""type":"statusChanged""#))
    #expect(json.contains(#""status":"monitoring""#))
}

@Test
func missionEventRoundTripsThroughJSON() throws {
    let missionID = try #require(MissionID("mission-codec"))
    let eventID = try #require(MissionEventID("event-codec"))
    let event = MissionEvent(
        id: eventID,
        missionID: missionID,
        sequence: 2,
        kind: .toolFailed(
            "send_message",
            RuntimeFailure(code: .toolFailed, message: "Tool execution failed.")
        ),
        occurredAt: Date(timeIntervalSince1970: 100)
    )

    let data = try JSONEncoder().encode(event)
    let decoded = try JSONDecoder().decode(MissionEvent.self, from: data)

    #expect(decoded == event)
    #expect(decoded.kind.type == .toolFailed)
}

