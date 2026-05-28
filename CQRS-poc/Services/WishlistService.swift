import Combine
import Foundation
import OSLog

@MainActor
final class WishlistService {
    typealias AddProductFn = (String) -> Void
    typealias RemoveProductFn = (String) -> Void

    private let add: AddProductFn
    private let remove: RemoveProductFn
    private let bus: EventBus
    private var subscriptions: Set<AnyCancellable> = []
    private let logger = Logger(subsystem: "CQRS-poc", category: "WishlistService")

    init(
        add: @escaping AddProductFn,
        remove: @escaping RemoveProductFn,
        bus: EventBus
    ) {
        self.add = add
        self.remove = remove
        self.bus = bus
        subscribeToCommands()
    }

    private func handle(_ command: Command) {
        logger.info("Handling command: \(String(describing: command), privacy: .public)")
        switch command {
        case let .considerProduct(productId):
            considerProduct(id: productId)
        case let .unconsiderProduct(productId):
            unconsiderProduct(id: productId)
        }
    }

    func considerProduct(id: String) {
        add(id)
        publish(.productConsidered(productId: id))
    }

    func unconsiderProduct(id: String) {
        remove(id)
        publish(.productUnconsidered(productId: id))
    }

    private func publish(_ event: Event) {
        logger.info("Publishing event: \(String(describing: event), privacy: .public)")
        bus.send(event.event)
    }

    private func subscribeToCommands() {
        bus.receiveOnMain(ConsiderProductCommand.self)
            .sink { [weak self] command in
                Task { @MainActor [weak self] in
                    self?.handle(.considerProduct(productId: command.payload))
                }
            }
            .store(in: &subscriptions)

        bus.receiveOnMain(UnconsiderProductCommand.self)
            .sink { [weak self] command in
                Task { @MainActor [weak self] in
                    self?.handle(.unconsiderProduct(productId: command.payload))
                }
            }
            .store(in: &subscriptions)
    }
}
