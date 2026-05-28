import Foundation
import OSLog
import SwiftData

@MainActor
final class SwiftDataWishlistRepository {
    private let container: ModelContainer
    private let logger = Logger(subsystem: "CQRS-poc", category: "WishlistRepository")
    private let context: ModelContext

    init(container: ModelContainer) {
        self.container = container
        self.context = ModelContext(container)
    }

    func getConsideredProducts() -> [String] {
        logger.info("Operation getConsideredProducts started")
        let descriptor = FetchDescriptor<ConsideredProduct>()
        let rows = (try? context.fetch(descriptor)) ?? []
        let productIds = rows.map(\.productId)
        logger.info("Operation getConsideredProducts completed. count=\(productIds.count, privacy: .public)")
        return productIds
    }

    func add(productId: String) {
        logger.info("Operation add started. productId=\(productId, privacy: .public)")
        let descriptor = FetchDescriptor<ConsideredProduct>(
            predicate: #Predicate { $0.productId == productId }
        )

        let exists = ((try? context.fetch(descriptor)) ?? []).isEmpty == false
        guard !exists else {
            logger.info("Operation add skipped. productId already considered=\(productId, privacy: .public)")
            return
        }

        context.insert(ConsideredProduct(productId: productId))
        try? context.save()
        logger.info("Operation add completed. productId=\(productId, privacy: .public)")
    }

    func remove(productId: String) {
        logger.info("Operation remove started. productId=\(productId, privacy: .public)")
        let descriptor = FetchDescriptor<ConsideredProduct>(
            predicate: #Predicate { $0.productId == productId }
        )
        let rows = (try? context.fetch(descriptor)) ?? []
        rows.forEach(context.delete)
        try? context.save()
        logger.info("Operation remove completed. productId=\(productId, privacy: .public), removed=\(rows.count, privacy: .public)")
    }
}
