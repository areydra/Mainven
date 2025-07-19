
import SwiftUI
import CoreData

struct HomeTab: View {
    @Environment(\.managedObjectContext) private var viewContext

    @FetchRequest(entity: Product.entity(), sortDescriptors: [])
    var products: FetchedResults<Product>

    @FetchRequest(entity: TransactionSale.entity(), sortDescriptors: [NSSortDescriptor(keyPath: \TransactionSale.date, ascending: false)])
    var salesTransactions: FetchedResults<TransactionSale>

    @FetchRequest(entity: TransactionPurchase.entity(), sortDescriptors: [NSSortDescriptor(keyPath: \TransactionPurchase.date, ascending: false)])
    var purchaseTransactions: FetchedResults<TransactionPurchase>

    @State private var selectedDate: Date = Date()
    @State private var selectedMonthForTopSales: Date = Date()

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // Date Picker for Daily Performance
                    DatePicker(
                        "Select Date",
                        selection: $selectedDate,
                        displayedComponents: .date
                    )
                    .datePickerStyle(.compact)
                    .padding(.horizontal)

                    // Inventory Snapshot
                    VStack(alignment: .leading) {
                        Text("Inventory Snapshot")
                            .font(.title2)
                            .padding(.bottom, 5)

                        HStack {
                            Text("Total Products:")
                            Spacer()
                            Text("\(totalProducts)")
                        }
                        HStack {
                            Text("Total Stock:")
                            Spacer()
                            Text("\(totalStock)")
                        }
                        HStack {
                            Text("Total Stock Value:")
                            Spacer()
                            Text("(\(totalStockValue, format: .currency(code: "IDR")))")
                        }
                    }
                    .padding()
                    .background(Color.gray.opacity(0.1))
                    .cornerRadius(10)

                    // Daily Performance
                    VStack(alignment: .leading) {
                        Text("Daily Performance (\(selectedDate, formatter: dateFormatter))")
                            .font(.title2)
                            .padding(.bottom, 5)
                        HStack {
                            Text("Total Quantity Sold:")
                            Spacer()
                            Text("\(totalQuantitySoldForSelectedDate)")
                        }
                        HStack {
                            Text("Total Revenue:")
                            Spacer()
                            Text("(\(totalRevenueForSelectedDate, format: .currency(code: "IDR")))")
                        }
                        HStack {
                            Text("Total Profit:")
                            Spacer()
                            Text("(\(totalProfitForSelectedDate, format: .currency(code: "IDR")))")
                        }
                    }
                    .padding()
                    .background(Color.gray.opacity(0.1))
                    .cornerRadius(10)

                    // Top Sales Products
                    VStack(alignment: .leading) {
                        HStack {
                            Text("Top Sales Products")
                                .font(.title2)
                            Spacer()
                            Button("See All") {
                                showTopSalesModal = true
                            }
                        }
                        .padding(.bottom, 5)

                        DatePicker(
                            "Select Month",
                            selection: $selectedMonthForTopSales,
                            displayedComponents: .date
                        )
                        .datePickerStyle(.compact)
                        .labelsHidden()
                        .padding(.bottom, 5)

                        if topSalesProducts.isEmpty {
                            Text("No sales data available for this month.")
                                .foregroundColor(.gray)
                        } else {
                            ForEach(topSalesProducts.prefix(10), id: \.product.objectID) { product, quantity in
                                HStack {
                                    Text(product.name ?? "Unknown Product")
                                    Spacer()
                                    Text("\(quantity) units")
                                }
                            }
                        }
                    }
                    .padding()
                    .background(Color.gray.opacity(0.1))
                    .cornerRadius(10)

                }
                .padding()
            }
            .navigationTitle("Dashboard")
            .sheet(isPresented: $showTopSalesModal) {
                TopSalesProductsView(selectedMonth: $selectedMonthForTopSales)
                    .environment(\.managedObjectContext, viewContext)
            }
        }
    }

    @State private var showTopSalesModal: Bool = false

    private var topSalesProducts: [(product: Product, quantity: Int)] {
        var productSales: [Product: Int] = [:]

        let calendar = Calendar.current
        let filteredSalesTransactions = salesTransactions.filter { transaction in
            guard let transactionDate = transaction.date else { return false }
            return calendar.isDate(transactionDate, equalTo: selectedMonthForTopSales, toGranularity: .month)
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

    private var totalProducts: Int {
        products.count
    }

    private var totalStock: Int {
        products.reduce(0) { $0 + Int($1.stockQuantity) }
    }

    private var totalStockValue: Double {
        products.reduce(0.0) { $0 + $1.stockValue }
    }

    private var totalRevenueForSelectedDate: Double {
        salesTransactions.filter { Calendar.current.isDate($0.date ?? Date(), inSameDayAs: selectedDate) }
            .reduce(0.0) { total, transaction in
                transaction.saleItems?.reduce(total) { itemTotal, item in
                    if let saleItem = item as? SaleItem {
                        return itemTotal + (Double(saleItem.quantity) * (saleItem.customSalePrice ?? saleItem.minimumSalePrice))
                    }
                    return itemTotal
                } ?? total
            }
    }

    private var totalProfitForSelectedDate: Double {
        let dailySales = salesTransactions.filter { Calendar.current.isDate($0.date ?? Date(), inSameDayAs: selectedDate) }

        var totalRevenue: Double = 0.0
        var totalCostOfSoldGoods: Double = 0.0

        for saleTransaction in dailySales {
            if let saleItems = saleTransaction.saleItems as? Set<SaleItem> {
                for saleItem in saleItems {
                    totalRevenue += (Double(saleItem.quantity) * (saleItem.customSalePrice ?? saleItem.minimumSalePrice))
                    // To calculate profit, we need the cost price of the product at the time of sale.
                    // Assuming product.costPrice is the current COGS, which might not be accurate for historical sales.
                    // For a more accurate profit, we would need to store the COGS at the time of sale in SaleItem.
                    // For now, we'll use the product's current costPrice as an approximation.
                    if let product = saleItem.product {
                        totalCostOfSoldGoods += (Double(saleItem.quantity) * product.costPrice)
                    }
                }
            }
        }
        return totalRevenue - totalCostOfSoldGoods
    }

    private var totalQuantitySoldForSelectedDate: Int {
        salesTransactions.filter { Calendar.current.isDate($0.date ?? Date(), inSameDayAs: selectedDate) }
            .reduce(0) { total, transaction in
                transaction.saleItems?.reduce(total) { itemTotal, item in
                    if let saleItem = item as? SaleItem {
                        return itemTotal + Int(saleItem.quantity)
                    }
                    return itemTotal
                } ?? total
            }
    }

    private var dateFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter
    }
}

#Preview {
    HomeTab()
        .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
}
