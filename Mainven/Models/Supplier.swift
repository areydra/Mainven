
import Foundation
import CoreData

@objc(Supplier)
public class Supplier: NSManagedObject {

}

extension Supplier {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<Supplier> {
        return NSFetchRequest<Supplier>(entityName: "Supplier")
    }

    @NSManaged public var supplierID: UUID?
    @NSManaged public var name: String?
    @NSManaged public var location: String?
    @NSManaged public var phoneNumber: String?
    @NSManaged public var purchaseTransactions: NSSet?

}

extension Supplier : Identifiable {

}
