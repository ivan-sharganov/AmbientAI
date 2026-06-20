import UIKit

final class ChatCoordinator: Coordinator {
    private let navigationController: UINavigationController
    private let repository: ChatRepository
    private let aiWritingRepository: AIWritingRepository
    private let apphudService: ApphudServiceProtocol
    private let pixverseService: PixverseServiceProtocol
    private var videoGenerationTask: Task<Void, Never>?

    init(
        navigationController: UINavigationController,
        repository: ChatRepository,
        aiWritingRepository: AIWritingRepository,
        apphudService: ApphudServiceProtocol,
        pixverseService: PixverseServiceProtocol
    ) {
        self.navigationController = navigationController
        self.repository = repository
        self.aiWritingRepository = aiWritingRepository
        self.apphudService = apphudService
        self.pixverseService = pixverseService
    }

    func start() {
        let viewModel = HomeViewModel(repository: repository, apphudService: apphudService)
        viewModel.onStartChat = { [weak self] prompt in
            self?.requirePremium { [weak self] in self?.showChat(initialPrompt: prompt) }
        }
        viewModel.onOpenWriting = { [weak self] in
            self?.requirePremium { [weak self] in self?.showWriting() }
        }
        viewModel.onOpenVideoTemplates = { [weak self] in
            self?.requirePremium { [weak self] in self?.showVideoTemplates() }
        }
        viewModel.onOpenHistory = { [weak self] in
            self?.showHistory()
        }
        let controller = HomeViewController(viewModel: viewModel)
        navigationController.setViewControllers([controller], animated: false)
    }

    private func requirePremium(perform action: @escaping () -> Void) {
        Task { [weak self] in
            guard let self else { return }
            await apphudService.refreshStatus()
            if apphudService.isPremium {
                action()
            } else {
                showPaywall(afterUnlock: action)
            }
        }
    }

    private func showPaywall(afterUnlock action: (() -> Void)? = nil) {
        if navigationController.topViewController is PaywallViewController { return }
        let controller = PaywallViewController(apphudService: apphudService)
        controller.onClose = { [weak self] in
            self?.navigationController.popViewController(animated: true)
        }
        controller.onUnlock = { [weak self, weak controller] in
            guard let self, let controller else { return }
            var stack = navigationController.viewControllers
            stack.removeAll(where: { $0 === controller })
            navigationController.setViewControllers(stack, animated: false)
            action?()
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
        let controller = VideoTemplateListViewController(service: pixverseService)
        controller.onClose = { [weak self] in self?.navigationController.popViewController(animated: true) }
        controller.onSelectTemplate = { [weak self] template, variants in
            self?.showVideoTemplateDetail(template: template, variants: variants)
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

    private func showVideoTemplateDetail(template: VideoTemplate, variants: [VideoTemplate]) {
        let controller = VideoTemplateDetailViewController(template: template, variants: variants)
        controller.onClose = { [weak self] in self?.navigationController.popViewController(animated: true) }
        controller.onCreate = { [weak self] request in self?.showVideoGenerationLoading(request: request) }
        navigationController.pushViewController(controller, animated: true)
    }

    private func showVideoGenerationLoading(
        request: VideoGenerationRequest,
        replacing replacedController: UIViewController? = nil
    ) {
        videoGenerationTask?.cancel()
        let controller = VideoGenerationLoadingViewController()
        controller.onClose = { [weak self] in
            self?.videoGenerationTask?.cancel()
            self?.navigationController.popViewController(animated: true)
        }

        if let replacedController {
            replace(replacedController, with: controller)
        } else {
            navigationController.pushViewController(controller, animated: true)
        }

        videoGenerationTask = Task { [weak self, weak controller] in
            guard let self else { return }
            do {
                let videoID = try await pixverseService.generateVideo(request: request)
                let videoURL = try await pixverseService.waitForVideo(videoID: videoID)
                try Task.checkCancellation()
                await MainActor.run {
                    guard let controller else { return }
                    self.showVideoResult(videoURL: videoURL, request: request, replacing: controller)
                }
            } catch is CancellationError {
                return
            } catch {
                await MainActor.run {
                    guard let controller else { return }
                    self.showVideoGenerationError(error, from: controller)
                }
            }
        }
    }

    private func showVideoResult(
        videoURL: URL,
        request: VideoGenerationRequest,
        replacing loadingController: VideoGenerationLoadingViewController
    ) {
        let controller = VideoResultViewController(videoURL: videoURL)
        controller.onClose = { [weak self] in self?.navigationController.popViewController(animated: true) }
        controller.onReplace = { [weak self, weak controller] in
            guard let controller else { return }
            self?.showVideoGenerationLoading(request: request, replacing: controller)
        }
        replace(loadingController, with: controller)
    }

    private func replace(_ oldController: UIViewController, with newController: UIViewController) {
        var stack = navigationController.viewControllers
        if let index = stack.firstIndex(where: { $0 === oldController }) {
            stack[index] = newController
            navigationController.setViewControllers(stack, animated: true)
        } else {
            navigationController.pushViewController(newController, animated: true)
        }
    }

    private func showVideoGenerationError(_ error: Error, from loadingController: UIViewController) {
        guard navigationController.viewControllers.contains(where: { $0 === loadingController }) else { return }
        navigationController.popViewController(animated: true)
        let alert = UIAlertController(
            title: "Generation failed",
            message: error.localizedDescription,
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        navigationController.topViewController?.present(alert, animated: true)
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
