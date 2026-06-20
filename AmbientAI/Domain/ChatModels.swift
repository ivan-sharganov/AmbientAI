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
    var remoteID: String?
    var title: String
    var messages: [ChatMessage]
    var createdAt: Date
    var updatedAt: Date
    var remotePreview: String?

    init(
        id: UUID = UUID(),
        remoteID: String? = nil,
        title: String,
        messages: [ChatMessage] = [],
        createdAt: Date = Date(),
        updatedAt: Date = Date(),
        remotePreview: String? = nil
    ) {
        self.id = id
        self.remoteID = remoteID
        self.title = title
        self.messages = messages
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.remotePreview = remotePreview
    }

    var lastMessagePreview: String {
        messages.last?.text ?? remotePreview ?? title
    }
}
