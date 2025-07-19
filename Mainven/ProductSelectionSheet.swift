
import SwiftUI
import CoreData

struct ProductSelectionSheet: View {
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.dismiss) var dismiss

    @FetchRequest(entity: Product.entity(), sortDescriptors: [NSSortDescriptor(keyPath: \Product.name, ascending: true)])
    var products: FetchedResults<Product>

    @Binding var selectedProduct: Product?
    var shouldShowAddProduct: Bool = false
    @State private var showingAddProductSheet = false

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
                if (shouldShowAddProduct) {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button(action: {
                            showingAddProductSheet = true
                        }) {
                            Label("Add Product", systemImage: "plus")
                        }
                    }
                }
            }
            .sheet(isPresented: $showingAddProductSheet) {
                AddEditProductSheet(productID: nil) // Pass nil for new product
                    .environment(\.managedObjectContext, viewContext)
            }
        }
    }
}

