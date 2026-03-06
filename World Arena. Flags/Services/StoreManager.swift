import Foundation
import StoreKit

// MARK: - Mock Product for Development
struct MockProduct {
    let id: String
    let displayName: String
    let description: String
    let price: Decimal
    let displayPrice: String
}

@MainActor
class StoreManager: ObservableObject {
    static let shared = StoreManager()
    private static let productLoadTimeoutNanoseconds: UInt64 = 15_000_000_000
    private static let purchaseTimeoutNanoseconds: UInt64 = 30_000_000_000
    
    @Published var products: [Product] = []
    @Published var purchasedProductIDs: Set<String> = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    // Mock products for development
    private var mockProducts: [MockProduct] = []
    private var isUsingMockProducts = false
    
    // Product IDs — только активные автопродляемые подписки.
    private let monthlyProductIDCandidates: [String] = [
        "WorldArena.Flags.MonthPremium2025"
    ]
    private let yearlyProductIDCandidates: [String] = [
        "WorldArena.Flags.YearlyPremium2025"
    ]
    private var productIDs: Set<String> {
        Set(monthlyProductIDCandidates + yearlyProductIDCandidates)
    }
    
    private init() {
        // Загружаем сохраненные покупки
        loadPurchasedProductsFromStorage()
        
        // Инициализация
        Task {
            await updatePurchasedProducts()
            await loadProducts()
        }
    }
    
    // MARK: - Product Loading
    
    func loadProducts() async {
        // Защита от залипания одновременных запросов
        if isLoading {
            return
        }
        isLoading = true
        errorMessage = nil
        
        print("🔄 Loading products with IDs: \(productIDs)")
        
        do {
            // Проверяем доступность StoreKit
            guard SKPaymentQueue.canMakePayments() else {
                print("❌ In-app purchases are disabled")
                errorMessage = "In-app purchases are disabled on this device"
                #if DEBUG
                await loadMockProducts()
                #endif
                isLoading = false
                return
            }
            
            let products = try await fetchProductsWithTimeout()
            self.products = products.sorted { $0.price < $1.price }
            print("✅ Loaded \(products.count) products from App Store")
            
            // Логируем каждый продукт
            for product in products {
                print("📦 Product: \(product.id) - \(product.displayName) - \(product.displayPrice)")
            }
            
            if products.isEmpty {
                #if DEBUG
                print("⚠️ No products loaded, using mock products for development")
                await loadMockProducts()
                #else
                errorMessage = "No subscription products are currently available. Please tap Retry."
                isUsingMockProducts = false
                #endif
            } else {
                isUsingMockProducts = false
            }
        } catch {
            print("❌ Failed to load products: \(error)")
            print("Error details: \(error.localizedDescription)")
            
            if let localStoreError = error as? StoreError, case .timeout = localStoreError {
                errorMessage = "Timed out loading products. Please tap Retry."
            } else if let storeError = error as? StoreKitError {
                switch storeError {
                case .networkError(let underlyingError):
                    errorMessage = "Network error: \(underlyingError.localizedDescription)"
                case .systemError(let underlyingError):
                    errorMessage = "System error: \(underlyingError.localizedDescription)"
                case .notAvailableInStorefront:
                    errorMessage = "Products not available in your region"
                case .notEntitled:
                    errorMessage = "Not entitled to purchase"
                default:
                    errorMessage = "Store error: \(error.localizedDescription)"
                }
            } else {
                errorMessage = "Failed to load products: \(error.localizedDescription)"
            }
            
            #if DEBUG
            await loadMockProducts()
            #endif
        }
        
        isLoading = false
    }

    /// Повторная загрузка для UI-кнопок "Tap to load price" и "Retry".
    func retryLoadProducts() async {
        // Явно сбрасываем прошлую ошибку и зависший state перед новой попыткой.
        errorMessage = nil
        if isLoading {
            isLoading = false
        }
        await loadProducts()
    }

    private func fetchProductsWithTimeout() async throws -> [Product] {
        let ids = productIDs
        return try await withThrowingTaskGroup(of: [Product].self) { group in
            group.addTask {
                try await Product.products(for: ids)
            }
            group.addTask {
                try await Task.sleep(nanoseconds: Self.productLoadTimeoutNanoseconds)
                throw StoreError.timeout
            }
            guard let firstFinished = try await group.next() else {
                throw StoreError.timeout
            }
            group.cancelAll()
            return firstFinished
        }
    }
    
