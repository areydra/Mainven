
import SwiftUI
import CoreData

struct TopSalesProductsView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.dismiss) var dismiss

    @Binding var selectedMonth: Date

    @FetchRequest(entity: TransactionSale.entity(), sortDescriptors: [NSSortDescriptor(keyPath: \TransactionSale.date, ascending: false)])
    var salesTransactions: FetchedResults<TransactionSale>

    var body: some View {
        NavigationView {
            List {
                DatePicker(
                    "Select Month",
                    selection: $selectedMonth,
                    displayedComponents: .date
                )
                .datePickerStyle(.compact)
                .labelsHidden()
                .padding(.bottom, 5)

                if topSalesProducts.isEmpty {
                    Text("No sales data available for this month.")
                        .foregroundColor(.gray)
                } else {
                    ForEach(topSalesProducts, id: \.product.objectID) { product, quantity in
                        HStack {
                            Text(product.name ?? "Unknown Product")
                            Spacer()
                            Text("\(quantity) units sold")
                        }
                    }
                }
            }
            .navigationTitle("All Top Sales Products")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }

    private var topSalesProducts: [(product: Product, quantity: Int)] {
        var productSales: [Product: Int] = [:]

        let calendar = Calendar.current
        let filteredSalesTransactions = salesTransactions.filter { transaction in
            guard let transactionDate = transaction.date else { return false }
            return calendar.isDate(transactionDate, equalTo: selectedMonth, toGranularity: .month)
        }

        for transaction in filteredSalesTransactions {
            if let saleItems = transaction.saleItems as? Set<SaleItem> {
                for item in saleItems {
                    if let product = item.product {
                        productSales[product, default: 0] += Int(item.quantity)
                    }
                }
            }
        }

        return productSales.sorted { $0.value > $1.value }.map { (product: $0.key, quantity: $0.value) }
    }
}

#Preview {
    TopSalesProductsView(selectedMonth: .constant(Date()))
        .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
}
