import Foundation
import CoreData

class ProductService {
    private var viewContext: NSManagedObjectContext

    init(context: NSManagedObjectContext) {
        self.viewContext = context
    }

    func saveProduct(
        productID: NSManagedObjectID?,
        name: String,
        costPrice: Double,
        minimumSalePrice: Double,
        stockQuantity: Int64,
        image: Data?
    ) {
        let productToSave: Product
        if let id = productID, let existingProduct = viewContext.object(with: id) as? Product {
            productToSave = existingProduct
        } else {
            productToSave = Product(context: viewContext)
            productToSave.productID = UUID()
        }

        productToSave.name = name
        productToSave.costPrice = costPrice
        productToSave.minimumSalePrice = minimumSalePrice
        productToSave.stockQuantity = stockQuantity
        productToSave.image = image
        productToSave.stockValue = (productToSave.costPrice) * Double(productToSave.stockQuantity)

        saveContext()
    }

    func deleteProduct(product: Product) {
        viewContext.delete(product)
        saveContext()
    }

    private func saveContext() {
        do {
            try viewContext.save()
        } catch {
            let nsError = error as NSError
            fatalError("Unresolved error \(nsError), \(nsError.userInfo)")
        }
    }
}
