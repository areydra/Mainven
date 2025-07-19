import SwiftUI

struct ContactsTab: View {
    @State private var selectedTab: ContactType = .suppliers

    enum ContactType: String, CaseIterable, Identifiable {
        case suppliers = "Suppliers"
        case customers = "Customers"

        var id: String { self.rawValue }
    }

    var body: some View {
        NavigationView {
            VStack {
                Picker("Select Contact Type", selection: $selectedTab) {
                    ForEach(ContactType.allCases) { type in
                        Text(type.rawValue).tag(type)
                    }
                }
                .pickerStyle(.segmented)
                .padding(.horizontal)

                if selectedTab == .suppliers {
                    SupplierTab()
                } else {
                    CustomerTab()
                }
                Spacer()
            }
            .navigationTitle("Contacts")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}

#Preview {
    ContactsTab()
}