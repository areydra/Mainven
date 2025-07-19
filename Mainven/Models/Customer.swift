
import Foundation
import CoreData

@objc(Customer)
public class Customer: NSManagedObject {

}

extension Customer {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<Customer> {
        return NSFetchRequest<Customer>(entityName: "Customer")
    }

    @NSManaged public var customerID: UUID?
    @NSManaged public var name: String?
    @NSManaged public var location: String?
    @NSManaged public var phoneNumber: String?
    @NSManaged public var saleTransactions: NSSet?

}

extension Customer : Identifiable {

}
