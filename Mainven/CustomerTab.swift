
import SwiftUI
import CoreData

struct CustomerTab: View {
    @Environment(\.managedObjectContext) private var viewContext
    @State private var searchText = ""

    var body: some View {
        let fetchRequest: FetchRequest<Customer>
        if searchText.isEmpty {
            fetchRequest = FetchRequest<Customer>(
                entity: NSEntityDescription.entity(forEntityName: "Customer", in: viewContext)!,
                sortDescriptors: [NSSortDescriptor(key: "name", ascending: true)]
            )
        } else {
            fetchRequest = FetchRequest<Customer>(
                entity: NSEntityDescription.entity(forEntityName: "Customer", in: viewContext)!,
                sortDescriptors: [NSSortDescriptor(key: "name", ascending: true)],
                predicate: NSPredicate(format: "name CONTAINS[cd] %@", searchText)
            )
        }
        return ContactManagementView<Customer>(title: "Customers", entityName: "Customer", fetchRequest: fetchRequest)
            .searchable(text: $searchText, prompt: "Search customers")
    }
}

#Preview {
    CustomerTab()
}
