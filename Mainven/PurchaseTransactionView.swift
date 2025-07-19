
import SwiftUI
import CoreData

struct PurchaseTransactionView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @FetchRequest(entity: TransactionPurchase.entity(), sortDescriptors: [NSSortDescriptor(keyPath: \TransactionPurchase.date, ascending: false)])
    var purchaseTransactions: FetchedResults<TransactionPurchase>

    @State private var showingAddPurchaseSheet = false

    var body: some View {
        NavigationView {
            List {
                ForEach(purchaseTransactions) { transaction in
                    PurchaseTransactionCardView(transaction: transaction)
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
            .sheet(isPresented: $showingAddPurchaseSheet) {
                AddPurchaseTransactionSheet()
                    .environment(\.managedObjectContext, viewContext)
            }
        }
    }

    private func deletePurchaseTransactions(offsets: IndexSet) {
        withAnimation {
            offsets.map { purchaseTransactions[$0] }.forEach(viewContext.delete)

            do {
                try viewContext.save()
            } catch {
                let nsError = error as NSError
                fatalError("Unresolved error \(nsError), \(nsError.userInfo)")
            }
        }
    }
}

struct AddPurchaseTransactionSheet: View {
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.dismiss) var dismiss

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
                    // TODO: Add option to add new supplier
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
            .navigationTitle("New Purchase")
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
        }
    }

    private func savePurchaseTransaction() {
        guard let selectedSupplier = selectedSupplier else { return }

        let newTransaction = TransactionPurchase(context: viewContext)
        newTransaction.transactionID = UUID()
        newTransaction.date = transactionDate
        newTransaction.note = note
        newTransaction.supplier = selectedSupplier

        for itemData in purchaseItems {
            guard let product = itemData.product else { continue }

            // COGS Calculation and Product Update
            let oldQuantity = product.stockQuantity
            let oldCostPrice = product.costPrice
            let newQuantity = Int64(itemData.quantity)
            let newCostPrice = itemData.costPrice

            if oldQuantity == 0 {
                // Initial Stock COGS Formula
                product.costPrice = newCostPrice
            } else {
                // Additional Stock COGS Formula (Weighted Average)
                product.costPrice = ((Double(oldQuantity) * oldCostPrice) + (Double(newQuantity) * newCostPrice)) / (Double(oldQuantity) + Double(newQuantity))
            }

            product.stockQuantity += newQuantity
            product.stockValue = product.costPrice * Double(product.stockQuantity)

            // Create PurchaseItem
            let newPurchaseItem = PurchaseItem(context: viewContext)
            newPurchaseItem.purchaseItemID = UUID()
            newPurchaseItem.quantity = newQuantity
            newPurchaseItem.costPrice = newCostPrice
            newPurchaseItem.product = product // Link to Product
            newPurchaseItem.transactionPurchase = newTransaction // Link to TransactionPurchase
        }

        do {
            try viewContext.save()
        } catch {
            let nsError = error as NSError
            fatalError("Unresolved error \(nsError), \(nsError.userInfo)")
        }
    }
}

struct PurchaseItemData: Identifiable {
    let id = UUID()
    var product: Product? = nil // Link to actual Product entity
    var quantity: Int = 0
    var costPrice: Double = 0.0 // Cost price for this specific purchase item
}

struct PurchaseItemRow: View {
    @Environment(\.managedObjectContext) private var viewContext
    @Binding var item: PurchaseItemData
    @State private var showingProductSelection = false

    var body: some View {
        VStack(alignment: .leading) {
            Button(action: {
                showingProductSelection = true
            }) {
                Text(item.product?.name ?? "Select Product")
                    .foregroundColor(item.product == nil ? .gray : .primary)
            }
            .sheet(isPresented: $showingProductSelection) {
                ProductSelectionSheet(selectedProduct: $item.product)
                    .environment(\.managedObjectContext, viewContext)
            }

            TextField("Quantity", value: $item.quantity, format: .number)
                .keyboardType(.numberPad)
            TextField("Cost Price (per unit)", value: $item.costPrice, format: .number)
                .keyboardType(.decimalPad)
        }
    }
}

#Preview {
    PurchaseTransactionView()
        .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
}
