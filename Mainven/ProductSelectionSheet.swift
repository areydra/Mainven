
import SwiftUI
import CoreData

struct ProductSelectionSheet: View {
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.dismiss) var dismiss

    @FetchRequest(entity: Product.entity(), sortDescriptors: [NSSortDescriptor(keyPath: \Product.name, ascending: true)])
    var products: FetchedResults<Product>

    @Binding var selectedProduct: Product?

    var body: some View {
        NavigationView {
            List {
                ForEach(products) { product in
                    Button(action: {
                        selectedProduct = product
                        dismiss()
                    }) {
                        HStack {
                            Text(product.name ?? "Unknown Product")
                            Spacer()
                            if selectedProduct == product {
                                Image(systemName: "checkmark")
                            }
                        }
                    }
                }
            }
            .navigationTitle("Select Product")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
    }
}