    // MARK: - Mock Products for Development
    
    private func loadMockProducts() async {
        print("🔧 Loading mock products for development...")
        
                // Создаем моковые продукты для разработки
        mockProducts = [
            MockProduct(
                id: "WorldArena.Flags.MonthPremium2025",
                displayName: "Monthly Premium",
                description: "Monthly access to all premium features",
                price: Decimal(1.99),
                displayPrice: "$1.99"
            ),
            MockProduct(
                id: "WorldArena.Flags.YearlyPremium2025",
                displayName: "Yearly Premium",
                description: "Yearly access to all premium features",
                price: Decimal(5.99),
                displayPrice: "$5.99"
            )
        ]
        
        isUsingMockProducts = true
        print("✅ Loaded \(mockProducts.count) mock products")
    }
    
    // MARK: - Purchase
    
    func purchase(_ product: Product) async -> Bool {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }
        
        print("🛒 Starting purchase for product: \(product.id)")
        
        guard SKPaymentQueue.canMakePayments() else {
            print("❌ Payments not allowed")
            errorMessage = "In-app purchases are not allowed on this device"
            return false
        }
        
        do {
            let result = try await purchaseWithTimeout(product)
            
            switch result {
            case .success(let verificationResult):
                print("✅ Purchase successful, verifying...")
                let transaction = try checkVerified(verificationResult)
                
                print("✅ Transaction verified: \(transaction.productID)")
                
                // Обновляем статус покупки
                await updatePurchasedProducts()
                
                // Завершаем транзакцию
                await transaction.finish()
                
                print("✅ Purchase completed for: \(product.id)")
                return true
                
            case .userCancelled:
                print("⚠️ User cancelled purchase")
                errorMessage = "Purchase cancelled"
                
            case .pending:
                print("⏳ Purchase pending")
                errorMessage = "Purchase is pending approval"
                
            @unknown default:
                print("❌ Unknown purchase result")
                errorMessage = "Unknown error occurred"
            }
        } catch {
            print("❌ Purchase failed: \(error)")
            if let localStoreError = error as? StoreError, case .purchaseTimeout = localStoreError {
                errorMessage = "Purchase request timed out. Please try again."
            } else {
                errorMessage = "Purchase failed: \(error.localizedDescription)"
            }
        }
        
