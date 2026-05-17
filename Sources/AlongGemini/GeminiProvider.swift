import AlongCore
import Foundation

public struct GeminiHTTPResponse: Sendable {
    public let statusCode: Int
    public let data: Data

    public init(statusCode: Int, data: Data) {
        self.statusCode = statusCode
        self.data = data
    }
}

public typealias GeminiHTTPClient = @Sendable (URLRequest) async throws -> GeminiHTTPResponse

public enum GeminiProviderError: Error, Equatable, Sendable {
    case invalidResponse
    case invalidEndpoint
    case invalidModel
    case requestFailed(statusCode: Int)
    case missingText
}

public struct GeminiProvider: ModelProvider {
    public static let defaultModel = "gemini-3-flash-preview"
    public static let defaultEndpointBase = URL(string: "https://generativelanguage.googleapis.com/v1beta")!
    public static let liveHTTPClient: GeminiHTTPClient = { request in
        let (data, response) = try await URLSession.shared.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse else {
            throw GeminiProviderError.invalidResponse
        }

        return GeminiHTTPResponse(statusCode: httpResponse.statusCode, data: data)
    }

    private let responder: @Sendable (ModelRequest) async throws -> ModelResponse

    public init(responder: @escaping @Sendable (ModelRequest) async throws -> ModelResponse) {
        self.responder = responder
    }

    public init(
        apiKey: String,
        model: String = Self.defaultModel,
        endpointBase: URL = Self.defaultEndpointBase,
        httpClient: @escaping GeminiHTTPClient = Self.liveHTTPClient
    ) {
        let client = GeminiGenerateContentClient(
            apiKey: apiKey,
            model: model,
            endpointBase: endpointBase,
            httpClient: httpClient
        )
        self.responder = { request in
            try await client.respond(to: request)
        }
    }

    public func respond(to request: ModelRequest) async throws -> ModelResponse {
        try await responder(request)
    }
}

private struct GeminiGenerateContentClient: Sendable {
    let apiKey: String
    let model: String
    let endpointBase: URL
    let httpClient: GeminiHTTPClient

    func respond(to request: ModelRequest) async throws -> ModelResponse {
        var urlRequest = URLRequest(url: try endpoint())
        urlRequest.httpMethod = "POST"
        urlRequest.setValue(apiKey, forHTTPHeaderField: "x-goog-api-key")
        urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
        urlRequest.httpBody = try JSONEncoder().encode(GeminiGenerateContentRequest(text: request.userInput))

        let response = try await httpClient(urlRequest)
        guard (200..<300).contains(response.statusCode) else {
            throw GeminiProviderError.requestFailed(statusCode: response.statusCode)
        }

        let payload = try JSONDecoder().decode(GeminiGenerateContentResponse.self, from: response.data)
        guard let text = payload.textOutput else {
            throw GeminiProviderError.missingText
        }

        return ModelResponse(text: text)
    }

    private func endpoint() throws -> URL {
        let normalizedModel = model.hasPrefix("models/")
            ? String(model.dropFirst("models/".count))
            : model

        guard !normalizedModel.isEmpty, !normalizedModel.contains("/") else {
            throw GeminiProviderError.invalidModel
        }

        guard var components = URLComponents(url: endpointBase, resolvingAgainstBaseURL: false) else {
            throw GeminiProviderError.invalidEndpoint
        }

        let basePath = components.path.trimmingCharacters(in: CharacterSet(charactersIn: "/"))
        components.path = ([basePath, "models", "\(normalizedModel):generateContent"])
            .filter { !$0.isEmpty }
            .joined(separator: "/")
        components.path = "/" + components.path
        components.query = nil
        components.fragment = nil

        guard let url = components.url else {
            throw GeminiProviderError.invalidEndpoint
        }

        return url
    }
}

private struct GeminiGenerateContentRequest: Encodable {
    let contents: [Content]

    init(text: String) {
        self.contents = [Content(parts: [Part(text: text)])]
    }

    struct Content: Encodable {
        let parts: [Part]
    }

    struct Part: Encodable {
        let text: String
    }
}

private struct GeminiGenerateContentResponse: Decodable {
    let candidates: [Candidate]?

    var textOutput: String? {
        let texts = (candidates ?? [])
            .flatMap { $0.content?.parts ?? [] }
            .compactMap(\.text)

        guard !texts.isEmpty else {
            return nil
        }

        return texts.joined(separator: "\n")
    }

    struct Candidate: Decodable {
        let content: Content?
    }

    struct Content: Decodable {
        let parts: [Part]?
    }

    struct Part: Decodable {
        let text: String?
    }
}
