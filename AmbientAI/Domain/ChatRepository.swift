import Foundation

protocol ChatRepository {
    func loadSessions() async throws -> [ChatSession]
    func loadMessages(for sessionID: UUID) async throws -> [ChatMessage]
    func createSession(initialPrompt: String?) async throws -> ChatSession
    func sendMessage(_ text: String, in sessionID: UUID) async throws -> ChatSession
    func deleteAllSessions() async throws
}

protocol ChatStorage {
    func loadSessions() async throws -> [ChatSession]
    func saveSessions(_ sessions: [ChatSession]) async throws
    func deleteAllSessions() async throws
}
