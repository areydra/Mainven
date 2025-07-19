
import SwiftUI

import SwiftUI
import CoreData

struct ProductsTab: View {
    @Environment(\.managedObjectContext) private var viewContext
    @FetchRequest(entity: Product.entity(), sortDescriptors: [NSSortDescriptor(keyPath: \Product.name, ascending: true)])
    var products: FetchedResults<Product>

    @State private var showingAddEditProductSheet = false
    @State private var selectedProduct: Product? = nil

    var body: some View {
        NavigationView {
            List {
                ForEach(products) { product in
                    ProductCardView(product: product)
                        .onTapGesture {
                            selectedProduct = product
                            showingAddEditProductSheet = true
                        }
                }
                .onDelete(perform: deleteProducts)
            }
            .navigationTitle("Products")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    EditButton()
                }
                ToolbarItem {
                    Button(action: {
                        selectedProduct = nil // Clear selection for new product
                        showingAddEditProductSheet = true
                    }) {
                        Label("Add Product", systemImage: "plus")
                    }
                }
            }
            .sheet(isPresented: $showingAddEditProductSheet) {
                AddEditProductSheet(product: selectedProduct)
                    .environment(\.managedObjectContext, viewContext)
            }
        }
    }

    private func deleteProducts(offsets: IndexSet) {
        withAnimation {
            offsets.map { products[$0] }.forEach(viewContext.delete)

            do {
                try viewContext.save()
            } catch {
                let nsError = error as NSError
                fatalError("Unresolved error \(nsError), \(nsError.userInfo)")
            }
        }
    }
}

struct ProductCardView: View {
    @ObservedObject var product: Product

    var body: some View {
        HStack {
            if let imageData = product.image, let uiImage = UIImage(data: imageData) {
                Image(uiImage: uiImage)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 50, height: 50)
                    .cornerRadius(8)
            } else {
                Image(systemName: "photo")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 50, height: 50)
                    .cornerRadius(8)
                    .foregroundColor(.gray)
            }
            VStack(alignment: .leading) {
                Text(product.name ?? "Unknown Product")
                    .font(.headline)
                HStack {
                    Text("Cost: \(product.costPrice, format: .currency(code: "IDR"))")
                    Spacer()
                    Text("Sale: \(product.salePrice, format: .currency(code: "IDR"))")
                }
                HStack {
                    Text("Stock: \(product.stockQuantity)")
                    Spacer()
                    Text("Value: \(product.stockValue, format: .currency(code: "IDR"))")
                }
            }
        }
    }
}

struct AddEditProductSheet: View {
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.dismiss) var dismiss

    @State private var name: String = ""
    @State private var costPrice: Double = 0.0
    @State private var salePrice: Double = 0.0
    @State private var stockQuantity: Int64 = 0
    @State private var image: Data? = nil // For product image
    @State private var showingImagePicker = false

    var product: Product?

    var body: some View {
        NavigationView {
            Form {
                TextField("Product Name", text: $name)
                TextField("Cost Price", value: $costPrice, format: .number)
                    .keyboardType(.decimalPad)
                TextField("Sale Price", value: $salePrice, format: .number)
                    .keyboardType(.decimalPad)
                TextField("Stock Quantity", value: $stockQuantity, format: .number)
                    .keyboardType(.numberPad)
                // Image Picker
                Button(action: {
                    showingImagePicker = true
                }) {
                    if let imageData = image, let uiImage = UIImage(data: imageData) {
                        Image(uiImage: uiImage)
                            .resizable()
                            .scaledToFit()
                            .frame(width: 100, height: 100)
                            .cornerRadius(10)
                    } else {
                        Image(systemName: "photo.on.rectangle.angled")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 100, height: 100)
                            .cornerRadius(10)
                            .foregroundColor(.gray)
                    }
                }
                .sheet(isPresented: $showingImagePicker) {
                    ImagePicker(selectedImage: $image)
                }
            }
            .navigationTitle(product == nil ? "Add New Product" : "Edit Product")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        saveProduct()
                        dismiss()
                    }
                }
            }
            .onAppear {
                if let product = product {
                    name = product.name ?? ""
                    costPrice = product.costPrice
                    salePrice = product.salePrice
                    stockQuantity = product.stockQuantity
                    image = product.image
                }
            }
        }
    }

    private func saveProduct() {
        let productToSave = product ?? Product(context: viewContext)
        productToSave.productID = productToSave.productID ?? UUID()
        productToSave.name = name
        productToSave.costPrice = costPrice
        productToSave.salePrice = salePrice
        productToSave.stockQuantity = stockQuantity
        productToSave.image = image
        productToSave.stockValue = costPrice * Double(stockQuantity)

        do {
            try viewContext.save()
        } catch {
            let nsError = error as NSError
            fatalError("Unresolved error \(nsError), \(nsError.userInfo)")
        }
    }
}

#Preview {
    ProductsTab()
        .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
}
