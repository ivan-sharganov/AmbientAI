import Foundation
import ApphudSDK
import StoreKit

enum ApphudPlan {
    case year
    case month
}

protocol ApphudServiceProtocol {
    var isPremium: Bool { get }
    var userID: String { get }
    func refreshStatus() async
    func purchase(plan: ApphudPlan) async throws -> Bool
    func restorePurchases() async throws -> Bool
    func logoutUserForTesting() async
    func printUserID()
}

final class MockApphudService: ApphudServiceProtocol {
    private(set) var isPremium: Bool
    let userID = "mock-apphud-user"

    init(isPremium: Bool = false) {
        self.isPremium = isPremium
    }

    func refreshStatus() async { }

    func purchase(plan: ApphudPlan) async throws -> Bool {
        isPremium = true
        return true
    }

    func restorePurchases() async throws -> Bool { isPremium }

    func logoutUserForTesting() async {
        isPremium = false
    }

    func printUserID() {
        print("Apphud User ID is unavailable in MockApphudService")
    }
}

final class ApphudService: ApphudServiceProtocol {
    private let apiKey: String
    private var isStarted = false
    private var isReady = false

    var isPremium: Bool {
        return Apphud.hasPremiumAccess()
    }

    var userID: String {
        Apphud.userID()
    }

    init(apiKey: String) {
        self.apiKey = apiKey
    }

    func start() {
        guard !isStarted else { return }
        isStarted = true
#if DEBUG
        Apphud.enableDebugLogs()
#endif
        startSDK()
    }

    private func startSDK() {
        Apphud.start(apiKey: apiKey) { [weak self] _ in
            self?.isReady = true
            self?.printUserID()
            print("[Apphud] Initial premium check completed: \(Apphud.hasPremiumAccess())")
            Task { await self?.logConfiguration() }
        }
    }

    func printUserID() {
        print("Apphud user_id: \(Apphud.userID())")
    }

    func refreshStatus() async {
        start()

        // Apphud refreshes subscriptions on start and whenever the app becomes active.
        // Wait for the initial customer response before allowing the premium gate to decide.
        for _ in 0..<50 where !isReady {
            try? await Task.sleep(nanoseconds: 100_000_000)
        }
        print("[Apphud] Refreshed premium=\(isPremium), ready=\(isReady)")
    }

    func purchase(plan: ApphudPlan) async throws -> Bool {
        if isPremium { return true }
        let product = try await product(for: plan)
        let result = await Apphud.purchase(product)
        print("[Apphud] Purchase result: \(result)")
        if let storeKitError = result.error as? SKError, storeKitError.code == .paymentCancelled {
            return false
        }
        if let error = result.error { throw error }
        return isPremium
    }

    func restorePurchases() async throws -> Bool {
        if let error = await Apphud.restorePurchases() { throw error }
        return isPremium
    }

    func logoutUserForTesting() async {
#if DEBUG
        isReady = false
        await Apphud.logout()
        print("[Apphud] Debug user logged out. Starting with a new user.")
        startSDK()
        await refreshStatus()
#endif
    }

    private func product(for plan: ApphudPlan) async throws -> ApphudProduct {
        let paywalls = try await loadPaywalls()
        guard let paywall = paywalls.first(where: { $0.identifier == "main" }) else {
            throw ApphudServiceError.paywallUnavailable
        }
        guard !paywall.products.isEmpty else { throw ApphudServiceError.productsUnavailable }

        let matchingProduct = paywall.products.first { product in
            guard let period = product.skProduct?.subscriptionPeriod else { return false }
            switch plan {
            case .year: return period.unit == .year
            case .month:
                return period.unit == .month
                    || period.unit == .week
                    || (period.unit == .day && period.numberOfUnits == 7)
            }
        }
        if let matchingProduct { return matchingProduct }

        let keyword = plan == .year ? "year" : "week"
        if let product = paywall.products.first(where: {
            $0.productId.localizedCaseInsensitiveContains(keyword)
                || ($0.name?.localizedCaseInsensitiveContains(keyword) ?? false)
        }) {
            return product
        }
        throw ApphudServiceError.planUnavailable(keyword)
    }

    private func logConfiguration() async {
        print("[Apphud] bundle_id=\(Bundle.main.bundleIdentifier ?? "nil")")
        print("[Apphud] user_id=\(userID), premium=\(isPremium)")
        do {
            let paywalls = try await loadPaywalls()
            print("[Apphud] paywalls_count=\(paywalls.count)")
            for paywall in paywalls {
                print("[Apphud] paywall='\(paywall.identifier)' products=\(paywall.products.count)")
                logProducts(paywall.products)
            }
        } catch {
            print("[Apphud] paywalls loading failed: \(error.localizedDescription)")
        }
    }

    private func loadPaywalls() async throws -> [ApphudPaywall] {
        try await withCheckedThrowingContinuation { continuation in
            Apphud.paywallsDidLoadCallback(maxAttempts: 3) { paywalls, error in
                if let error {
                    continuation.resume(throwing: error)
                } else {
                    continuation.resume(returning: paywalls)
                }
            }
        }
    }

    private func logProducts(_ products: [ApphudProduct]) {
        for product in products {
            let storeKitState = product.skProduct == nil ? "missing" : "loaded"
            let period = product.skProduct?.subscriptionPeriod.map {
                "\($0.numberOfUnits) \(periodName($0.unit))"
            } ?? "none"
            print("[Apphud] product_id='\(product.productId)' storekit=\(storeKitState) period=\(period)")
        }
    }

    private func periodName(_ unit: SKProduct.PeriodUnit) -> String {
        switch unit {
        case .day: return "day"
        case .week: return "week"
        case .month: return "month"
        case .year: return "year"
        @unknown default: return "unknown"
        }
    }
}

enum ApphudServiceError: LocalizedError {
    case paywallUnavailable
    case productsUnavailable
    case planUnavailable(String)

    var errorDescription: String? {
        switch self {
        case .paywallUnavailable:
            return "Apphud paywall 'main' is unavailable."
        case .productsUnavailable:
            return "No App Store products are configured for the Apphud paywall."
        case let .planUnavailable(plan):
            return "The \(plan) subscription is not configured in Apphud."
        }
    }
}
