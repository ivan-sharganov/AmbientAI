import Foundation

final class MockChatRepository: ChatRepository {
    private let storage: ChatStorage

    init(storage: ChatStorage) {
        self.storage = storage
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
        let session = ChatSession(title: title)
        sessions.append(session)
        try await storage.saveSessions(sessions)
        return session
    }

    func sendMessage(_ text: String, in sessionID: UUID) async throws -> ChatSession {
        let prompt = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !prompt.isEmpty else { throw ChatRepositoryError.emptyPrompt }

        var sessions = try await storage.loadSessions()
        let index: Int
        if let existingIndex = sessions.firstIndex(where: { $0.id == sessionID }) {
            index = existingIndex
        } else {
            sessions.append(ChatSession(id: sessionID, title: prompt))
            index = sessions.count - 1
        }

        sessions[index].messages.append(ChatMessage(role: .user, text: prompt))
        sessions[index].title = sessions[index].messages.first?.text ?? prompt
        sessions[index].updatedAt = Date()
        try await storage.saveSessions(sessions)

        try await Task.sleep(nanoseconds: 2_000_000_000)

        sessions = try await storage.loadSessions()
        guard let refreshedIndex = sessions.firstIndex(where: { $0.id == sessionID }) else {
            throw ChatRepositoryError.sessionNotFound
        }

        sessions[refreshedIndex].messages.append(ChatMessage(role: .assistant, text: Self.response(for: prompt)))
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

    private static func response(for prompt: String) -> String {
        """
        Welcome to the team, Alexander!

        Hi Alexander, welcome to the development team! We're all really looking forward to having you start next week, and we're confident you'll settle in quickly.

        Here are a few tips to help you get through your first week:
        • Focus on getting up to speed — don't hesitate to ask questions if anything is unclear. We're used to helping new team members find their feet.
        • Meet the team — we're having a short welcome meeting on Monday at 11:00 AM. It'll be a great chance to connect with everyone.
        • Documentation — all the key materials are available in our internal knowledge base. I'll send you the link separately.

        Looking forward to working with you!
        """
    }
}

enum ChatRepositoryError: LocalizedError {
    case emptyPrompt
    case sessionNotFound

    var errorDescription: String? {
        switch self {
        case .emptyPrompt:
            return "Enter a prompt first."
        case .sessionNotFound:
            return "Chat session was not found."
        }
    }
}

private extension String {
    var nilIfEmpty: String? { isEmpty ? nil : self }
}
