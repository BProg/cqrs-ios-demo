import Combine
import Foundation
import OSLog

@MainActor
final class AggregationService {
    typealias GetProductsFn = () -> [Product]
    typealias GetConsideredProductsFn = () -> [String]
    typealias SetAggregatedProductsFn = ([AggregatedUserProduct]) -> Void
    typealias UpdateAggregatedProductFn = (String, Bool) -> Void

    private let getProducts: GetProductsFn
    private let getConsideredProducts: GetConsideredProductsFn
    private let setAggregatedProducts: SetAggregatedProductsFn
    private let updateAggregatedProduct: UpdateAggregatedProductFn
    private let bus: EventBus
    private var subscriptions: Set<AnyCancellable> = []
    private let logger = Logger(subsystem: "CQRS-poc", category: "AggregationService")

    init(
        getProducts: @escaping GetProductsFn,
        getConsideredProducts: @escaping GetConsideredProductsFn,
        setAggregatedProducts: @escaping SetAggregatedProductsFn,
        updateAggregatedProduct: @escaping UpdateAggregatedProductFn,
        bus: EventBus
    ) {
        self.getProducts = getProducts
        self.getConsideredProducts = getConsideredProducts
        self.setAggregatedProducts = setAggregatedProducts
        self.updateAggregatedProduct = updateAggregatedProduct
        self.bus = bus
        subscribeToEvents()
    }

    func boot() {
        Task {
            let products = getProducts()
            let considered = Set(getConsideredProducts())

            let aggregated = products.map {
                AggregatedUserProduct(id: $0.id, name: $0.name, inWishlist: considered.contains($0.id))
            }

            setAggregatedProducts(aggregated)
        }
    }

    private func subscribeToEvents() {
        bus.receiveOnMain(ProductConsideredEvent.self)
            .sink { [weak self] event in
                Task { @MainActor [weak self] in
                    self?.onProductConsidered(event)
                }
            }
            .store(in: &subscriptions)

        bus.receiveOnMain(ProductUnconsideredEvent.self)
            .sink { [weak self] event in
                Task { @MainActor [weak self] in
                    self?.onProductUnconsidered(event)
                }
            }
            .store(in: &subscriptions)
    }

    private func onProductConsidered(_ event: ProductConsideredEvent) {
        let productId = event.payload
        logger.info("Consuming event: productConsidered productId=\(productId, privacy: .public)")
        updateAggregatedProduct(productId, true)
    }

    private func onProductUnconsidered(_ event: ProductUnconsideredEvent) {
        let productId = event.payload
        logger.info("Consuming event: productUnconsidered productId=\(productId, privacy: .public)")
        updateAggregatedProduct(productId, false)
    }
}
