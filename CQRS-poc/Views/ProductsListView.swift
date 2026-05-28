import SwiftUI
import SwiftData

struct ProductsListView: View {
    @Query(sort: [SortDescriptor(\AggregatedUserProduct.name)])
    private var products: [AggregatedUserProduct]

    var body: some View {
        NavigationStack {
            List {
                ForEach(products, id: \.id) { product in
                    ProductCardView(product: product)
                }
            }
            .navigationTitle("Products")
        }
    }
}

#Preview {
    ProductsListView()
}
