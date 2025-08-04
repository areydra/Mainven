import Foundation
import CoreData

class ContactService {
    private var viewContext: NSManagedObjectContext

    init(context: NSManagedObjectContext) {
        self.viewContext = context
    }

    func saveContact<T: NSManagedObject>(
        contact: T?,
        entityName: String,
        name: String,
        location: String,
        phoneNumber: String
    ) {
        let contactToSave: NSManagedObject
        if let contact = contact {
            contactToSave = contact
        } else {
            contactToSave = NSEntityDescription.insertNewObject(forEntityName: entityName, into: viewContext)
            contactToSave.setValue(UUID(), forKey: "\(entityName.lowercased())ID")
        }

        contactToSave.setValue(name, forKey: "name")
        contactToSave.setValue(location, forKey: "location")
        contactToSave.setValue(phoneNumber, forKey: "phoneNumber")

        saveContext()
    }

    func deleteContact<T: NSManagedObject>(contact: T) {
        viewContext.delete(contact)
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
