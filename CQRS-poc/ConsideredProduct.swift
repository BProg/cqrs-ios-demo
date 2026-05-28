import Foundation
import SwiftData

@Model
final class ConsideredProduct {
    @Attribute(.unique) var productId: String

    init(productId: String) {
        self.productId = productId
    }
}
