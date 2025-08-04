
import Foundation
import CoreData
import Combine

class DashboardViewModel: ObservableObject {
    private var viewContext: NSManagedObjectContext

    @Published var totalProducts: Int = 0
    @Published var totalStock: Int = 0
    @Published var totalStockValue: Double = 0.0

    @Published var totalQuantitySoldForSelectedDate: Int = 0
    @Published var totalRevenueForSelectedDate: Double = 0.0
    @Published var totalProfitForSelectedDate: Double = 0.0

    @Published var topSalesProducts: [(product: Product, quantity: Int)] = []

    private var products: [Product] = []
    private var salesTransactions: [TransactionSale] = []

    init(context: NSManagedObjectContext) {
        self.viewContext = context
    }

    func fetchData() {
        do {
            let productRequest: NSFetchRequest<Product> = Product.fetchRequest()
            products = try viewContext.fetch(productRequest)

            let salesRequest: NSFetchRequest<TransactionSale> = TransactionSale.fetchRequest()
            salesRequest.sortDescriptors = [NSSortDescriptor(keyPath: \TransactionSale.date, ascending: false)]
            salesTransactions = try viewContext.fetch(salesRequest)
            
            updateDashboard(for: Date())
            updateTopSales(for: Date())
        } catch {
            // Handle error
            print("Failed to fetch data: \(error)")
        }
    }

    func updateDashboard(for date: Date) {
        // Calculate inventory snapshot
        totalProducts = products.count
        totalStock = products.reduce(0) { $0 + Int($1.stockQuantity) }
        totalStockValue = products.reduce(0.0) { $0 + $1.stockValue }

        // Calculate daily performance
        let dailySales = salesTransactions.filter { Calendar.current.isDate($0.date ?? Date(), inSameDayAs: date) }
        totalQuantitySoldForSelectedDate = dailySales.reduce(0) { total, transaction in
            transaction.saleItems?.reduce(total) { itemTotal, item in
                if let saleItem = item as? SaleItem {
                    return itemTotal + Int(saleItem.quantity)
                }
                return itemTotal
            } ?? total
        }

        var totalRevenue: Double = 0.0
        var totalCostOfSoldGoods: Double = 0.0

        for saleTransaction in dailySales {
            if let saleItems = saleTransaction.saleItems as? Set<SaleItem> {
                for saleItem in saleItems {
                    totalRevenue += (Double(saleItem.quantity) * (saleItem.customSalePrice ?? saleItem.minimumSalePrice))
                    if let product = saleItem.product {
                        totalCostOfSoldGoods += (Double(saleItem.quantity) * product.costPrice)
                    }
                }
            }
        }
        totalRevenueForSelectedDate = totalRevenue
        totalProfitForSelectedDate = totalRevenue - totalCostOfSoldGoods
    }

    func updateTopSales(for month: Date) {
        var productSales: [Product: Int] = [:]

        let calendar = Calendar.current
        let filteredSalesTransactions = salesTransactions.filter { transaction in
            guard let transactionDate = transaction.date else { return false }
            return calendar.isDate(transactionDate, equalTo: month, toGranularity: .month)
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

        topSalesProducts = productSales.sorted { $0.value > $1.value }.map { (product: $0.key, quantity: $0.value) }
    }
}
