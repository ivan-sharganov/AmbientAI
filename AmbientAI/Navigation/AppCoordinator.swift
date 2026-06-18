import UIKit

protocol Coordinator: AnyObject {
    func start()
}

final class AppCoordinator: Coordinator {
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
        let repository = MockChatRepository(storage: storage)
        let apphudService = MockApphudService()
        let chatCoordinator = ChatCoordinator(navigationController: navigationController, repository: repository, apphudService: apphudService)
        self.chatCoordinator = chatCoordinator
        chatCoordinator.start()

        window.rootViewController = navigationController
        window.makeKeyAndVisible()
    }
}
