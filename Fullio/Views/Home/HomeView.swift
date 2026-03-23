import SwiftUI
import SwiftData

struct HomeView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Transaction.date, order: .reverse) private var transactions: [Transaction]
    @Query private var profiles: [UserProfile]
    @Query private var goals: [SavingsGoal]

    @State private var financeManager = FinanceManager()
    @State private var insightEngine = InsightEngine()
    @State private var showAddTransaction = false

    private var profile: UserProfile? { profiles.first }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: FullioSpacing.lg) {
                    greetingSection

                    safeToSpendSection

                    quickStatsSection

                    forecastSection

                    if !topInsights.isEmpty {
                        insightsPreviewSection
                    }

                    if !recentTransactions.isEmpty {
                        recentTransactionsSection
                    }

                    if let topGoal = goals.first(where: { $0.isActive }) {
                        goalPreviewSection(topGoal)
                    }

                    Spacer(minLength: 100)
                }
                .padding(.horizontal, FullioSpacing.md)
                .padding(.top, FullioSpacing.sm)
            }
            .background(Color.fullioBackground)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Text("Fullio")
                        .font(FullioFont.title(24))
                        .foregroundStyle(.fullioDarkGreen)
                }
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
            .onAppear { refreshData() }
            .onChange(of: transactions.count) { refreshData() }
        }
    }

    // MARK: - Greeting

    private var greetingSection: some View {
        VStack(alignment: .leading, spacing: FullioSpacing.xs) {
            if let name = profile?.name, !name.isEmpty {
                Text("Ciao \(name)!")
                    .font(FullioFont.headline())
                    .foregroundStyle(.fullioBlack)
            }

            EmotionalBanner(
                message: emotionalMessage,
                type: emotionalBannerType
            )
        }
    }

    // MARK: - Safe-to-Spend

    private var safeToSpendSection: some View {
        SafeToSpendCard(
            amount: financeManager.safeToSpend,
            dailyBudget: profile?.dailyBudget ?? 30,
            message: EmotionalMessages.safeToSpendMessage(
                amount: financeManager.safeToSpend,
                dailyBudget: profile?.dailyBudget ?? 30
            )
        )
    }

    // MARK: - Quick Stats

    private var quickStatsSection: some View {
        QuickStatRow(stats: [
            (title: "Oggi", value: "\(String(format: "%.0f", financeManager.todaySpent))€",
             icon: "clock", color: .fullioSoftGreen),
            (title: "Settimana", value: "\(String(format: "%.0f", financeManager.thisWeekSpent))€",
             icon: "calendar", color: .fullioDarkGreen),
        ])
    }

    // MARK: - Forecast

    private var forecastSection: some View {
        ForecastCard(
            projectedSavings: financeManager.projectedSavings,
            budgetRisk: financeManager.budgetRisk
        )
    }

    // MARK: - Insights Preview

    private var topInsights: [Insight] {
        Array(insightEngine.insights.prefix(2))
    }

    private var insightsPreviewSection: some View {
        VStack(alignment: .leading, spacing: FullioSpacing.sm) {
            Text("Per te")
                .font(FullioFont.headline(16))
                .foregroundStyle(.fullioBlack)

            ForEach(topInsights) { insight in
                InsightCard(insight: insight)
            }
        }
    }

    // MARK: - Recent Transactions

    private var recentTransactions: [Transaction] {
        Array(transactions.prefix(3))
    }

    private var recentTransactionsSection: some View {
        VStack(alignment: .leading, spacing: FullioSpacing.sm) {
            HStack {
                Text("Ultime spese")
                    .font(FullioFont.headline(16))
                    .foregroundStyle(.fullioBlack)
                Spacer()
                NavigationLink("Vedi tutto", value: "activity")
                    .font(FullioFont.caption())
                    .foregroundStyle(.fullioDarkGreen)
            }

            VStack(spacing: 0) {
                ForEach(recentTransactions, id: \.id) { transaction in
                    TransactionRow(transaction: transaction)
                    if transaction.id != recentTransactions.last?.id {
                        Divider()
                            .padding(.leading, 60)
                    }
                }
            }
            .fullioCard(padding: FullioSpacing.md)
        }
    }

    // MARK: - Goal Preview

    private func goalPreviewSection(_ goal: SavingsGoal) -> some View {
        VStack(alignment: .leading, spacing: FullioSpacing.sm) {
            Text("Il tuo obiettivo")
                .font(FullioFont.headline(16))
                .foregroundStyle(.fullioBlack)

            GoalProgressCard(goal: goal)
        }
    }

    // MARK: - Helpers

    private var emotionalMessage: String {
        if financeManager.budgetRisk == .danger {
            return "Giornata impegnativa — ma sei ancora in controllo"
        }
        if financeManager.weeklyTrend < -10 {
            return "Stai migliorando questa settimana!"
        }
        if financeManager.weeklyTrend > 20 {
            return "Settimana un po' intensa — rallenta un attimo"
        }
        return EmotionalMessages.randomGreeting
    }

    private var emotionalBannerType: EmotionalBanner.BannerType {
        if financeManager.budgetRisk == .danger { return .warning }
        if financeManager.weeklyTrend < -10 { return .positive }
        if financeManager.weeklyTrend > 20 { return .warning }
        return .neutral
    }

    private func refreshData() {
        financeManager.refresh(transactions: transactions, profile: profile)
        insightEngine.generateInsights(transactions: transactions, profile: profile)
    }
}

#Preview {
    HomeView()
        .modelContainer(for: [Transaction.self, UserProfile.self, SavingsGoal.self], inMemory: true)
}
