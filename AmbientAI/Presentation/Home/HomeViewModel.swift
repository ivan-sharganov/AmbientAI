import Foundation

final class HomeViewModel {
    var onStartChat: ((String?) -> Void)?
    var onOpenWriting: (() -> Void)?
    var onOpenVideoTemplates: (() -> Void)?
    var onOpenHistory: (() -> Void)?
    var onStateChange: ((HomeState) -> Void)?
    var onApphudLogout: ((String, Bool) -> Void)?

    private let repository: ChatRepository
    private let apphudService: ApphudServiceProtocol

    init(repository: ChatRepository, apphudService: ApphudServiceProtocol) {
        self.repository = repository
        self.apphudService = apphudService
    }

    func viewDidLoad() {
        onStateChange?(.ready(isPremium: apphudService.isPremium))
    }

    func startChat(prompt: String?) {
        onStartChat?(prompt?.trimmingCharacters(in: .whitespacesAndNewlines).nilIfEmpty)
    }

    func openWriting() {
        onOpenWriting?()
    }

    func openVideoTemplates() {
        onOpenVideoTemplates?()
    }

    func openHistory() {
        onOpenHistory?()
    }

    func logoutApphudUser() {
        Task { [weak self] in
            guard let self else { return }
            await apphudService.logoutUserForTesting()
            onApphudLogout?(apphudService.userID, apphudService.isPremium)
        }
    }

}

enum HomeState: Equatable {
    case ready(isPremium: Bool)
}

private extension String {
    var nilIfEmpty: String? { isEmpty ? nil : self }
}
