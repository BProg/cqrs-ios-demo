import Foundation

enum Command {
    case considerProduct(productId: String)
    case unconsiderProduct(productId: String)
}

final class ConsiderProductCommand: EventBase<String> {}
final class UnconsiderProductCommand: EventBase<String> {}

extension Command {
    var event: any EventProtocol {
        switch self {
        case let .considerProduct(productId):
            ConsiderProductCommand(productId)
        case let .unconsiderProduct(productId):
            UnconsiderProductCommand(productId)
        }
    }
}
