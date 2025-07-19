
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
                    .environment(\.managedObjectContext, viewContext)
            }
        }
    }

    private func deletePurchaseTransactions(offsets: IndexSet) {
        withAnimation {
            offsets.map { purchaseTransactions[$0] }.forEach { purchaseTransaction in
                if let purchaseItems = purchaseTransaction.purchaseItems as? Set<PurchaseItem> {
                    for purchaseItem in purchaseItems {
                        if let product = purchaseItem.product {
                            product.stockQuantity -= purchaseItem.quantity
                            // Recalculate stockValue based on remaining stock and old costPrice
                            product.stockValue = product.costPrice * Double(product.stockQuantity)
                        }
                    }
                }
                viewContext.delete(purchaseTransaction)
            }

            do {
                try viewContext.performAndWait { // Use performAndWait for synchronous save
                    try viewContext.save()
                }
            } catch {
                let nsError = error as NSError
                fatalError("Unresolved error \(nsError), \(nsError.userInfo)")
            }
        }
    }
}

struct PurchaseTransactionSheet: View {
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.dismiss) var dismiss

    var transactionID: NSManagedObjectID? // Changed to accept objectID

    @State private var selectedSupplier: Supplier? = nil
    @State private var transactionDate: Date = Date()
    @State private var note: String = ""
    @State private var purchaseItems: [PurchaseItemData] = []

    @State private var fetchedTransaction: TransactionPurchase? // To hold the fetched object

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
            .navigationTitle(fetchedTransaction == nil ? "New Purchase" : "Edit Purchase")
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
            .onAppear {
                if let id = transactionID {
                    fetchedTransaction = viewContext.object(with: id) as? TransactionPurchase

                    if let purchaseTransaction = fetchedTransaction {
                        selectedSupplier = purchaseTransaction.supplier
                        transactionDate = purchaseTransaction.date ?? Date()
                        note = purchaseTransaction.note ?? ""

                        if let existingPurchaseItems = purchaseTransaction.purchaseItems as? Set<PurchaseItem> {
                            purchaseItems = existingPurchaseItems.map { PurchaseItemData(product: $0.product, quantity: Int($0.quantity), costPrice: $0.costPrice, minimumSalePrice: $0.minimumSalePrice) }
                        }
                    }
                }
            }
        }
    }

    private func savePurchaseTransaction() {
        guard let selectedSupplier = selectedSupplier else { return }

        let transactionToSave = fetchedTransaction ?? TransactionPurchase(context: viewContext)

        // If editing, revert old stock changes first
        if let existingTransaction = fetchedTransaction {
            if let oldPurchaseItems = existingTransaction.purchaseItems as? Set<PurchaseItem> {
                for oldPurchaseItem in oldPurchaseItems {
                    if let product = oldPurchaseItem.product {
                        product.stockQuantity -= oldPurchaseItem.quantity
                        // Recalculate stockValue based on remaining stock and old costPrice
                        product.stockValue = product.costPrice * Double(product.stockQuantity)
                    }
                }
            }
        }

        transactionToSave.transactionID = transactionToSave.transactionID ?? UUID()
        transactionToSave.date = transactionDate
        transactionToSave.note = note
        transactionToSave.supplier = selectedSupplier

        // Clear existing purchase items if editing
        if let existingPurchaseItems = transactionToSave.purchaseItems as? Set<PurchaseItem> {
            for item in existingPurchaseItems {
                viewContext.delete(item)
            }
        }

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
            newPurchaseItem.minimumSalePrice = itemData.minimumSalePrice
            newPurchaseItem.product = product // Link to Product
            newPurchaseItem.transactionPurchase = transactionToSave // Link to TransactionPurchase
        }

        do {
            try viewContext.performAndWait { // Use performAndWait for synchronous save
                try viewContext.save()
            }
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
    var minimumSalePrice: Double = 0.0
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
