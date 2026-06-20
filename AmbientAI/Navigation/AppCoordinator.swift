import UIKit

protocol Coordinator: AnyObject {
    func start()
}

final class AppCoordinator: Coordinator {
    private enum Configuration {
        static let apphudAPIKey = requiredValue(named: "APPHUD_API_KEY")
        static let dolaAppID = requiredValue(named: "DOLA_APP_ID")
        static let dolaBearerToken = requiredValue(named: "DOLA_BEARER_TOKEN")

        private static func requiredValue(named name: String) -> String {
            guard let value = Bundle.main.object(forInfoDictionaryKey: name) as? String,
                  !value.isEmpty,
                  !value.hasPrefix("$(") else {
                fatalError("Missing required value '\(name)' in Secrets.xcconfig")
            }
            return value
        }
    }

    private let window: UIWindow
    private let navigationController: UINavigationController
    private var chatCoordinator: ChatCoordinator?
    private var apphudService: ApphudService?

    init(window: UIWindow) {
        self.window = window
        self.navigationController = UINavigationController()
        self.navigationController.setNavigationBarHidden(true, animated: false)
    }

    func start() {
        clearLegacyLocalChatData()
        let apphudService = ApphudService(apiKey: Configuration.apphudAPIKey)
        self.apphudService = apphudService
        apphudService.start()
        let repository = DolaChatRepository(
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

    func applicationDidBecomeActive() {
        Task { [weak self] in
            await self?.apphudService?.refreshStatus()
        }
    }

    private func clearLegacyLocalChatData() {
        if let applicationSupport = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first {
            let fileURL = applicationSupport
                .appendingPathComponent("AmbientAI", isDirectory: true)
                .appendingPathComponent("chat_history.json")
            try? FileManager.default.removeItem(at: fileURL)
        }
        UserDefaults.standard.dictionaryRepresentation().keys
            .filter { $0.hasPrefix("deleted-dola-chats.") }
            .forEach { UserDefaults.standard.removeObject(forKey: $0) }
    }
}
