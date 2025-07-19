
import Foundation
import CoreData

@objc(TransactionPurchase)
public class TransactionPurchase: NSManagedObject {

}

extension TransactionPurchase {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<TransactionPurchase> {
        return NSFetchRequest<TransactionPurchase>(entityName: "TransactionPurchase")
    }

    @NSManaged public var transactionID: UUID?
    @NSManaged public var date: Date?
    @NSManaged public var note: String?
    @NSManaged public var supplier: Supplier?
    @NSManaged public var purchaseItems: NSSet?

}

extension TransactionPurchase : Identifiable {

}
