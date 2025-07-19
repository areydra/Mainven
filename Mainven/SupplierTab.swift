
import SwiftUI

import CoreData

struct SupplierTab: View {
    @Environment(\.managedObjectContext) private var viewContext

    var body: some View {
        let fetchRequest = FetchRequest<Supplier>(
            entity: NSEntityDescription.entity(forEntityName: "Supplier", in: viewContext)!,
            sortDescriptors: [NSSortDescriptor(key: "name", ascending: true)]
        )
        return ContactManagementView<Supplier>(title: "Suppliers", entityName: "Supplier", fetchRequest: fetchRequest)
    }
}

#Preview {
    SupplierTab()
}
