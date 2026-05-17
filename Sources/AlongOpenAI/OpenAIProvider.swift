import AlongCore

public struct OpenAIProvider: ModelProvider {
    private let responder: @Sendable (ModelRequest) async throws -> ModelResponse

    public init(responder: @escaping @Sendable (ModelRequest) async throws -> ModelResponse) {
        self.responder = responder
    }

    public func respond(to request: ModelRequest) async throws -> ModelResponse {
        try await responder(request)
    }
}

