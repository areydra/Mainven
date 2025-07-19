
import SwiftUI

import SwiftUI
import CoreData

struct ProductsTab: View {
    @Environment(\.managedObjectContext) private var viewContext
    @FetchRequest(entity: Product.entity(), sortDescriptors: [NSSortDescriptor(keyPath: \Product.name, ascending: true)])
    var products: FetchedResults<Product>

    @State private var showingAddEditProductSheet = false
    @State private var selectedProductID: ManagedObjectIDWrapper? = nil

    var body: some View {
        NavigationView {
            List {
                ForEach(products) { product in
                    ProductCardView(product: product)
                        .onTapGesture {
                            selectedProductID = ManagedObjectIDWrapper(id: product.objectID)
                        }
                }
                .onDelete(perform: deleteProducts)
            }
            .navigationTitle("Products")
            // .toolbar {
                // ToolbarItem(placement: .navigationBarTrailing) {
                //     EditButton()
                // }
                // ToolbarItem {
                //     Button(action: {
                //         selectedProductID = nil // Clear selection for new product
                //     }) {
                //         Label("Add Product", systemImage: "plus")
                //     }
                // }
            // }
            .sheet(item: $selectedProductID) { wrapper in
                AddEditProductSheet(productID: wrapper.id)
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
                    Text("Minimum Sale: \(product.minimumSalePrice, format: .currency(code: "IDR"))")
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
    @State private var minimumSalePrice: Double = 0.0
    @State private var stockQuantity: Int64 = 0
    @State private var image: Data? = nil // For product image
    @State private var showingImagePicker = false

    var productID: NSManagedObjectID? // Changed to accept objectID

    @State private var fetchedProduct: Product? // To hold the fetched object

    var body: some View {
        NavigationView {
            Form {
                TextField("Product Name", text: $name)
                    .disabled(productID != nil)
                TextField("Cost Price", value: $costPrice, format: .number)
                    .keyboardType(.decimalPad)
                    .disabled(productID != nil)
                TextField("Minimum Sale Price", value: $minimumSalePrice, format: .number)
                    .keyboardType(.decimalPad)
                TextField("Stock Quantity", value: $stockQuantity, format: .number)
                    .keyboardType(.numberPad)
                    .disabled(productID != nil)
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
            .navigationTitle(fetchedProduct == nil ? "Add New Product" : "Edit Product")
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
                if let id = productID {
                    fetchedProduct = viewContext.object(with: id) as? Product
                    
                    if let product = fetchedProduct {
                        name = product.name ?? ""
                        costPrice = product.costPrice
                        minimumSalePrice = product.minimumSalePrice
                        stockQuantity = product.stockQuantity
                        image = product.image
                    }
                }
            }
        }
    }

    private func saveProduct() {
        let productToSave = fetchedProduct ?? Product(context: viewContext)
        productToSave.productID = productToSave.productID ?? UUID()
        if productID == nil {
            productToSave.name = name
            productToSave.costPrice = costPrice
            productToSave.stockQuantity = stockQuantity
        }
        productToSave.minimumSalePrice = minimumSalePrice
        productToSave.image = image
        productToSave.stockValue = (productToSave.costPrice) * Double(productToSave.stockQuantity)

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
