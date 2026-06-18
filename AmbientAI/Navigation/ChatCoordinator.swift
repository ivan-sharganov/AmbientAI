import UIKit

final class ChatCoordinator: Coordinator {
    private let navigationController: UINavigationController
    private let repository: ChatRepository
    private let apphudService: ApphudServiceProtocol

    init(navigationController: UINavigationController, repository: ChatRepository, apphudService: ApphudServiceProtocol) {
        self.navigationController = navigationController
        self.repository = repository
        self.apphudService = apphudService
    }

    func start() {
        let viewModel = HomeViewModel(repository: repository, apphudService: apphudService)
        viewModel.onStartChat = { [weak self] prompt in
            self?.showChat(initialPrompt: prompt)
        }
        viewModel.onOpenWriting = { [weak self] in
            self?.showWriting()
        }
        viewModel.onOpenHistory = { [weak self] in
            self?.showHistory()
        }
        let controller = HomeViewController(viewModel: viewModel)
        navigationController.setViewControllers([controller], animated: false)
    }

    private func showChat(initialPrompt: String?) {
        let viewModel = ChatViewModel(repository: repository, initialPrompt: initialPrompt)
        viewModel.onOpenHistory = { [weak self] in self?.showHistory() }
        viewModel.onClose = { [weak self] in self?.navigationController.popViewController(animated: true) }
        let controller = ChatViewController(viewModel: viewModel)
        navigationController.pushViewController(controller, animated: true)
    }

    private func showWriting() {
        let controller = AIWritingViewController()
        controller.onClose = { [weak self] in self?.navigationController.popViewController(animated: true) }
        navigationController.pushViewController(controller, animated: true)
    }

    private func showHistory() {
        let viewModel = ChatHistoryViewModel(repository: repository)
        viewModel.onSelectSession = { [weak self] session in
            self?.showExistingChat(session: session)
        }
        viewModel.onClose = { [weak self] in self?.navigationController.popViewController(animated: true) }
        let controller = ChatHistoryViewController(viewModel: viewModel)
        navigationController.pushViewController(controller, animated: true)
    }

    private func showExistingChat(session: ChatSession) {
        let viewModel = ChatViewModel(repository: repository, existingSession: session)
        viewModel.onOpenHistory = { [weak self] in self?.showHistory() }
        viewModel.onClose = { [weak self] in self?.navigationController.popViewController(animated: true) }
        let controller = ChatViewController(viewModel: viewModel)
        navigationController.pushViewController(controller, animated: true)
    }
}
