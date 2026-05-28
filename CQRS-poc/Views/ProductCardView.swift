import SwiftUI

struct ProductCardView: View {
    @Environment(\.bus) private var bus
    let product: AggregatedUserProduct

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(product.name)
                    .font(.headline)
                Text(product.id)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            Button(product.inWishlist ? "In wishlist" : "Add") {
                toggleConsideredState()
            }
            .buttonStyle(.borderedProminent)
            .tint(product.inWishlist ? .orange : .blue)
        }
        .padding(.vertical, 6)
    }

    private func toggleConsideredState() {
        let command: Command = product.inWishlist
            ? .unconsiderProduct(productId: product.id)
            : .considerProduct(productId: product.id)

        bus.send(command.event)
    }
}