        return false
    }

    private func purchaseWithTimeout(_ product: Product) async throws -> Product.PurchaseResult {
        try await withThrowingTaskGroup(of: Product.PurchaseResult.self) { group in
            group.addTask {
                try await product.purchase()
            }
            group.addTask {
                try await Task.sleep(nanoseconds: Self.purchaseTimeoutNanoseconds)
                throw StoreError.purchaseTimeout
            }
            guard let firstFinished = try await group.next() else {
                throw StoreError.purchaseTimeout
            }
            group.cancelAll()
            return firstFinished
        }
    }

    // MARK: - Restore Purchases
    
    func restorePurchases() async {
        isLoading = true
        errorMessage = nil
        
        do {
            try await AppStore.sync()
            await updatePurchasedProducts()
            print("✅ Purchases restored")
        } catch {
            print("❌ Failed to restore purchases: \(error)")
            errorMessage = "Failed to restore purchases: \(error.localizedDescription)"
        }
        
        isLoading = false
    }
    
    // MARK: - Check Purchased Products
    
    func updatePurchasedProducts() async {
        var purchasedIDs: Set<String> = []
        
        for await result in Transaction.currentEntitlements {
            do {
                let transaction = try checkVerified(result)
                
                // Проверяем, что транзакция активна
                if transaction.productType == .autoRenewable {
                    purchasedIDs.insert(transaction.productID)
                }
            } catch {
                print("❌ Failed to verify transaction: \(error)")
            }
        }
        
        // Если используем mock продукты, сохраняем существующие mock покупки
        if isUsingMockProducts && !purchasedProductIDs.isEmpty {
            // Добавляем реальные покупки к существующим mock покупкам
            purchasedIDs = purchasedIDs.union(purchasedProductIDs)
            print("🔧 Preserving mock purchases: \(purchasedProductIDs)")
        }
        
        self.purchasedProductIDs = purchasedIDs
        print("✅ Updated purchased products: \(purchasedIDs)")
        
        // Сохраняем изменения в UserDefaults
        savePurchasedProductsToStorage()
    }
    
    // MARK: - Verification
    
    private func checkVerified<T>(_ result: VerificationResult<T>) throws -> T {
        switch result {
        case .unverified:
            throw StoreError.failedVerification
        case .verified(let safe):
            return safe
        }
    }
    
    // MARK: - Premium Status
    
    var isPremium: Bool {
        !purchasedProductIDs.isEmpty
    }
    
    // MARK: - Product Helpers
    
    func product(for id: String) -> Product? {
        products.first { $0.id == id }
    }
    
    var monthlyProduct: Product? {
        products.first { monthlyProductIDCandidates.contains($0.id) }
    }
    
    var yearlyProduct: Product? {
        products.first { yearlyProductIDCandidates.contains($0.id) }
    }
    
    // MARK: - Mock Product Helpers
    
    func mockProduct(for id: String) -> MockProduct? {
        mockProducts.first { $0.id == id }
    }
    
    var monthlyMockProduct: MockProduct? {
        mockProducts.first { monthlyProductIDCandidates.contains($0.id) }
    }

    var yearlyMockProduct: MockProduct? {
        mockProducts.first { yearlyProductIDCandidates.contains($0.id) }
    }
    
    var hasProducts: Bool {
        !products.isEmpty || !mockProducts.isEmpty
    }
    
    // MARK: - Persistence
    
    private let purchasedProductsStorageKey = "store.purchased.products"
    private let mockProductsStorageKey = "store.is.using.mock.products"
    
    private func loadPurchasedProductsFromStorage() {
        #if DEBUG
        if let data = UserDefaults.standard.data(forKey: purchasedProductsStorageKey),
           let productIDs = try? JSONDecoder().decode(Set<String>.self, from: data) {
            self.purchasedProductIDs = productIDs
            print("✅ Loaded purchased products from storage: \(productIDs)")
        }
        self.isUsingMockProducts = UserDefaults.standard.bool(forKey: mockProductsStorageKey)
        if isUsingMockProducts {
            print("🔧 Using mock products mode")
        }
        #else
        // В Release только реальные покупки из Transaction.currentEntitlements; mock и сохранённые ID не используем
        self.isUsingMockProducts = false
        self.purchasedProductIDs = []
        #endif
    }
    
    private func savePurchasedProductsToStorage() {
        if let data = try? JSONEncoder().encode(purchasedProductIDs) {
            UserDefaults.standard.set(data, forKey: purchasedProductsStorageKey)
            UserDefaults.standard.set(isUsingMockProducts, forKey: mockProductsStorageKey)
            print("💾 Saved purchased products to storage: \(purchasedProductIDs)")
            if isUsingMockProducts {
                print("🔧 Saved mock products mode: true")
            }
        }
    }

    // MARK: - Mock Purchase for Development (only in DEBUG; no-op in Release)
    
    func simulateMockPurchase(productID: String) {
        #if DEBUG
        print("🔧 Simulating mock purchase for: \(productID)")
        isUsingMockProducts = true
        purchasedProductIDs.insert(productID)
        savePurchasedProductsToStorage()
        print("✅ Mock purchase completed. Premium status: \(isPremium)")
        #endif
    }
    
    func cancelMockSubscription() {
        #if DEBUG
        print("🔧 Cancelling mock subscription...")
        purchasedProductIDs.removeAll()
        isUsingMockProducts = false
        savePurchasedProductsToStorage()
        print("✅ Mock subscription cancelled. Premium status: \(isPremium)")
        #endif
    }
}

// MARK: - Store Errors

enum StoreError: Error, LocalizedError {
    case failedVerification
    case productNotFound
    case purchaseFailed
    case timeout
    case purchaseTimeout
    
    var errorDescription: String? {
        switch self {
        case .failedVerification:
            return "Transaction verification failed"
        case .productNotFound:
            return "Product not found"
        case .purchaseFailed:
            return "Purchase failed"
        case .timeout:
            return "Request timed out"
        case .purchaseTimeout:
            return "Purchase request timed out"
        }
    }
}
