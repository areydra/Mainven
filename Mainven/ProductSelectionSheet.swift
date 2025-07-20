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
    @State private var searchText = ""

    var filteredProducts: [Product] {
        if searchText.isEmpty {
            return Array(products)
        } else {
            return products.filter { product in
                product.name?.localizedCaseInsensitiveContains(searchText) ?? false
            }
        }
    }

    var body: some View {
        NavigationView {
            List {
                ForEach(filteredProducts) { product in
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
            .searchable(text: $searchText, prompt: "Search for a product")
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