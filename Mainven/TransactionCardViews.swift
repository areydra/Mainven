import SwiftUI

struct PurchaseTransactionCardView: View {
    @ObservedObject var transaction: TransactionPurchase

    var body: some View {
        VStack(alignment: .leading) {
            Text("Supplier: \(transaction.supplier?.name ?? "Unknown")")
                .font(.headline)
            Text("Date: \(transaction.date ?? Date(), formatter: itemFormatter)")
                .font(.subheadline)
            Text("Total Value: \(totalPurchaseValue, format: .currency(code: "IDR"))")
                .font(.subheadline)
        }
    }

    private var itemFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.timeStyle = .short
        return formatter
    }

    private var totalPurchaseValue: Double {
        transaction.purchaseItems?.reduce(0.0) { (result, item) in
            if let purchaseItem = item as? PurchaseItem {
                return result + (Double(purchaseItem.quantity) * purchaseItem.costPrice)
            }
            return result
        } ?? 0.0
    }
}

struct SalesTransactionCardView: View {
    @ObservedObject var transaction: TransactionSale

    var body: some View {
        VStack(alignment: .leading) {
            Text("Customer: \(transaction.customer?.name ?? "Unknown")")
                .font(.headline)
            Text("Date: \(transaction.date ?? Date(), formatter: itemFormatter)")
                .font(.subheadline)
            Text("Total Value: \(totalSalesValue, format: .currency(code: "IDR"))")
                .font(.subheadline)
            Text("Profit: \(profit, format: .currency(code: "IDR"))")
                .font(.subheadline)
                .foregroundColor(profit >= 0 ? .green : .red)
        }
    }

    private var itemFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.timeStyle = .short
        return formatter
    }

    private var totalSalesValue: Double {
        transaction.saleItems?.reduce(0.0) { (result, item) in
            if let saleItem = item as? SaleItem {
                return result + (Double(saleItem.quantity) * (saleItem.customSalePrice ?? saleItem.minimumSalePrice))
            }
            return result
        } ?? 0.0
    }

    private var profit: Double {
        transaction.saleItems?.reduce(0.0) { (result, item) in
            if let saleItem = item as? SaleItem, let product = saleItem.product {
                return result + (saleItem.customSalePrice * Double(saleItem.quantity)) - (product.costPrice * Double(saleItem.quantity))
            }
            return result
        } ?? 0.0
    }
}
