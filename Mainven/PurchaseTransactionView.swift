
import SwiftUI
import CoreData

struct PurchaseTransactionView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @FetchRequest(entity: TransactionPurchase.entity(), sortDescriptors: [NSSortDescriptor(keyPath: \TransactionPurchase.date, ascending: false)])
    var purchaseTransactions: FetchedResults<TransactionPurchase>

    @State private var selectedPurchaseTransactionID: ManagedObjectIDWrapper? = nil
    @State private var showingAddPurchaseSheet = false

    var body: some View {
        NavigationView {
            List {
                ForEach(purchaseTransactions) { transaction in
                    PurchaseTransactionCardView(transaction: transaction)
                        .onTapGesture {
                            selectedPurchaseTransactionID = ManagedObjectIDWrapper(id: transaction.objectID)
                        }
                }
                .onDelete(perform: deletePurchaseTransactions)
            }
            .navigationTitle("Purchase Transactions")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    EditButton()
                }
                ToolbarItem {
                    Button(action: {
                        showingAddPurchaseSheet = true
                    }) {
                        Label("Add Transaction", systemImage: "plus")
                    }
                }
            }
            .sheet(item: $selectedPurchaseTransactionID) { wrapper in
                PurchaseTransactionSheet(transactionID: wrapper.id)
                    .environment(\.managedObjectContext, viewContext)
            }
            .sheet(isPresented: $showingAddPurchaseSheet) {
                PurchaseTransactionSheet(transactionID: nil)
                    .environment(\.managedObject-Context, viewContext)
            }
        }
    }

    private func deletePurchaseTransactions(offsets: IndexSet) {
        withAnimation {
            let service = TransactionService(context: viewContext)
            offsets.map { purchaseTransactions[$0] }.forEach(service.deletePurchaseTransaction)
        }
    }
}

struct PurchaseTransactionSheet: View {
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.dismiss) var dismiss

    var transactionID: NSManagedObjectID?

    @State private var selectedSupplier: Supplier? = nil
    @State private var transactionDate: Date = Date()
    @State private var note: String = ""
    @State private var purchaseItems: [PurchaseItemData] = []

    @FetchRequest(entity: Supplier.entity(), sortDescriptors: [NSSortDescriptor(keyPath: \Supplier.name, ascending: true)])
    var suppliers: FetchedResults<Supplier>

    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Supplier")) {
                    Picker("Select Supplier", selection: $selectedSupplier) {
                        Text("Select a supplier").tag(nil as Supplier?)
                        ForEach(suppliers) { supplier in
                            Text(supplier.name ?? "Unknown").tag(supplier as Supplier?)
                        }
                    }
                    .pickerStyle(.navigationLink)
                }

                Section(header: Text("Products")) {
                    ForEach($purchaseItems) { $item in
                        PurchaseItemRow(item: $item)
                    }
                    Button("Add Product") {
                        purchaseItems.append(PurchaseItemData())
                    }
                }

                Section(header: Text("Details")) {
                    DatePicker("Date", selection: $transactionDate, displayedComponents: .date)
                    TextField("Note", text: $note)
                }
            }
            .navigationTitle(transactionID == nil ? "New Purchase" : "Edit Purchase")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        savePurchaseTransaction()
                        dismiss()
                    }
                }
            }
            .onAppear(perform: loadTransactionData)
        }
    }

    private func loadTransactionData() {
        if let id = transactionID, let transaction = viewContext.object(with: id) as? TransactionPurchase {
            selectedSupplier = transaction.supplier
            transactionDate = transaction.date ?? Date()
            note = transaction.note ?? ""
            if let items = transaction.purchaseItems as? Set<PurchaseItem> {
                purchaseItems = items.map { PurchaseItemData(from: $0) }
            }
        }
    }

    private func savePurchaseTransaction() {
        guard let supplier = selectedSupplier else { return }
        let service = TransactionService(context: viewContext)
        service.savePurchaseTransaction(
            transactionID: transactionID,
            supplier: supplier,
            date: transactionDate,
            note: note,
            items: purchaseItems
        )
    }
}

struct PurchaseItemData: Identifiable {
    let id = UUID()
    var product: Product? = nil
    var quantity: Int = 0
    var costPrice: Double = 0.0
    var minimumSalePrice: Double = 0.0

    init(from item: PurchaseItem? = nil) {
        if let item = item {
            self.product = item.product
            self.quantity = Int(item.quantity)
            self.costPrice = item.costPrice
            self.minimumSalePrice = item.minimumSalePrice
        }
    }
}

struct PurchaseItemRow: View {
    @Environment(\.managedObjectContext) private var viewContext
    @Binding var item: PurchaseItemData
    @State private var showingProductSelection = false

    var body: some View {
        VStack(alignment: .leading) {
            Button(action: { showingProductSelection = true }) {
                Text(item.product?.name ?? "Select Product")
                    .foregroundColor(item.product == nil ? .gray : .primary)
            }
            .sheet(isPresented: $showingProductSelection) {
                ProductSelectionSheet(selectedProduct: $item.product, shouldShowAddProduct: true)
                    .environment(\.managedObjectContext, viewContext)
            }

            TextField("Quantity", value: $item.quantity, format: .number)
                .keyboardType(.numberPad)
            TextField("Cost Price (per unit)", value: $item.costPrice, format: .number)
                .keyboardType(.decimalPad)
            TextField("Minimum Sale Price (per unit)", value: $item.minimumSalePrice, format: .number)
                .keyboardType(.decimalPad)
        }
    }
}

#Preview {
    PurchaseTransactionView()
        .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
}
