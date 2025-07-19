
import Foundation
import CoreData

@objc(SaleItem)
public class SaleItem: NSManagedObject {

}

extension SaleItem {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<SaleItem> {
        return NSFetchRequest<SaleItem>(entityName: "SaleItem")
    }

    @NSManaged public var quantity: Int64
    @NSManaged public var saleItemID: UUID?
    @NSManaged public var salePrice: Double
    @NSManaged public var customSalePrice: Double
    @NSManaged public var product: Product?
    @NSManaged public var transactionSale: TransactionSale?

}

extension SaleItem : Identifiable {

}
