public enum RuntimeFailureCode: String, Codable, Equatable, Sendable {
    case missionQueued
    case missingTool
    case approvalDenied
    case providerFailed
    case toolFailed
    case cancelled
    case timedOut
}

public struct RuntimeFailure: Codable, Equatable, Sendable {
    public let code: RuntimeFailureCode
    public let message: String

    public init(code: RuntimeFailureCode, message: String) {
        self.code = code
        self.message = message
    }
}

