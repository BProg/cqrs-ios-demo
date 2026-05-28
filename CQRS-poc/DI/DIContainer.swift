import Foundation
import SwiftData

@MainActor
final class DIContainer {
    let eventBus: EventBus
    let dataModelsContainer: ModelContainer
    let viewModelsContainer: ModelContainer

    let productsRepository: SwiftDataProductsRepository
    let wishlistRepository: SwiftDataWishlistRepository
    let aggregatedProductsRepository: SwiftDataAggregatedProductsRepository

    let wishlistService: WishlistService
    let aggregationService: AggregationService

    init() {
        let bus = EventBus()
        self.eventBus = bus
        do {
            let appSupportURL = try Self.appSupportDirectoryURL()
            let dataStoreURL = appSupportURL.appendingPathComponent("DataModels.store")
            let viewModelsStoreURL = appSupportURL.appendingPathComponent("ViewModels.store")

            let dataModelsSchema = Schema([
                StoredProduct.self,
                ConsideredProduct.self
            ])
            let viewModelsDBSchema = Schema([AggregatedUserProduct.self])

            self.dataModelsContainer = try ModelContainer(
                for: dataModelsSchema,
                configurations: [
                    ModelConfiguration(
                        "DataModels",
                        schema: dataModelsSchema,
                        url: dataStoreURL,
                        allowsSave: true
                    )
                ]
            )

            self.viewModelsContainer = try ModelContainer(
                for: viewModelsDBSchema,
                configurations: [
                    ModelConfiguration(
                        "ViewModels",
                        schema: viewModelsDBSchema,
                        url: viewModelsStoreURL,
                        allowsSave: true
                    )
                ]
            )
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }

        self.productsRepository = SwiftDataProductsRepository(container: dataModelsContainer)
        self.wishlistRepository = SwiftDataWishlistRepository(container: dataModelsContainer)
        self.aggregatedProductsRepository = SwiftDataAggregatedProductsRepository(container: viewModelsContainer)

        productsRepository.seedIfNeeded()

        self.wishlistService = WishlistService(
            add: { [wishlistRepository] productId in
                wishlistRepository.add(productId: productId)
            },
            remove: { [wishlistRepository] productId in
                wishlistRepository.remove(productId: productId)
            },
            bus: bus
        )

        self.aggregationService = AggregationService(
            getProducts: { [productsRepository] in
                productsRepository.getProducts()
            },
            getConsideredProducts: { [wishlistRepository] in
                wishlistRepository.getConsideredProducts()
            },
            setAggregatedProducts: { [aggregatedProductsRepository] products in
                aggregatedProductsRepository.setAggregatedProducts(products)
            },
            updateAggregatedProduct: { [aggregatedProductsRepository] productId, inWishlist in
                aggregatedProductsRepository.updateConsidered(id: productId, inWishlist: inWishlist)
            },
            bus: bus
        )
    }

    private static func appSupportDirectoryURL() throws -> URL {
        let fileManager = FileManager.default
        guard let baseURL = fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask).first else {
            throw NSError(domain: "CQRS-poc", code: 1, userInfo: [NSLocalizedDescriptionKey: "Application Support directory not found"])
        }

        try fileManager.createDirectory(at: baseURL, withIntermediateDirectories: true)
        return baseURL
    }
}
