
import Foundation
import CoreData

@objc(PurchaseItem)
public class PurchaseItem: NSManagedObject {

}

extension PurchaseItem {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<PurchaseItem> {
        return NSFetchRequest<PurchaseItem>(entityName: "PurchaseItem")
    }

    @NSManaged public var purchaseItemID: UUID?
    @NSManaged public var quantity: Int64
    @NSManaged public var costPrice: Double
    @NSManaged public var minimumSalePrice: Double
    @NSManaged public var product: Product?
    @NSManaged public var transactionPurchase: TransactionPurchase?

}

extension PurchaseItem : Identifiable {

}
