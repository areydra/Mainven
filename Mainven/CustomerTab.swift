
import SwiftUI

import CoreData

struct CustomerTab: View {
    @Environment(\.managedObjectContext) private var viewContext

    var body: some View {
        let fetchRequest = FetchRequest<Customer>(
            entity: NSEntityDescription.entity(forEntityName: "Customer", in: viewContext)!,
            sortDescriptors: [NSSortDescriptor(key: "name", ascending: true)]
        )
        return ContactManagementView<Customer>(title: "Customers", entityName: "Customer", fetchRequest: fetchRequest)
    }
}

#Preview {
    CustomerTab()
}
