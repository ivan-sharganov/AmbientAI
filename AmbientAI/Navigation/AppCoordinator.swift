import UIKit

protocol Coordinator: AnyObject {
    func start()
}

final class AppCoordinator: Coordinator {
    private enum Configuration {
        static let apphudAPIKey = "app_FmCjFTwjWpcLSafxT8vCDeVffJyfFS"
        static let dolaAppID = "com.test.test"
        static let dolaBearerToken = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJzdWIiOiIxIiwiZW1haWwiOiJzaGFyb3ZfMTk5OUBsaXN0LnJ1Iiwicm9sZSI6IkFETUlOIiwiZXhwIjo0OTM1MjA4NjcxLCJpYXQiOjE3ODE2MDg2NzEsInR5cGUiOiJhY2Nlc3MifQ.0GRnZq1LZA__0G0tYEsPER8lQiCiX_myE6_T_nMwUmc"
    }

    private let window: UIWindow
    private let navigationController: UINavigationController
    private var chatCoordinator: ChatCoordinator?

    init(window: UIWindow) {
        self.window = window
        self.navigationController = UINavigationController()
        self.navigationController.setNavigationBarHidden(true, animated: false)
    }

    func start() {
        let storage = FileChatStorage()
        let apphudService = ApphudService(apiKey: Configuration.apphudAPIKey)
        apphudService.start()
        let repository = DolaChatRepository(
            storage: storage,
            appID: Configuration.dolaAppID,
            bearerToken: Configuration.dolaBearerToken,
            userIDProvider: { apphudService.userID }
        )
        let aiWritingRepository = DolaAIWritingRepository(
            appID: Configuration.dolaAppID,
            bearerToken: Configuration.dolaBearerToken,
            userIDProvider: { apphudService.userID }
        )
        let pixverseService = PixverseService(
            appID: Configuration.dolaAppID,
            bearerToken: Configuration.dolaBearerToken,
            userIDProvider: { apphudService.userID }
        )
        let chatCoordinator = ChatCoordinator(
            navigationController: navigationController,
            repository: repository,
            aiWritingRepository: aiWritingRepository,
            apphudService: apphudService,
            pixverseService: pixverseService
        )
        self.chatCoordinator = chatCoordinator
        chatCoordinator.start()

        window.rootViewController = navigationController
        window.makeKeyAndVisible()
    }
}
