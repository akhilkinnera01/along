import AlongCore
import Foundation

public struct OpenAIHTTPResponse: Sendable {
    public let statusCode: Int
    public let data: Data

    public init(statusCode: Int, data: Data) {
        self.statusCode = statusCode
        self.data = data
    }
}

public typealias OpenAIHTTPClient = @Sendable (URLRequest) async throws -> OpenAIHTTPResponse

public enum OpenAIProviderError: Error, Equatable, Sendable {
    case invalidResponse
    case requestFailed(statusCode: Int)
    case missingText
}

public struct OpenAIProvider: ModelProvider {
    public static let defaultModel = "gpt-5-mini"
    public static let defaultEndpoint = URL(string: "https://api.openai.com/v1/responses")!
    public static let liveHTTPClient: OpenAIHTTPClient = { request in
        let (data, response) = try await URLSession.shared.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse else {
            throw OpenAIProviderError.invalidResponse
        }

        return OpenAIHTTPResponse(statusCode: httpResponse.statusCode, data: data)
    }

    private let responder: @Sendable (ModelRequest) async throws -> ModelResponse

    public init(responder: @escaping @Sendable (ModelRequest) async throws -> ModelResponse) {
        self.responder = responder
    }

    public init(
        apiKey: String,
        model: String = Self.defaultModel,
        endpoint: URL = Self.defaultEndpoint,
        httpClient: @escaping OpenAIHTTPClient = Self.liveHTTPClient
    ) {
        let client = OpenAIResponsesClient(
            apiKey: apiKey,
            model: model,
            endpoint: endpoint,
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

private struct OpenAIResponsesClient: Sendable {
    let apiKey: String
    let model: String
    let endpoint: URL
    let httpClient: OpenAIHTTPClient

    func respond(to request: ModelRequest) async throws -> ModelResponse {
        var urlRequest = URLRequest(url: endpoint)
        urlRequest.httpMethod = "POST"
        urlRequest.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
        urlRequest.httpBody = try JSONEncoder().encode(OpenAIResponsesRequest(model: model, input: request.userInput))

        let response = try await httpClient(urlRequest)
        guard (200..<300).contains(response.statusCode) else {
            throw OpenAIProviderError.requestFailed(statusCode: response.statusCode)
        }

        let payload = try JSONDecoder().decode(OpenAIResponsesResponse.self, from: response.data)
        guard let text = payload.textOutput else {
            throw OpenAIProviderError.missingText
        }

        return ModelResponse(text: text)
    }
}

private struct OpenAIResponsesRequest: Encodable {
    let model: String
    let input: String
}

private struct OpenAIResponsesResponse: Decodable {
    let output: [OutputItem]

    var textOutput: String? {
        let texts = output
            .flatMap(\.content)
            .compactMap(\.text)

        guard !texts.isEmpty else {
            return nil
        }

        return texts.joined(separator: "\n")
    }

    struct OutputItem: Decodable {
        let content: [ContentItem]

        init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            self.content = try container.decodeIfPresent([ContentItem].self, forKey: .content) ?? []
        }

        private enum CodingKeys: String, CodingKey {
            case content
        }
    }

    struct ContentItem: Decodable {
        let text: String?
    }
}
