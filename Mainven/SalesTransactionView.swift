
import SwiftUI
import CoreData

struct SalesTransactionView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @FetchRequest(entity: TransactionSale.entity(), sortDescriptors: [NSSortDescriptor(keyPath: \TransactionSale.date, ascending: false)])
    var salesTransactions: FetchedResults<TransactionSale>

    @State private var showingAddSaleSheet = false

    var body: some View {
        NavigationView {
            List {
                ForEach(salesTransactions) { transaction in
                    SalesTransactionCardView(transaction: transaction)
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
            .sheet(isPresented: $showingAddSaleSheet) {
                AddSalesTransactionSheet()
                    .environment(\.managedObjectContext, viewContext)
            }
        }
    }

    private func deleteSalesTransactions(offsets: IndexSet) {
        withAnimation {
            offsets.map { salesTransactions[$0] }.forEach(viewContext.delete)

            do {
                try viewContext.save()
            } catch {
                let nsError = error as NSError
                fatalError("Unresolved error \(nsError), \(nsError.userInfo)")
            }
        }
    }
}

struct AddSalesTransactionSheet: View {
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.dismiss) var dismiss

    @State private var selectedCustomer: Customer? = nil
    @State private var transactionDate: Date = Date()
    @State private var note: String = ""
    @State private var saleItems: [SaleItemData] = []

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
            .navigationTitle("New Sale")
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
        }
    }

    private func saveSalesTransaction() {
        guard let selectedCustomer = selectedCustomer else { return }

        let newTransaction = TransactionSale(context: viewContext)
        newTransaction.transactionID = UUID()
        newTransaction.date = transactionDate
        newTransaction.note = note
        newTransaction.customer = selectedCustomer

        for itemData in saleItems {
            guard let product = itemData.product else { continue }

            // Decrease stock quantity
            product.stockQuantity -= Int64(itemData.quantity)
            product.stockValue = product.costPrice * Double(product.stockQuantity)

            // Create SaleItem
            let newSaleItem = SaleItem(context: viewContext)
            newSaleItem.saleItemID = UUID()
            newSaleItem.quantity = Int64(itemData.quantity)
            newSaleItem.salePrice = product.salePrice // Use product's current sale price
            newSaleItem.product = product // Link to Product
            newSaleItem.transactionSale = newTransaction // Link to TransactionSale
        }

        do {
            try viewContext.save()
        } catch {
            let nsError = error as NSError
            fatalError("Unresolved error \(nsError), \(nsError.userInfo)")
        }
    }
}

struct SaleItemData: Identifiable {
    let id = UUID()
    var product: Product? = nil // Link to actual Product entity
    var quantity: Int = 0
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
        }
    }
}

#Preview {
    SalesTransactionView()
        .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
}
