
import SwiftUI

import CoreData

struct SupplierTab: View {
    @Environment(\.managedObjectContext) private var viewContext
    @State private var searchText = ""

    var body: some View {
        let fetchRequest: FetchRequest<Supplier>
        if searchText.isEmpty {
            fetchRequest = FetchRequest<Supplier>(
                entity: NSEntityDescription.entity(forEntityName: "Supplier", in: viewContext)!,
                sortDescriptors: [NSSortDescriptor(key: "name", ascending: true)]
            )
        } else {
            fetchRequest = FetchRequest<Supplier>(
                entity: NSEntityDescription.entity(forEntityName: "Supplier", in: viewContext)!,
                sortDescriptors: [NSSortDescriptor(key: "name", ascending: true)],
                predicate: NSPredicate(format: "name CONTAINS[cd] %@", searchText)
            )
        }
        return ContactManagementView<Supplier>(title: "Suppliers", entityName: "Supplier", fetchRequest: fetchRequest)
            .searchable(text: $searchText, prompt: "Search suppliers")
    }
}

#Preview {
    SupplierTab()
}
