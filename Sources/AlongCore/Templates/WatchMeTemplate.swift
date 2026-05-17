public enum MissionStartMode: String, Codable, Equatable, Sendable {
    case localCheckIn
    case trustedEscalation
}

public struct MissionStartRequest: Codable, Equatable, Sendable {
    public let template: MissionTemplateKind
    public let spokenText: String
    public let mode: MissionStartMode?
    public let durationMinutes: Int?
    public let checkInIntervalMinutes: Int?

    public init(
        template: MissionTemplateKind,
        spokenText: String,
        mode: MissionStartMode? = nil,
        durationMinutes: Int? = nil,
        checkInIntervalMinutes: Int? = nil
    ) {
        self.template = template
        self.spokenText = spokenText
        self.mode = mode
        self.durationMinutes = durationMinutes
        self.checkInIntervalMinutes = checkInIntervalMinutes
    }
}

public enum MissionStartDecision: Equatable, Sendable {
    case ready(MissionDraft)
    case needsClarification(ClarifyingQuestion)
    case rejected(String)
}

public struct MissionDraft: Codable, Equatable, Sendable {
    public let title: String
    public let template: MissionTemplateKind
    public let mode: MissionStartMode
    public let durationMinutes: Int
    public let checkInIntervalMinutes: Int?

    public init(
        title: String,
        template: MissionTemplateKind,
        mode: MissionStartMode,
        durationMinutes: Int,
        checkInIntervalMinutes: Int?
    ) {
        self.title = title
        self.template = template
        self.mode = mode
        self.durationMinutes = durationMinutes
        self.checkInIntervalMinutes = checkInIntervalMinutes
    }
}

public struct ClarifyingQuestion: Codable, Equatable, Sendable {
    public let title: String
    public let options: [String]

    public init(title: String, options: [String]) {
        self.title = title
        self.options = options
    }
}

public protocol WatchMeTemplate: Sendable {
    var kind: MissionTemplateKind { get }
    var displayName: String { get }

    func draft(from request: MissionStartRequest) -> MissionStartDecision
}

enum WatchMeTemplateRules {
    static let durationRange = 5...480
    static let checkInIntervalRange = 1...60

    static func duration(from request: MissionStartRequest, default defaultValue: Int) -> TemplateRuleValue<Int> {
        let duration = request.durationMinutes ?? defaultValue
        guard durationRange.contains(duration) else {
            return .rejected("Duration must be between 5 and 480 minutes.")
        }
        return .accepted(duration)
    }

    static func interval(from request: MissionStartRequest, default defaultValue: Int) -> TemplateRuleValue<Int> {
        let interval = request.checkInIntervalMinutes ?? defaultValue
        guard checkInIntervalRange.contains(interval) else {
            return .rejected("Check-in interval must be between 1 and 60 minutes.")
        }
        return .accepted(interval)
    }
}

enum TemplateRuleValue<Value> {
    case accepted(Value)
    case rejected(String)
}
