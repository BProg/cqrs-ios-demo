import Foundation

enum Event {
    case productConsidered(productId: String)
    case productUnconsidered(productId: String)
}

final class ProductConsideredEvent: EventBase<String> {}
final class ProductUnconsideredEvent: EventBase<String> {}

extension Event {
    var event: any EventProtocol {
        switch self {
        case let .productConsidered(productId):
            ProductConsideredEvent(productId)
        case let .productUnconsidered(productId):
            ProductUnconsideredEvent(productId)
        }
    }
}
