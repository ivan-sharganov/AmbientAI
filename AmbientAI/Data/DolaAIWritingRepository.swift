import Foundation

final class DolaAIWritingRepository: AIWritingRepository {
    private let session: URLSession
    private let baseURL: URL
    private let appID: String
    private let bearerToken: String
    private let userIDProvider: () -> String

    init(
        baseURL: URL = URL(string: "https://nebulaapps.site")!,
        appID: String,
        bearerToken: String,
        userIDProvider: @escaping () -> String,
        session: URLSession = .shared
    ) {
        self.baseURL = baseURL
        self.appID = appID
        self.bearerToken = bearerToken
        self.userIDProvider = userIDProvider
        self.session = session
    }

    func process(_ requestModel: AIWritingRequestModel) async throws -> String {
        let userID = userIDProvider()
        guard !userID.isEmpty else { throw DolaAPIError.missingUserID }

        let endpoint = baseURL.appendingPathComponent("dola").appendingPathComponent("ai-writing")
        guard var components = URLComponents(url: endpoint, resolvingAgainstBaseURL: false) else {
            throw DolaAPIError.invalidURL
        }
        components.queryItems = [
            URLQueryItem(name: "user_id", value: userID),
            URLQueryItem(name: "app_id", value: appID)
        ]
        guard let url = components.url else { throw DolaAPIError.invalidURL }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.setValue("Bearer \(bearerToken)", forHTTPHeaderField: "Authorization")
        request.httpBody = try JSONEncoder().encode(AIWritingRequestDTO(model: requestModel))

        let (data, response) = try await session.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse else {
            throw DolaAPIError.invalidResponse
        }
        guard 200..<300 ~= httpResponse.statusCode else {
            throw DolaAPIError.httpError(statusCode: httpResponse.statusCode, message: nil)
        }

        return try JSONDecoder().decode(AIWritingResponseDTO.self, from: data).resultText
    }
}

private struct AIWritingRequestDTO: Encodable {
    let text: String
    let improve: Bool
    let rewrite: Bool
    let fixGrammar: Bool
    let shorten: Bool
    let translateTo: String?
    let style: String?

    init(model: AIWritingRequestModel) {
        text = model.text
        improve = model.improve
        rewrite = model.rewrite
        fixGrammar = model.fixGrammar
        shorten = model.shorten
        translateTo = model.translateTo
        style = model.style
    }

    enum CodingKeys: String, CodingKey {
        case text
        case improve
        case rewrite
        case fixGrammar = "fix_grammar"
        case shorten
        case translateTo = "translate_to"
        case style
    }
}

private struct AIWritingResponseDTO: Decodable {
    let resultText: String

    enum CodingKeys: String, CodingKey {
        case resultText = "result_text"
    }
}
