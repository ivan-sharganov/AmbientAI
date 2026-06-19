import Foundation

final class DolaChatRepository: ChatRepository {
    private let storage: ChatStorage
    private let session: URLSession
    private let baseURL: URL
    private let appID: String
    private let bearerToken: String
    private let userIDProvider: () -> String

    init(
        storage: ChatStorage,
        baseURL: URL = URL(string: "https://nebulaapps.site")!,
        appID: String,
        bearerToken: String,
        userIDProvider: @escaping () -> String,
        session: URLSession = .shared
    ) {
        self.storage = storage
        self.baseURL = baseURL
        self.appID = appID
        self.bearerToken = bearerToken
        self.userIDProvider = userIDProvider
        self.session = session
    }

    func loadSessions() async throws -> [ChatSession] {
        try await storage.loadSessions().sorted { $0.updatedAt > $1.updatedAt }
    }

    func loadMessages(for sessionID: UUID) async throws -> [ChatMessage] {
        let sessions = try await storage.loadSessions()
        return sessions.first(where: { $0.id == sessionID })?.messages ?? []
    }

    func createSession(initialPrompt: String?) async throws -> ChatSession {
        var sessions = try await storage.loadSessions()
        let title = initialPrompt?.trimmingCharacters(in: .whitespacesAndNewlines).nilIfEmpty ?? "New chat"
        let chat = ChatSession(title: title)
        sessions.append(chat)
        try await storage.saveSessions(sessions)
        return chat
    }

    func sendMessage(_ text: String, in sessionID: UUID) async throws -> ChatSession {
        guard !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            throw ChatRepositoryError.emptyPrompt
        }

        var sessions = try await storage.loadSessions()
        let index: Int
        if let existingIndex = sessions.firstIndex(where: { $0.id == sessionID }) {
            index = existingIndex
        } else {
            sessions.append(ChatSession(id: sessionID, title: text))
            index = sessions.count - 1
        }

        sessions[index].messages.append(ChatMessage(role: .user, text: text))
        sessions[index].title = sessions[index].messages.first?.text ?? text
        sessions[index].updatedAt = Date()
        try await storage.saveSessions(sessions)

        let response = try await sendToDola(text: text, chatID: sessionID)

        sessions = try await storage.loadSessions()
        guard let refreshedIndex = sessions.firstIndex(where: { $0.id == sessionID }) else {
            throw ChatRepositoryError.sessionNotFound
        }

        sessions[refreshedIndex].messages.append(
            ChatMessage(role: .assistant, text: response.assistantMessage)
        )
        sessions[refreshedIndex].updatedAt = Date()
        try await storage.saveSessions(sessions)
        return sessions[refreshedIndex]
    }

    func deleteSession(id: UUID) async throws {
        try await storage.deleteSession(id: id)
    }

    func deleteAllSessions() async throws {
        try await storage.deleteAllSessions()
    }

    private func sendToDola(text: String, chatID: UUID) async throws -> SendDolaMessageResponse {
        let userID = userIDProvider()
        guard !userID.isEmpty else { throw DolaAPIError.missingUserID }

        let endpoint = baseURL
            .appendingPathComponent("dola")
            .appendingPathComponent("chats")
            .appendingPathComponent(chatID.uuidString)
            .appendingPathComponent("messages")

        guard var components = URLComponents(url: endpoint, resolvingAgainstBaseURL: false) else {
            throw DolaAPIError.invalidURL
        }
        components.queryItems = [
            URLQueryItem(name: "user_id", value: userID),
            URLQueryItem(name: "app_id", value: appID),
            URLQueryItem(name: "locale", value: "en")
        ]
        guard let url = components.url else { throw DolaAPIError.invalidURL }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.setValue("Bearer \(bearerToken)", forHTTPHeaderField: "Authorization")
        request.httpBody = try JSONEncoder().encode(SendDolaMessageRequest(message: text))

        let (data, response) = try await session.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse else {
            throw DolaAPIError.invalidResponse
        }
        guard 200..<300 ~= httpResponse.statusCode else {
            let serverMessage = (try? JSONDecoder().decode(DolaErrorResponse.self, from: data))?.detail
            throw DolaAPIError.httpError(statusCode: httpResponse.statusCode, message: serverMessage)
        }

        return try JSONDecoder().decode(SendDolaMessageResponse.self, from: data)
    }
}

private struct SendDolaMessageRequest: Encodable {
    let message: String
}

private struct SendDolaMessageResponse: Decodable {
    let chatID: String
    let assistantMessage: String

    enum CodingKeys: String, CodingKey {
        case chatID = "chat_id"
        case assistantMessage = "assistant_message"
    }
}

private struct DolaErrorResponse: Decodable {
    let detail: String?
}

enum DolaAPIError: LocalizedError {
    case invalidURL
    case missingUserID
    case invalidResponse
    case httpError(statusCode: Int, message: String?)

    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "The Dola API URL is invalid."
        case .missingUserID:
            return "Apphud user ID is unavailable."
        case .invalidResponse:
            return "The Dola API returned an invalid response."
        case let .httpError(statusCode, message):
            return message ?? "Dola API request failed with status \(statusCode)."
        }
    }
}

private extension String {
    var nilIfEmpty: String? { isEmpty ? nil : self }
}
