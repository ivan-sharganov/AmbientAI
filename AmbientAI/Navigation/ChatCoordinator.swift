import UIKit

final class ChatCoordinator: Coordinator {
    private let navigationController: UINavigationController
    private let repository: ChatRepository
    private let aiWritingRepository: AIWritingRepository
    private let apphudService: ApphudServiceProtocol

    init(
        navigationController: UINavigationController,
        repository: ChatRepository,
        aiWritingRepository: AIWritingRepository,
        apphudService: ApphudServiceProtocol
    ) {
        self.navigationController = navigationController
        self.repository = repository
        self.aiWritingRepository = aiWritingRepository
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
        viewModel.onOpenVideoTemplates = { [weak self] in
            self?.showVideoTemplates()
        }
        viewModel.onOpenHistory = { [weak self] in
            self?.showHistory()
        }
        viewModel.onOpenPaywall = { [weak self] in
            self?.showPaywall()
        }
        let controller = HomeViewController(viewModel: viewModel)
        navigationController.setViewControllers([controller], animated: false)
    }

    private func showPaywall() {
        let controller = PaywallViewController()
        controller.onClose = { [weak self] in
            self?.navigationController.popViewController(animated: true)
        }
        navigationController.pushViewController(controller, animated: true)
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
        controller.onGenerate = { [weak self] request in
            self?.showWritingResult(request: request)
        }
        navigationController.pushViewController(controller, animated: true)
    }

    private func showWritingResult(request: AIWritingRequestModel) {
        let viewModel = AIWritingResultViewModel(request: request, repository: aiWritingRepository)
        let controller = AIWritingResultViewController(viewModel: viewModel)
        controller.onClose = { [weak self] in
            self?.navigationController.popViewController(animated: true)
        }
        navigationController.pushViewController(controller, animated: true)
    }

    private func showVideoTemplates() {
        let controller = VideoTemplateListViewController()
        controller.onClose = { [weak self] in self?.navigationController.popViewController(animated: true) }
        controller.onSelectTemplate = { [weak self] template in
            self?.showVideoTemplateDetail(template: template)
        }
        controller.onOpenHistory = { [weak self] in
            self?.showVideoHistory()
        }
        navigationController.pushViewController(controller, animated: true)
    }

    private func showVideoHistory() {
        let controller = VideoHistoryViewController()
        controller.onClose = { [weak self] in self?.navigationController.popViewController(animated: true) }
        navigationController.pushViewController(controller, animated: true)
    }

    private func showVideoTemplateDetail(template: VideoTemplate) {
        let controller = VideoTemplateDetailViewController(template: template)
        controller.onClose = { [weak self] in self?.navigationController.popViewController(animated: true) }
        controller.onCreate = { [weak self] in self?.showVideoGenerationLoading() }
        navigationController.pushViewController(controller, animated: true)
    }

    private func showVideoGenerationLoading() {
        let controller = VideoGenerationLoadingViewController()
        controller.onClose = { [weak self] in self?.navigationController.popViewController(animated: true) }
        controller.onFinished = { [weak self, weak controller] in
            guard let controller else { return }
            self?.showVideoResult(replacing: controller)
        }
        navigationController.pushViewController(controller, animated: true)
    }

    private func showVideoResult(replacing loadingController: VideoGenerationLoadingViewController) {
        let controller = VideoResultViewController()
        controller.onClose = { [weak self] in self?.navigationController.popViewController(animated: true) }
        controller.onReplace = { [weak self, weak controller] in
            guard let controller else { return }
            self?.regenerateVideo(replacing: controller)
        }

        var stack = navigationController.viewControllers
        if let index = stack.firstIndex(where: { $0 === loadingController }) {
            stack[index] = controller
            navigationController.setViewControllers(stack, animated: true)
        } else {
            navigationController.pushViewController(controller, animated: true)
        }
    }

    private func regenerateVideo(replacing resultController: VideoResultViewController) {
        let controller = VideoGenerationLoadingViewController()
        controller.onClose = { [weak self] in self?.navigationController.popViewController(animated: true) }
        controller.onFinished = { [weak self, weak controller] in
            guard let controller else { return }
            self?.showVideoResult(replacing: controller)
        }

        var stack = navigationController.viewControllers
        if let index = stack.firstIndex(where: { $0 === resultController }) {
            stack[index] = controller
            navigationController.setViewControllers(stack, animated: true)
        } else {
            navigationController.pushViewController(controller, animated: true)
        }
    }

    private func showHistory() {
        let viewModel = ChatHistoryViewModel(repository: repository)
        viewModel.onSelectSession = { [weak self] session in
            self?.showExistingChat(session: session)
        }
        viewModel.onDeletedSession = { [weak self] sessionID in
            self?.removeDeletedChatFromStack(sessionID: sessionID)
        }
        viewModel.onClose = { [weak self] in self?.navigationController.popViewController(animated: true) }
        let controller = ChatHistoryViewController(viewModel: viewModel)
        navigationController.pushViewController(controller, animated: true)
    }

    private func removeDeletedChatFromStack(sessionID: UUID) {
        let updatedStack = navigationController.viewControllers.filter { controller in
            guard let chatController = controller as? ChatViewController else { return true }
            return chatController.viewModel.sessionID != sessionID
        }
        if updatedStack.count != navigationController.viewControllers.count {
            navigationController.setViewControllers(updatedStack, animated: false)
        }
    }

    private func showExistingChat(session: ChatSession) {
        let viewModel = ChatViewModel(repository: repository, existingSession: session)
        viewModel.onOpenHistory = { [weak self] in self?.showHistory() }
        viewModel.onClose = { [weak self] in self?.navigationController.popViewController(animated: true) }
        let controller = ChatViewController(viewModel: viewModel)
        navigationController.pushViewController(controller, animated: true)
    }
}
