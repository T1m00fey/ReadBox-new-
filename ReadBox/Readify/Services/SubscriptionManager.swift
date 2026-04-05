//
//  SubscriptionManager.swift
//  ReadBox
//
//  Created by Тимофей Юдин on 24.03.2026.
//

import StoreKit

@MainActor
final class SubscriptionManager: ObservableObject {
    @Published var product: Product?
    @Published var hasPremium: Bool = false

    private let productID = "ReadBox.Sub.Month"

    func start() {
        Task {
            await loadProduct()
            await refreshEntitlements()
            listenForUpdates()
        }
    }

    func loadProduct() async {
        do {
            let products = try await Product.products(for: [productID])
            print("IAP products count:", products.count, "ids:", products.map{$0.id})
            product = products.first
        } catch {
            print("loadProduct error:", error)
        }
    }

    func buy() async {
        guard let product else { return }
        do {
            let result = try await product.purchase()
            switch result {
            case .success(let verification):
                let tx = try verified(verification)
                await tx.finish()
                await refreshEntitlements()
            case .userCancelled, .pending:
                break
            @unknown default:
                break
            }
        } catch {
            print("buy error:", error)
        }
    }

    func refreshEntitlements() async {
        var premium = false
        for await result in Transaction.currentEntitlements {
            if let tx = try? verified(result), tx.productID == productID {
                premium = true
            }
        }
        hasPremium = premium
    }

    private func listenForUpdates() {
        Task.detached { [weak self] in
            guard let self else { return }
            for await result in Transaction.updates {
                if let tx = try? await self.verified(result) {
                    await tx.finish()
                    await self.refreshEntitlements()
                }
            }
        }
    }

    private func verified<T>(_ result: VerificationResult<T>) throws -> T {
        switch result {
        case .verified(let safe): return safe
        case .unverified: throw NSError(domain: "IAP", code: 1)
        }
    }
}
