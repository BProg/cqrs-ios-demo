import Foundation
import OSLog
import SwiftData

@MainActor
final class SwiftDataAggregatedProductsRepository {
    private let container: ModelContainer
    private let logger = Logger(subsystem: "CQRS-poc", category: "AggregatedProductsRepository")
    private let context: ModelContext

    init(container: ModelContainer) {
        self.container = container
        self.context = ModelContext(container)
    }

    func setAggregatedProducts(_ products: [AggregatedUserProduct]) {
        logger.info("Operation setAggregatedProducts started. incoming=\(products.count, privacy: .public)")
        let fetchAll = FetchDescriptor<AggregatedUserProduct>()
        let existing = (try? context.fetch(fetchAll)) ?? []
        existing.forEach(context.delete)

        products.forEach { product in
            context.insert(
                AggregatedUserProduct(id: product.id, name: product.name, inWishlist: product.inWishlist)
            )
        }

        try? context.save()
        logger.info("Operation setAggregatedProducts completed. replaced=\(existing.count, privacy: .public), inserted=\(products.count, privacy: .public)")
    }

    func updateConsidered(id: String, inWishlist: Bool) {
        logger.info("Operation updateConsidered started. id=\(id, privacy: .public), inWishlist=\(String(inWishlist), privacy: .public)")
        let descriptor = FetchDescriptor<AggregatedUserProduct>(
            predicate: #Predicate { $0.id == id }
        )

        if let product = (try? context.fetch(descriptor))?.first {
            product.inWishlist = inWishlist
            try? context.save()
            logger.info("Operation updateConsidered completed. id=\(id, privacy: .public)")
        } else {
            logger.info("Operation updateConsidered skipped. product not found id=\(id, privacy: .public)")
        }
    }
}
