import SwiftUI
import CoreData

struct SalesTransactionView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @FetchRequest(entity: TransactionSale.entity(), sortDescriptors: [NSSortDescriptor(keyPath: \TransactionSale.date, ascending: false)])
    var salesTransactions: FetchedResults<TransactionSale>

    @State private var selectedSalesTransactionID: ManagedObjectIDWrapper? = nil
    @State private var showingAddSaleSheet = false

    var body: some View {
        NavigationView {
            List {
                ForEach(salesTransactions) { transaction in
                    SalesTransactionCardView(transaction: transaction)
                        .onTapGesture {
                            selectedSalesTransactionID = ManagedObjectIDWrapper(id: transaction.objectID)
                        }
                }
                .onDelete(perform: deleteSalesTransactions)
            }
            .navigationTitle("Sales Transactions")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    EditButton()
                }
                ToolbarItem {
                    Button(action: {
                        showingAddSaleSheet = true
                    }) {
                        Label("Add Transaction", systemImage: "plus")
                    }
                }
            }
            .sheet(item: $selectedSalesTransactionID) { wrapper in
                SalesTransactionSheet(transactionID: wrapper.id)
                    .environment(\.managedObjectContext, viewContext)
            }
            .sheet(isPresented: $showingAddSaleSheet) {
                SalesTransactionSheet(transactionID: nil)
                    .environment(\.managedObjectContext, viewContext)
            }
        }
    }

    private func deleteSalesTransactions(offsets: IndexSet) {
        withAnimation {
            let service = TransactionService(context: viewContext)
            offsets.map { salesTransactions[$0] }.forEach(service.deleteSalesTransaction)
        }
    }
}

struct SalesTransactionSheet: View {
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.dismiss) var dismiss

    var transactionID: NSManagedObjectID? // Changed to accept objectID

    @State private var selectedCustomer: Customer? = nil
    @State private var transactionDate: Date = Date()
    @State private var note: String = ""
    @State private var saleItems: [SaleItemData] = []

    @State private var fetchedTransaction: TransactionSale? // To hold the fetched object

    @FetchRequest(entity: Customer.entity(), sortDescriptors: [NSSortDescriptor(keyPath: \Customer.name, ascending: true)])
    var customers: FetchedResults<Customer>

    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Customer")) {
                    Picker("Select Customer", selection: $selectedCustomer) {
                        Text("Select a customer").tag(nil as Customer?)
                        ForEach(customers) { customer in
                            Text(customer.name ?? "Unknown").tag(customer as Customer?)
                        }
                    }
                    .pickerStyle(.navigationLink)
                    // TODO: Add option to add new customer
                }

                Section(header: Text("Products")) {
                    ForEach($saleItems) { $item in
                        SaleItemRow(item: $item)
                    }
                    Button("Add Product") {
                        saleItems.append(SaleItemData())
                    }
                }

                Section(header: Text("Details")) {
                    DatePicker("Date", selection: $transactionDate, displayedComponents: .date)
                    TextField("Note", text: $note)
                }
            }
            .navigationTitle(fetchedTransaction == nil ? "New Sale" : "Edit Sale")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        saveSalesTransaction()
                        dismiss()
                    }
                }
            }
            .onAppear {
                if let id = transactionID {
                    fetchedTransaction = viewContext.object(with: id) as? TransactionSale

                    if let salesTransaction = fetchedTransaction {
                        selectedCustomer = salesTransaction.customer
                        transactionDate = salesTransaction.date ?? Date()
                        note = salesTransaction.note ?? ""

                        if let existingSaleItems = salesTransaction.saleItems as? Set<SaleItem> {
                            saleItems = existingSaleItems.map { SaleItemData(product: $0.product, quantity: Int($0.quantity), customSalePrice: $0.customSalePrice) }
                        }
                    }
                }
            }
        }
    }

    private func saveSalesTransaction() {
        guard let customer = selectedCustomer else { return }
        let service = TransactionService(context: viewContext)
        service.saveSalesTransaction(
            transactionID: transactionID,
            customer: customer,
            date: transactionDate,
            note: note,
            items: saleItems
        )
    }
}

struct SaleItemData: Identifiable {
    let id = UUID()
    var product: Product? = nil // Link to actual Product entity
    var quantity: Int = 0
    var customSalePrice: Double = 0.0
}

struct SaleItemRow: View {
    @Environment(\.managedObjectContext) private var viewContext
    @Binding var item: SaleItemData
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
            TextField("Custom Sale Price", value: $item.customSalePrice, format: .number)
                .keyboardType(.decimalPad)
        }
    }
}

#Preview {
    SalesTransactionView()
        .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
}