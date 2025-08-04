

import SwiftUI
import CoreData

struct ContactManagementView<T: NSManagedObject & Identifiable>: View {
    @Environment(\.managedObjectContext) private var viewContext
    @FetchRequest var contacts: FetchedResults<T>
    @State private var showingAddContactSheet = false
    @State private var selectedContact: T? = nil

    let title: String
    let entityName: String

    init(title: String, entityName: String, fetchRequest: FetchRequest<T>) {
        self.title = title
        self.entityName = entityName
        self._contacts = fetchRequest
    }

    var body: some View {
        NavigationView {
            List {
                ForEach(contacts) { contact in
                    ContactCard(contact: contact)
                        .onTapGesture {
                            selectedContact = contact
                            showingAddContactSheet = true
                        }
                }
                .onDelete(perform: deleteContacts)
            }
            .navigationTitle(title)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    EditButton()
                }
                ToolbarItem {
                    Button(action: {
                        selectedContact = nil
                        showingAddContactSheet = true
                    }) {
                        Label("Add Contact", systemImage: "plus")
                    }
                }
            }
            .sheet(isPresented: $showingAddContactSheet) {
                AddEditContactSheet(contact: selectedContact, entityName: entityName)
                    .environment(\.managedObjectContext, viewContext)
            }
        }
    }

    private func deleteContacts(offsets: IndexSet) {
        withAnimation {
            let service = ContactService(context: viewContext)
            offsets.map { contacts[$0] }.forEach(service.deleteContact)
        }
    }
}

struct ContactCard<T: NSManagedObject & Identifiable>: View {
    let contact: T

    var body: some View {
        VStack(alignment: .leading) {
            if let name = contact.value(forKey: "name") as? String {
                Text(name)
                    .font(.headline)
            }
            if let location = contact.value(forKey: "location") as? String {
                Text(location)
                    .font(.subheadline)
            }
            if let phoneNumber = contact.value(forKey: "phoneNumber") as? String {
                Text(phoneNumber)
                    .font(.subheadline)
            }
        }
    }
}

struct AddEditContactSheet<T: NSManagedObject & Identifiable>: View {
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.dismiss) var dismiss

    @State private var name: String = ""
    @State private var location: String = ""
    @State private var phoneNumber: String = ""

    var contact: T?
    let entityName: String

    var body: some View {
        NavigationView {
            Form {
                TextField("Name", text: $name)
                TextField("Location", text: $location)
                TextField("Phone Number", text: $phoneNumber)
            }
            .navigationTitle(contact == nil ? "Add New \(entityName)" : "Edit \(entityName)")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        saveContact()
                        dismiss()
                    }
                }
            }
            .onAppear(perform: loadContactData)
        }
    }

    private func loadContactData() {
        if let contact = contact {
            name = contact.value(forKey: "name") as? String ?? ""
            location = contact.value(forKey: "location") as? String ?? ""
            phoneNumber = contact.value(forKey: "phoneNumber") as? String ?? ""
        }
    }

    private func saveContact() {
        let service = ContactService(context: viewContext)
        service.saveContact(
            contact: contact,
            entityName: entityName,
            name: name,
            location: location,
            phoneNumber: phoneNumber
        )
    }
}

