import Foundation
import ApphudSDK

protocol ApphudServiceProtocol {
    var isPremium: Bool { get }
    var userID: String { get }
    func refreshStatus() async
    func presentPaywallPlaceholder() async
    func printUserID()
}

final class MockApphudService: ApphudServiceProtocol {
    private(set) var isPremium: Bool
    let userID = "mock-apphud-user"

    init(isPremium: Bool = false) {
        self.isPremium = isPremium
    }

    func refreshStatus() async { }

    func presentPaywallPlaceholder() async { }

    func printUserID() {
        print("Apphud User ID is unavailable in MockApphudService")
    }
}

final class ApphudService: ApphudServiceProtocol {
    private let apiKey: String

    var isPremium: Bool {
        Apphud.hasPremiumAccess()
    }

    var userID: String {
        Apphud.userID()
    }

    init(apiKey: String) {
        self.apiKey = apiKey
    }

    func start() {
        Apphud.start(apiKey: apiKey) { [weak self] _ in
            self?.printUserID()
        }
    }

    func printUserID() {
        print("Apphud user_id: \(Apphud.userID())")
    }

    func refreshStatus() async { }

    func presentPaywallPlaceholder() async { }
}
