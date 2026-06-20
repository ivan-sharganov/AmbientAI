import Foundation

final class DolaChatRepository: ChatRepository {
    private let session: URLSession
    private let baseURL: URL
    private let appID: String
    private let bearerToken: String
    private let userIDProvider: () -> String
    private var sessionsByID: [UUID: ChatSession] = [:]
    private var deletedRemoteIDs: Set<String> = []

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

    func loadSessions() async throws -> [ChatSession] {
        let remoteChats = try await fetchChats()
        let previousSessions = Array(sessionsByID.values)

        var synchronized: [ChatSession] = []
        for remote in remoteChats where !deletedRemoteIDs.contains(remote.chatID) {
            let local = previousSessions.first(where: { session in
                session.remoteID == remote.chatID
                    || session.id.uuidString.caseInsensitiveCompare(remote.chatID) == .orderedSame
            })
            let loadedMessages: [ChatMessage]
            if remote.title?.nilIfEmpty == nil {
                loadedMessages = (try? await fetchMessages(chatID: remote.chatID).map(\.model)) ?? local?.messages ?? []
            } else {
                loadedMessages = local?.messages ?? []
            }
            let firstUserMessage = loadedMessages.first(where: { $0.role == .user })?.text.nilIfEmpty
            synchronized.append(ChatSession(
                id: local?.id ?? UUID(uuidString: remote.chatID) ?? UUID(),
                remoteID: remote.chatID,
                title: remote.title?.nilIfEmpty ?? firstUserMessage ?? local?.title ?? "New chat",
                messages: loadedMessages,
                createdAt: local?.createdAt ?? remote.updatedAt,
                updatedAt: remote.updatedAt,
                remotePreview: remote.lastMessagePreview
            ))
        }

        let pendingSessions = previousSessions.filter { local in
            !synchronized.contains(where: { $0.id == local.id })
                && local.remoteID == nil
                && !local.messages.isEmpty
                && !deletedRemoteIDs.contains(local.id.uuidString)
        }
        let result = (synchronized + pendingSessions).sorted { $0.updatedAt > $1.updatedAt }
        sessionsByID = Dictionary(uniqueKeysWithValues: result.map { ($0.id, $0) })
        print("[Dola] Server returned \(remoteChats.count), UI receives \(result.count) chats")
        return result
    }

    func loadMessages(for sessionID: UUID) async throws -> [ChatMessage] {
        guard var chat = sessionsByID[sessionID] else {
            throw ChatRepositoryError.sessionNotFound
        }
        let remoteID = chat.remoteID ?? chat.id.uuidString
        let messages = try await fetchMessages(chatID: remoteID).map(\.model)
        chat.messages = messages
        chat.remoteID = remoteID
        chat.remotePreview = messages.last?.text
        sessionsByID[sessionID] = chat
        return messages
    }

    func createSession(initialPrompt: String?) async throws -> ChatSession {
        let title = initialPrompt?.trimmingCharacters(in: .whitespacesAndNewlines).nilIfEmpty ?? "New chat"
        let chat = ChatSession(title: title)
        sessionsByID[chat.id] = chat
        return chat
    }

    func sendMessage(_ text: String, in sessionID: UUID) async throws -> ChatSession {
        guard !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            throw ChatRepositoryError.emptyPrompt
        }

        var chat = sessionsByID[sessionID] ?? ChatSession(id: sessionID, title: text)
        chat.messages.append(ChatMessage(role: .user, text: text))
        chat.title = chat.messages.first?.text ?? text
        chat.updatedAt = Date()
        sessionsByID[sessionID] = chat

        let remoteID = chat.remoteID ?? sessionID.uuidString
        let response = try await sendToDola(text: text, chatID: remoteID)

