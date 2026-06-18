import Foundation

protocol ApphudServiceProtocol {
    var isPremium: Bool { get }
    func refreshStatus() async
    func presentPaywallPlaceholder() async
}

final class MockApphudService: ApphudServiceProtocol {
    private(set) var isPremium: Bool

    init(isPremium: Bool = false) {
        self.isPremium = isPremium
    }

    func refreshStatus() async { }

    func presentPaywallPlaceholder() async { }
}
