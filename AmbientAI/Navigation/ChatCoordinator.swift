import UIKit

final class ChatCoordinator: Coordinator {
    private let navigationController: UINavigationController
    private let repository: ChatRepository
    private let aiWritingRepository: AIWritingRepository
    private let apphudService: ApphudServiceProtocol
    private let pixverseService: PixverseServiceProtocol
    private let videoHistoryStore: VideoHistoryStore
    private var videoGenerationTask: Task<Void, Never>?

    init(
        navigationController: UINavigationController,
        repository: ChatRepository,
        aiWritingRepository: AIWritingRepository,
        apphudService: ApphudServiceProtocol,
        pixverseService: PixverseServiceProtocol,
        videoHistoryStore: VideoHistoryStore
    ) {
        self.navigationController = navigationController
        self.repository = repository
        self.aiWritingRepository = aiWritingRepository
        self.apphudService = apphudService
        self.pixverseService = pixverseService
        self.videoHistoryStore = videoHistoryStore
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
        let controller = VideoHistoryViewController(store: videoHistoryStore)
        controller.onClose = { [weak self] in self?.navigationController.popViewController(animated: true) }
        controller.onSelectVideo = { [weak self] videoURL in
            self?.showHistoricalVideo(videoURL: videoURL)
        }
        navigationController.pushViewController(controller, animated: true)
    }

    private func showHistoricalVideo(videoURL: URL) {
        let controller = VideoResultViewController(videoURL: videoURL, showsReplaceButton: false)
        controller.onClose = { [weak self] in
            self?.navigationController.popViewController(animated: true)
        }
        navigationController.pushViewController(controller, animated: true)
    }

    private func showVideoTemplateDetail(template: VideoTemplate, variants: [VideoTemplate]) {
        let controller = VideoTemplateDetailViewController(template: template, variants: variants)
        controller.onClose = { [weak self] in self?.navigationController.popViewController(animated: true) }
        controller.onCreate = { [weak self] request in self?.showVideoGenerationLoading(request: request) }
        navigationController.pushViewController(controller, animated: true)
    }

    private func showVideoGenerationLoading(
        request: VideoGenerationRequest
    ) {
        let controller = VideoGenerationLoadingViewController()
        controller.onClose = { [weak self] in
            self?.videoGenerationTask?.cancel()
            self?.navigationController.popViewController(animated: true)
        }
        navigationController.pushViewController(controller, animated: true)
        startVideoGeneration(request: request, on: controller)
    }

    private func startVideoGeneration(
        request: VideoGenerationRequest,
        on controller: VideoGenerationLoadingViewController
    ) {
        videoGenerationTask?.cancel()
        videoGenerationTask = Task { [weak self, weak controller] in
            guard let self else { return }
            do {
                let videoID = try await pixverseService.generateVideo(request: request)
                let remoteVideoURL = try await pixverseService.waitForVideo(videoID: videoID)
                let sourceURL = resolvedVideoURL(remoteVideoURL)
                let resultURL: URL
                do {
                    let savedVideo = try await videoHistoryStore.save(
                        videoAt: sourceURL,
                        title: request.template.title,
                        fallbackThumbnailData: request.imageData
                    )
                    resultURL = savedVideo.videoURL
                } catch {
                    print("[VideoHistory] Local save failed: \(error.localizedDescription)")
                    resultURL = sourceURL
                }
                try Task.checkCancellation()
                await MainActor.run {
                    guard let controller else { return }
                    self.showVideoResult(videoURL: resultURL, request: request, after: controller)
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

    private func resolvedVideoURL(_ videoURL: URL) -> URL {
        if videoURL.host == "example.com",
           let fallbackURL = Bundle.main.url(forResource: "fallback_video", withExtension: "mov") {
            return fallbackURL
        }
        return videoURL
    }

    private func showVideoResult(
        videoURL: URL,
        request: VideoGenerationRequest,
        after loadingController: VideoGenerationLoadingViewController
    ) {
        guard navigationController.topViewController === loadingController else { return }
        let controller = VideoResultViewController(videoURL: videoURL)
        controller.onClose = { [weak self, weak loadingController] in
            guard let self, let loadingController,
                  let loadingIndex = self.navigationController.viewControllers.firstIndex(where: { $0 === loadingController }),
                  loadingIndex > 0 else { return }
            let destination = self.navigationController.viewControllers[loadingIndex - 1]
            self.navigationController.popToViewController(destination, animated: true)
        }
        controller.onReplace = { [weak self, weak loadingController] in
            guard let self, let loadingController else { return }
            self.navigationController.popToViewController(loadingController, animated: true)
            self.startVideoGeneration(request: request, on: loadingController)
        }
        navigationController.pushViewController(controller, animated: true)
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