        chat.messages.append(ChatMessage(role: .assistant, text: response.assistantMessage))
        chat.remoteID = response.chatID
        chat.remotePreview = response.assistantMessage
        chat.updatedAt = Date()
        sessionsByID[sessionID] = chat
        return chat
    }

    func deleteSession(id: UUID) async throws {
        if let session = sessionsByID[id] {
            deletedRemoteIDs.insert(session.remoteID ?? session.id.uuidString)
        }
        sessionsByID.removeValue(forKey: id)
    }

    func deleteAllSessions() async throws {
        deletedRemoteIDs.formUnion(sessionsByID.values.map { $0.remoteID ?? $0.id.uuidString })
        sessionsByID.removeAll()
    }

    private func fetchChats() async throws -> [DolaChatDTO] {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .custom(DateDecoding.decode)
        var result: [DolaChatDTO] = []
        var offset = 0

        while true {
            let request = try makeAuthorizedRequest(
                path: ["dola", "chats"],
                queryItems: paginationQuery(offset: offset)
            )
            let page = try decoder.decode([DolaChatDTO].self, from: await perform(request))
            result.append(contentsOf: page)
            guard page.count == 100 else { break }
            offset += page.count
        }
        print("[Dola] Synchronized \(result.count) chats")
        result.forEach { chat in
            print("[Dola] Server chat: \(chat.title?.nilIfEmpty ?? "Untitled") [\(chat.chatID)]")
        }
        return result
    }

    private func fetchMessages(chatID: String) async throws -> [DolaMessageDTO] {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .custom(DateDecoding.decode)
        var result: [DolaMessageDTO] = []
        var offset = 0

        while true {
            let request = try makeAuthorizedRequest(
                path: ["dola", "chats", chatID, "messages"],
                queryItems: paginationQuery(offset: offset)
            )
            let page = try decoder.decode([DolaMessageDTO].self, from: await perform(request))
            result.append(contentsOf: page)
            guard page.count == 100 else { break }
            offset += page.count
        }
        print("[Dola] Synchronized \(result.count) messages for chat \(chatID)")
        return result
    }

    private func sendToDola(text: String, chatID: String) async throws -> SendDolaMessageResponse {
        let userID = userIDProvider()
        guard !userID.isEmpty else { throw DolaAPIError.missingUserID }

        let endpoint = baseURL
            .appendingPathComponent("dola")
            .appendingPathComponent("chats")
            .appendingPathComponent(chatID)
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

    private func makeAuthorizedRequest(path: [String], queryItems: [URLQueryItem] = []) throws -> URLRequest {
        let userID = userIDProvider()
        guard !userID.isEmpty else { throw DolaAPIError.missingUserID }
        let endpoint = path.reduce(baseURL) { $0.appendingPathComponent($1) }
        guard var components = URLComponents(url: endpoint, resolvingAgainstBaseURL: false) else {
            throw DolaAPIError.invalidURL
        }
        components.queryItems = queryItems + [
            URLQueryItem(name: "user_id", value: userID),
            URLQueryItem(name: "app_id", value: appID)
        ]
        guard let url = components.url else { throw DolaAPIError.invalidURL }
        var request = URLRequest(url: url)
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.setValue("Bearer \(bearerToken)", forHTTPHeaderField: "Authorization")
        return request
    }

    private func paginationQuery(offset: Int) -> [URLQueryItem] {
        [
            URLQueryItem(name: "limit", value: "100"),
            URLQueryItem(name: "offset", value: String(offset))
        ]
    }

    private func perform(_ request: URLRequest) async throws -> Data {
        let (data, response) = try await session.data(for: request)
        guard let http = response as? HTTPURLResponse else { throw DolaAPIError.invalidResponse }
        guard (200..<300).contains(http.statusCode) else {
            let message = (try? JSONDecoder().decode(DolaErrorResponse.self, from: data))?.detail
            throw DolaAPIError.httpError(statusCode: http.statusCode, message: message)
        }
        return data
    }

}

private struct DolaChatDTO: Decodable {
    let chatID: String
    let title: String?
    let updatedAt: Date
    let lastMessagePreview: String?

    enum CodingKeys: String, CodingKey {
        case chatID = "chat_id"
        case title
        case updatedAt = "updated_at"
        case lastMessagePreview = "last_message_preview"
    }
}

private struct DolaMessageDTO: Decodable {
    let role: String
    let content: String
    let createdAt: Date

    enum CodingKeys: String, CodingKey {
        case role, content
        case createdAt = "created_at"
    }

    var model: ChatMessage {
        ChatMessage(role: role == "user" ? .user : .assistant, text: content, createdAt: createdAt)
    }
}

private enum DateDecoding {
    static func decode(_ decoder: Decoder) throws -> Date {
        let container = try decoder.singleValueContainer()
        let value = try container.decode(String.self)
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        if let date = formatter.date(from: value) { return date }
        formatter.formatOptions = [.withInternetDateTime]
        if let date = formatter.date(from: value) { return date }
        throw DecodingError.dataCorruptedError(in: container, debugDescription: "Invalid ISO-8601 date: \(value)")
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
