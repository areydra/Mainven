
import Foundation
import CoreData

@objc(Product)
public class Product: NSManagedObject {

}

extension Product {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<Product> {
        return NSFetchRequest<Product>(entityName: "Product")
    }

    @NSManaged public var productID: UUID?
    @NSManaged public var name: String?
    @NSManaged public var image: Data?
    @NSManaged public var costPrice: Double
    @NSManaged public var minimumSalePrice: Double
    @NSManaged public var stockQuantity: Int64
    @NSManaged public var stockValue: Double
    @NSManaged public var purchaseItems: NSSet?
    @NSManaged public var saleItems: NSSet?

}

extension Product : Identifiable {

}
