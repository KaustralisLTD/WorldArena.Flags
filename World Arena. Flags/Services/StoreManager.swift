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
    
    @Published var products: [Product] = []
    @Published var purchasedProductIDs: Set<String> = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    // Mock products for development
    private var mockProducts: [MockProduct] = []
    private var isUsingMockProducts = false
    
    // Product IDs — должны совпадать с App Store Connect (раздел Подписки или Встроенные покупки)
    private let productIDs: Set<String> = [
        "WorldArena.Flags.MonthPremium2025",   // подписка в разделе Подписки
        "WorldArena.Flags.YearlyPremium2025"  // подписка в разделе Подписки
    ]
    
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
            
            let products = try await Product.products(for: productIDs)
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
                isUsingMockProducts = false
                #endif
            } else {
                isUsingMockProducts = false
            }
        } catch {
            print("❌ Failed to load products: \(error)")
            print("Error details: \(error.localizedDescription)")
            
            if let storeError = error as? StoreKitError {
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
        // Добавить родительский контроль
        guard parentalGatePassed() else {
            print("❌ Parental gate not passed")
            errorMessage = "Parental gate not passed"
            return false
        }

        isLoading = true
        errorMessage = nil
        
        print("🛒 Starting purchase for product: \(product.id)")
        
        guard SKPaymentQueue.canMakePayments() else {
            print("❌ Payments not allowed")
            errorMessage = "In-app purchases are not allowed on this device"
            isLoading = false
            return false
        }
        
        do {
            let result = try await product.purchase()
            
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
                isLoading = false
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
            errorMessage = "Purchase failed: \(error.localizedDescription)"
        }
        
        isLoading = false
        return false
    }

    private func parentalGatePassed() -> Bool {
        // Логика проверки родительского контроля
        // Например, простая математическая задача
        return true // Заменить на реальную проверку
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
        product(for: "WorldArena.Flags.MonthlyAccess")
    }
    
    var yearlyProduct: Product? {
        product(for: "WorldArena.Flags.TotalAccess")
    }
    
    // MARK: - Mock Product Helpers
    
    func mockProduct(for id: String) -> MockProduct? {
        mockProducts.first { $0.id == id }
    }
    
        var monthlyMockProduct: MockProduct? {
        mockProduct(for: "WorldArena.Flags.MonthPremium2025")
    }

    var yearlyMockProduct: MockProduct? {
        mockProduct(for: "WorldArena.Flags.YearlyPremium2025")
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
    
    var errorDescription: String? {
        switch self {
        case .failedVerification:
            return "Transaction verification failed"
        case .productNotFound:
            return "Product not found"
        case .purchaseFailed:
            return "Purchase failed"
        }
    }
}
