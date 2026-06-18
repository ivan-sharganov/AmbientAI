import Foundation

final class ChatViewModel {
    var onStateChange: ((ChatViewState) -> Void)?
    var onOpenHistory: (() -> Void)?
    var onClose: (() -> Void)?

    private let repository: ChatRepository
    private var session: ChatSession?
    private let initialPrompt: String?

    init(repository: ChatRepository, initialPrompt: String?) {
        self.repository = repository
        self.initialPrompt = initialPrompt
    }

    init(repository: ChatRepository, existingSession: ChatSession) {
        self.repository = repository
        self.session = existingSession
        self.initialPrompt = nil
    }

    func viewDidLoad() {
        Task { await bootstrap() }
    }

    func send(_ rawText: String) {
        let text = rawText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty else { return }

        Task {
            do {
                let activeSession = try await ensureSession(initialPrompt: text)
                let pendingMessages = activeSession.messages + [ChatMessage(role: .user, text: text)]
                onStateChange?(.loaded(messages: pendingMessages, isLoadingResponse: true))
                let updatedSession = try await repository.sendMessage(text, in: activeSession.id)
                session = updatedSession
                onStateChange?(.loaded(messages: updatedSession.messages, isLoadingResponse: false))
            } catch {
                onStateChange?(.error(error.localizedDescription))
            }
        }
    }

    func openHistory() {
        onOpenHistory?()
    }

    func close() {
        onClose?()
    }

    private func bootstrap() async {
        do {
            if let session {
                let messages = try await repository.loadMessages(for: session.id)
                var updated = session
                updated.messages = messages
                self.session = updated
                onStateChange?(.loaded(messages: messages, isLoadingResponse: false))
                return
            }

            let newSession = try await repository.createSession(initialPrompt: initialPrompt)
            session = newSession
            onStateChange?(.loaded(messages: [], isLoadingResponse: false))

            if let initialPrompt, !initialPrompt.isEmpty {
                send(initialPrompt)
            }
        } catch {
            onStateChange?(.error(error.localizedDescription))
        }
    }

    private func ensureSession(initialPrompt: String) async throws -> ChatSession {
        if let session { return session }
        let newSession = try await repository.createSession(initialPrompt: initialPrompt)
        session = newSession
        return newSession
    }
}

enum ChatViewState: Equatable {
    case loaded(messages: [ChatMessage], isLoadingResponse: Bool)
    case error(String)
}
