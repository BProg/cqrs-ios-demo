import Foundation
import SwiftData

@Model
final class AggregatedUserProduct {
    @Attribute(.unique) var id: String
    var name: String
    var inWishlist: Bool

    init(id: String, name: String, inWishlist: Bool) {
        self.id = id
        self.name = name
        self.inWishlist = inWishlist
    }
}
