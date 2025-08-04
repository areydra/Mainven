
import SwiftUI
import CoreData

struct HomeTab: View {
    @StateObject private var viewModel: DashboardViewModel

    @State private var selectedDate: Date = Date()
    @State private var selectedMonthForTopSales: Date = Date()
    @State private var showTopSalesModal: Bool = false

    init(context: NSManagedObjectContext) {
        _viewModel = StateObject(wrappedValue: DashboardViewModel(context: context))
    }

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    DatePicker(
                        "Select Date",
                        selection: $selectedDate,
                        displayedComponents: .date
                    )
                    .datePickerStyle(.compact)
                    .padding(.horizontal)
                    .onChange(of: selectedDate) {
                        viewModel.updateDashboard(for: selectedDate)
                    }

                    VStack(alignment: .leading) {
                        Text("Inventory Snapshot")
                            .font(.title2)
                            .padding(.bottom, 5)

                        HStack {
                            Text("Total Products:")
                            Spacer()
                            Text("\(viewModel.totalProducts)")
                        }
                        HStack {
                            Text("Total Stock:")
                            Spacer()
                            Text("\(viewModel.totalStock)")
                        }
                        HStack {
                            Text("Total Stock Value:")
                            Spacer()
                            Text("(\(viewModel.totalStockValue, format: .currency(code: "IDR")))")
                        }
                    }
                    .padding()
                    .background(Color.gray.opacity(0.1))
                    .cornerRadius(10)

                    VStack(alignment: .leading) {
                        Text("Daily Performance (\(selectedDate, formatter: dateFormatter))")
                            .font(.title2)
                            .padding(.bottom, 5)
                        HStack {
                            Text("Total Quantity Sold:")
                            Spacer()
                            Text("\(viewModel.totalQuantitySoldForSelectedDate)")
                        }
                        HStack {
                            Text("Total Revenue:")
                            Spacer()
                            Text("(\(viewModel.totalRevenueForSelectedDate, format: .currency(code: "IDR")))")
                        }
                        HStack {
                            Text("Total Profit:")
                            Spacer()
                            Text("(\(viewModel.totalProfitForSelectedDate, format: .currency(code: "IDR")))")
                        }
                    }
                    .padding()
                    .background(Color.gray.opacity(0.1))
                    .cornerRadius(10)

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
                        .onChange(of: selectedMonthForTopSales) {
                            viewModel.updateTopSales(for: selectedMonthForTopSales)
                        }

                        if viewModel.topSalesProducts.isEmpty {
                            Text("No sales data available for this month.")
                                .foregroundColor(.gray)
                        } else {
                            ForEach(viewModel.topSalesProducts.prefix(10), id: \.product.objectID) { product, quantity in
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
            .onAppear {
                viewModel.fetchData()
            }
            .sheet(isPresented: $showTopSalesModal) {
                TopSalesProductsView(selectedMonth: $selectedMonthForTopSales)
                    .environment(\.managedObjectContext, viewModel.viewContext)
            }
        }
    }

    private var dateFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter
    }
}

#Preview {
    HomeTab(context: PersistenceController.preview.container.viewContext)
}
