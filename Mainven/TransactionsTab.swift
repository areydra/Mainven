import SwiftUI

struct TransactionsTab: View {
    @State private var selectedTab: TransactionType = .purchases

    enum TransactionType: String, CaseIterable, Identifiable {
        case purchases = "Purchases"
        case sales = "Sales"

        var id: String { self.rawValue }
    }

    var body: some View {
        NavigationView {
            VStack {
                Picker("Select Transaction Type", selection: $selectedTab) {
                    ForEach(TransactionType.allCases) { type in
                        Text(type.rawValue).tag(type)
                    }
                }
                .pickerStyle(.segmented)
                .padding(.horizontal)

                if selectedTab == .purchases {
                    PurchaseTransactionView()
                } else {
                    SalesTransactionView()
                }
                Spacer()
            }
            .navigationTitle("Transactions")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}

#Preview {
    TransactionsTab()
}