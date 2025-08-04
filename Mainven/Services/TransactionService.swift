import Foundation
import CoreData

class TransactionService {
    private var viewContext: NSManagedObjectContext

    init(context: NSManagedObjectContext) {
        self.viewContext = context
    }

    // MARK: - Purchase Transactions

    func savePurchaseTransaction(
        transactionID: NSManagedObjectID?,
        supplier: Supplier,
        date: Date,
        note: String,
        items: [PurchaseItemData]
    ) {
        let transactionToSave: TransactionPurchase
        if let id = transactionID, let existingTransaction = viewContext.object(with: id) as? TransactionPurchase {
            transactionToSave = existingTransaction
            revertOldStockChanges(for: existingTransaction)
        } else {
            transactionToSave = TransactionPurchase(context: viewContext)
            transactionToSave.transactionID = UUID()
        }

        transactionToSave.date = date
        transactionToSave.note = note
        transactionToSave.supplier = supplier

        clearExistingPurchaseItems(for: transactionToSave)
        addNewPurchaseItems(items, to: transactionToSave)

        saveContext()
    }

    private func revertOldStockChanges(for transaction: TransactionPurchase) {
        if let oldPurchaseItems = transaction.purchaseItems as? Set<PurchaseItem> {
            for oldPurchaseItem in oldPurchaseItems {
                if let product = oldPurchaseItem.product {
                    let currentProductTotalValue = product.costPrice * Double(product.stockQuantity)
                    let oldPurchaseItemTotalValue = oldPurchaseItem.costPrice * Double(oldPurchaseItem.quantity)
                    let quantityBeforeOldPurchaseItem = product.stockQuantity - oldPurchaseItem.quantity

                    if quantityBeforeOldPurchaseItem == 0 {
                        product.costPrice = 0.0
                    } else {
                        product.costPrice = (currentProductTotalValue - oldPurchaseItemTotalValue) / Double(quantityBeforeOldPurchaseItem)
                    }
                    product.stockQuantity -= oldPurchaseItem.quantity
                    product.stockValue = product.costPrice * Double(product.stockQuantity)
                }
            }
        }
    }

    private func clearExistingPurchaseItems(for transaction: TransactionPurchase) {
        if let existingPurchaseItems = transaction.purchaseItems as? Set<PurchaseItem> {
            for item in existingPurchaseItems {
                viewContext.delete(item)
            }
        }
    }

    private func addNewPurchaseItems(_ items: [PurchaseItemData], to transaction: TransactionPurchase) {
        for itemData in items {
            guard let product = itemData.product else { continue }

            updateProductCost(for: product, with: itemData)

            let newPurchaseItem = PurchaseItem(context: viewContext)
            newPurchaseItem.purchaseItemID = UUID()
            newPurchaseItem.quantity = Int64(itemData.quantity)
            newPurchaseItem.costPrice = itemData.costPrice
            newPurchaseItem.minimumSalePrice = itemData.minimumSalePrice
            newPurchaseItem.product = product
            newPurchaseItem.transactionPurchase = transaction
        }
    }

    private func updateProductCost(for product: Product, with itemData: PurchaseItemData) {
        let oldQuantity = product.stockQuantity
        let oldCostPrice = product.costPrice
        let newQuantity = Int64(itemData.quantity)
        let newCostPrice = itemData.costPrice

        if oldQuantity == 0 {
            product.costPrice = newCostPrice
        } else {
            product.costPrice = ((Double(oldQuantity) * oldCostPrice) + (Double(newQuantity) * newCostPrice)) / (Double(oldQuantity) + Double(newQuantity))
        }

        product.stockQuantity += newQuantity
        product.stockValue = product.costPrice * Double(product.stockQuantity)
    }

    // MARK: - Sales Transactions

    func saveSalesTransaction(
        transactionID: NSManagedObjectID?,
        customer: Customer,
        date: Date,
        note: String,
        items: [SaleItemData]
    ) {
        let transactionToSave: TransactionSale
        if let id = transactionID, let existingTransaction = viewContext.object(with: id) as? TransactionSale {
            transactionToSave = existingTransaction
            revertOldStockChanges(for: existingTransaction)
        } else {
            transactionToSave = TransactionSale(context: viewContext)
            transactionToSave.transactionID = UUID()
        }

        transactionToSave.date = date
        transactionToSave.note = note
        transactionToSave.customer = customer

        clearExistingSaleItems(for: transactionToSave)
        addNewSaleItems(items, to: transactionToSave)

        saveContext()
    }

    private func revertOldStockChanges(for transaction: TransactionSale) {
        if let oldSaleItems = transaction.saleItems as? Set<SaleItem> {
            for oldSaleItem in oldSaleItems {
                if let product = oldSaleItem.product {
                    product.stockQuantity += oldSaleItem.quantity
                    product.stockValue = product.costPrice * Double(product.stockQuantity)
                }
            }
        }
    }

    private func clearExistingSaleItems(for transaction: TransactionSale) {
        if let existingSaleItems = transaction.saleItems as? Set<SaleItem> {
            for item in existingSaleItems {
                viewContext.delete(item)
            }
        }
    }

    private func addNewSaleItems(_ items: [SaleItemData], to transaction: TransactionSale) {
        for itemData in items {
            guard let product = itemData.product else { continue }

            product.stockQuantity -= Int64(itemData.quantity)
            product.stockValue = product.costPrice * Double(product.stockQuantity)

            let newSaleItem = SaleItem(context: viewContext)
            newSaleItem.saleItemID = UUID()
            newSaleItem.quantity = Int64(itemData.quantity)
            newSaleItem.minimumSalePrice = product.minimumSalePrice
            newSaleItem.customSalePrice = itemData.customSalePrice
            newSaleItem.product = product
            newSaleItem.transactionSale = transaction
        }
    }

    // MARK: - Common

    private func saveContext() {
        do {
            try viewContext.save()
        } catch {
            let nsError = error as NSError
            fatalError("Unresolved error \(nsError), \(nsError.userInfo)")
        }
    }
}
