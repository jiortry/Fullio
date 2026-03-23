import SwiftUI
import SwiftData

struct ActivityView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Transaction.date, order: .reverse) private var transactions: [Transaction]
    @State private var searchText = ""
    @State private var selectedFilter: ActivityFilter = .all
    @State private var showAddTransaction = false

    enum ActivityFilter: String, CaseIterable {
        case all = "Tutto"
        case expenses = "Uscite"
        case income = "Entrate"
        case recurring = "Ricorrenti"
        case subscriptions = "Abbonamenti"
    }

    private var filteredTransactions: [Transaction] {
        var result = transactions

        switch selectedFilter {
        case .all: break
        case .expenses: result = result.filter { !$0.isIncome }
        case .income: result = result.filter { $0.isIncome }
        case .recurring: result = result.filter { $0.isRecurring }
        case .subscriptions: result = result.filter { $0.isSubscription }
        }

        if !searchText.isEmpty {
            let query = searchText.lowercased()
            result = result.filter {
                $0.title.lowercased().contains(query) ||
                $0.merchant.lowercased().contains(query) ||
                $0.category.rawValue.lowercased().contains(query) ||
                $0.tags.contains { $0.lowercased().contains(query) }
            }
        }

        return result
    }

    private var groupedTransactions: [(key: String, value: [Transaction])] {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "it_IT")
        formatter.dateFormat = "d MMMM yyyy"

        let grouped = Dictionary(grouping: filteredTransactions) { transaction -> String in
            if Calendar.current.isDateInToday(transaction.date) {
                return "Oggi"
            } else if Calendar.current.isDateInYesterday(transaction.date) {
                return "Ieri"
            } else {
                return formatter.string(from: transaction.date)
            }
        }

        return grouped.sorted { first, second in
            let firstDate = first.value.first?.date ?? .distantPast
            let secondDate = second.value.first?.date ?? .distantPast
            return firstDate > secondDate
        }
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                filterBar

                if filteredTransactions.isEmpty {
                    emptyState
                } else {
                    transactionList
                }
            }
            .background(Color.fullioBackground)
            .navigationTitle("Attività")
            .navigationBarTitleDisplayMode(.large)
            .searchable(text: $searchText, prompt: "Cerca transazioni...")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showAddTransaction = true
                    } label: {
                        Image(systemName: "plus.circle.fill")
                            .font(.title3)
                            .foregroundStyle(.fullioDarkGreen)
                    }
                }
            }
            .sheet(isPresented: $showAddTransaction) {
                AddTransactionView()
            }
        }
    }

    // MARK: - Filter Bar

    private var filterBar: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: FullioSpacing.sm) {
                ForEach(ActivityFilter.allCases, id: \.self) { filter in
                    Button {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            selectedFilter = filter
                        }
                    } label: {
                        Text(filter.rawValue)
                            .font(FullioFont.caption())
                            .foregroundStyle(selectedFilter == filter ? .white : .fullioBlack)
                            .padding(.horizontal, FullioSpacing.md)
                            .padding(.vertical, FullioSpacing.sm)
                            .background(selectedFilter == filter ? Color.fullioDarkGreen : Color.fullioCardBackground)
                            .clipShape(Capsule())
                    }
                }
            }
            .padding(.horizontal, FullioSpacing.md)
            .padding(.vertical, FullioSpacing.sm)
        }
    }

    // MARK: - Transaction List

    private var transactionList: some View {
        ScrollView {
            LazyVStack(spacing: FullioSpacing.md) {
                ForEach(groupedTransactions, id: \.key) { section in
                    VStack(alignment: .leading, spacing: FullioSpacing.sm) {
                        HStack {
                            Text(section.key)
                                .font(FullioFont.caption())
                                .foregroundStyle(.fullioSecondaryText)

                            Spacer()

                            let dayTotal = section.value.filter { !$0.isIncome }
                                .reduce(0) { $0 + $1.amount }
                            Text("-\(String(format: "%.0f", dayTotal))€")
                                .font(FullioFont.caption())
                                .foregroundStyle(.fullioSecondaryText)
                        }

                        VStack(spacing: 0) {
                            ForEach(section.value, id: \.id) { transaction in
                                TransactionRow(transaction: transaction)
                                    .swipeActions(edge: .trailing) {
                                        Button(role: .destructive) {
                                            deleteTransaction(transaction)
                                        } label: {
                                            Label("Elimina", systemImage: "trash")
                                        }
                                    }

                                if transaction.id != section.value.last?.id {
                                    Divider()
                                        .padding(.leading, 60)
                                }
                            }
                        }
                        .fullioCard(padding: FullioSpacing.md)
                    }
                }
            }
            .padding(.horizontal, FullioSpacing.md)
            .padding(.bottom, 100)
        }
    }

    // MARK: - Empty State

    private var emptyState: some View {
        VStack(spacing: FullioSpacing.lg) {
            Spacer()

            Image(systemName: "tray")
                .font(.system(size: 48))
                .foregroundStyle(.fullioNeutral)

            Text("Nessuna transazione")
                .font(FullioFont.headline())
                .foregroundStyle(.fullioBlack)

            Text("Aggiungi la tua prima spesa per iniziare")
                .font(FullioFont.body(14))
                .foregroundStyle(.fullioSecondaryText)
                .multilineTextAlignment(.center)

            Button {
                showAddTransaction = true
            } label: {
                Text("Aggiungi transazione")
                    .font(FullioFont.body().weight(.semibold))
                    .foregroundStyle(.white)
                    .padding(.horizontal, FullioSpacing.xl)
                    .padding(.vertical, FullioSpacing.md)
                    .background(Color.fullioDarkGreen)
                    .clipShape(Capsule())
            }

            Spacer()
        }
        .padding()
    }

    private func deleteTransaction(_ transaction: Transaction) {
        modelContext.delete(transaction)
    }
}

#Preview {
    ActivityView()
        .modelContainer(for: Transaction.self, inMemory: true)
}
