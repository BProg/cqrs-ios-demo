import Foundation
import OSLog
import SwiftData

@MainActor
final class SwiftDataProductsRepository {
    private let container: ModelContainer
    private let logger = Logger(subsystem: "CQRS-poc", category: "ProductsRepository")
    private let context: ModelContext

    init(container: ModelContainer) {
        self.container = container
        self.context = ModelContext(container)
    }

    func getProducts() -> [Product] {
        logger.info("Operation getProducts started")
        let descriptor = FetchDescriptor<StoredProduct>(sortBy: [SortDescriptor(\.name)])
        let rows = (try? context.fetch(descriptor)) ?? []
        let products = rows.map { Product(id: $0.id, name: $0.name) }
        logger.info("Operation getProducts completed. count=\(products.count, privacy: .public)")
        return products
    }

    func seedIfNeeded() {
        logger.info("Operation seedIfNeeded started")
        let descriptor = FetchDescriptor<StoredProduct>()
        let existingCount = (try? context.fetchCount(descriptor)) ?? 0
        guard existingCount == 0 else {
            logger.info("Operation seedIfNeeded skipped. existingCount=\(existingCount, privacy: .public)")
            return
        }

        let seedProducts = [
            Product(id: "P-001", name: "iPhone 17 Pro"),
            Product(id: "P-002", name: "MacBook Air M5"),
            Product(id: "P-003", name: "AirPods Max 2"),
            Product(id: "P-004", name: "Apple Watch Ultra 3"),
            Product(id: "P-005", name: "Vision Pro 2")
        ]

        seedProducts
            .map { StoredProduct(id: $0.id, name: $0.name) }
            .forEach(context.insert)

        try? context.save()
        logger.info("Operation seedIfNeeded completed. inserted=\(seedProducts.count, privacy: .public)")
    }
}
