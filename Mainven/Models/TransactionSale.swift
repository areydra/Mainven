
import Foundation
import CoreData

@objc(TransactionSale)
public class TransactionSale: NSManagedObject {

}

extension TransactionSale {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<TransactionSale> {
        return NSFetchRequest<TransactionSale>(entityName: "TransactionSale")
    }

    @NSManaged public var transactionID: UUID?
    @NSManaged public var date: Date?
    @NSManaged public var note: String?
    @NSManaged public var customer: Customer?
    @NSManaged public var saleItems: NSSet?

}

extension TransactionSale : Identifiable {

}
