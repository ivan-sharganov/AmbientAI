import Foundation

final class ChatHistoryViewModel {
    var onStateChange: ((ChatHistoryState) -> Void)?
    var onDeleteResult: ((HistoryDeleteResult) -> Void)?
    var onDeletedSession: ((UUID) -> Void)?
    var onSelectSession: ((ChatSession) -> Void)?
    var onClose: (() -> Void)?

    private let repository: ChatRepository
    private(set) var sections: [ChatHistorySection] = []

    init(repository: ChatRepository) {
        self.repository = repository
    }

    func viewDidLoad() {
        Task { await reload() }
    }

    func reload() async {
        onStateChange?(.loading)
        do {
            let sessions = try await repository.loadSessions()
            print("[Dola] Displaying \(sessions.count) chats in history UI")
            sections = Self.group(sessions: sessions)
            onStateChange?(sessions.isEmpty ? .empty : .loaded(sections))
        } catch {
            sections = []
            onStateChange?(.empty)
        }
    }

    func select(indexPath: IndexPath) {
        guard let session = session(at: indexPath) else { return }
        onSelectSession?(session)
    }

    func delete(indexPath: IndexPath) {
        guard let session = session(at: indexPath), indexPath.count >= 2 else { return }
        let oldSectionHadSingleRow = sections[indexPath[0]].sessions.count == 1

        Task {
            do {
                try await repository.deleteSession(id: session.id)
                let sessions = try await repository.loadSessions()
                sections = Self.group(sessions: sessions)

                let result = HistoryDeleteResult(
                    indexPath: indexPath,
                    removedSectionIndex: oldSectionHadSingleRow ? indexPath[0] : nil,
                    isEmpty: sessions.isEmpty
                )
                onDeleteResult?(result)
                onDeletedSession?(session.id)
            } catch {
                await reload()
            }
        }
    }

    private func session(at indexPath: IndexPath) -> ChatSession? {
        guard indexPath.count >= 2 else { return nil }
        let section = indexPath[0]
        let row = indexPath[1]
        guard sections.indices.contains(section), sections[section].sessions.indices.contains(row) else { return nil }
        return sections[section].sessions[row]
    }

    func close() {
        onClose?()
    }

    private static func group(sessions: [ChatSession]) -> [ChatHistorySection] {
        let grouped = Dictionary(grouping: sessions) { DateFormatting.historySectionTitle(for: $0.updatedAt) }
        let order = ["Today", "Yesterday"]
        return grouped.map { title, sessions in
            ChatHistorySection(title: title, sessions: sessions.sorted { $0.updatedAt > $1.updatedAt })
        }
        .sorted { lhs, rhs in
            let leftIndex = order.firstIndex(of: lhs.title) ?? Int.max
            let rightIndex = order.firstIndex(of: rhs.title) ?? Int.max
            if leftIndex != rightIndex { return leftIndex < rightIndex }
            return (lhs.sessions.first?.updatedAt ?? .distantPast) > (rhs.sessions.first?.updatedAt ?? .distantPast)
        }
    }
}

struct ChatHistorySection: Equatable {
    let title: String
    let sessions: [ChatSession]
}

struct HistoryDeleteResult: Equatable {
    let indexPath: IndexPath
    let removedSectionIndex: Int?
    let isEmpty: Bool
}

enum ChatHistoryState: Equatable {
    case loading
    case loaded([ChatHistorySection])
    case empty
}
