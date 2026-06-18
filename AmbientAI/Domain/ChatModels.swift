import Foundation

enum ChatRole: String, Codable {
    case user
    case assistant
}

struct ChatMessage: Codable, Identifiable, Equatable {
    let id: UUID
    let role: ChatRole
    let text: String
    let createdAt: Date

    init(id: UUID = UUID(), role: ChatRole, text: String, createdAt: Date = Date()) {
        self.id = id
        self.role = role
        self.text = text
        self.createdAt = createdAt
    }
}

struct ChatSession: Codable, Identifiable, Equatable {
    let id: UUID
    var title: String
    var messages: [ChatMessage]
    var createdAt: Date
    var updatedAt: Date

    init(id: UUID = UUID(), title: String, messages: [ChatMessage] = [], createdAt: Date = Date(), updatedAt: Date = Date()) {
        self.id = id
        self.title = title
        self.messages = messages
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }

    var lastMessagePreview: String {
        messages.last?.text ?? title
    }
}
