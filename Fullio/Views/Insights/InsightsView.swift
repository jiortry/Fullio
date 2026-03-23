import SwiftUI
import SwiftData

struct InsightsView: View {
    @Query(sort: \Transaction.date, order: .reverse) private var transactions: [Transaction]
    @Query private var profiles: [UserProfile]

    @State private var insightEngine = InsightEngine()
    @State private var financeManager = FinanceManager()
    @State private var selectedTab: InsightTab = .forYou

    private var profile: UserProfile? { profiles.first }

    enum InsightTab: String, CaseIterable {
        case forYou = "Per te"
        case behavior = "Comportamento"
        case savings = "Risparmio"
        case forecast = "Previsioni"
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                tabBar

                ScrollView {
                    VStack(spacing: FullioSpacing.lg) {
                        switch selectedTab {
                        case .forYou:
                            forYouSection
                        case .behavior:
                            behaviorSection
                        case .savings:
                            savingsSection
                        case .forecast:
                            forecastSection
                        }

                        Spacer(minLength: 100)
                    }
                    .padding(.horizontal, FullioSpacing.md)
                    .padding(.top, FullioSpacing.md)
                }
            }
            .background(Color.fullioBackground)
            .navigationTitle("Insight")
            .navigationBarTitleDisplayMode(.large)
            .onAppear { refreshData() }
            .onChange(of: transactions.count) { refreshData() }
        }
    }

    // MARK: - Tab Bar

    private var tabBar: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: FullioSpacing.sm) {
                ForEach(InsightTab.allCases, id: \.self) { tab in
                    Button {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            selectedTab = tab
                        }
                    } label: {
                        Text(tab.rawValue)
                            .font(FullioFont.caption())
                            .foregroundStyle(selectedTab == tab ? .white : .fullioBlack)
                            .padding(.horizontal, FullioSpacing.md)
                            .padding(.vertical, FullioSpacing.sm)
                            .background(selectedTab == tab ? Color.fullioDarkGreen : Color.fullioCardBackground)
                            .clipShape(Capsule())
                    }
                }
            }
            .padding(.horizontal, FullioSpacing.md)
            .padding(.vertical, FullioSpacing.sm)
        }
    }

    // MARK: - For You

    private var forYouSection: some View {
        VStack(spacing: FullioSpacing.md) {
            if insightEngine.insights.isEmpty {
                emptyInsightsState
            } else {
                ForEach(insightEngine.insights) { insight in
                    InsightCard(insight: insight)
                }
            }
        }
    }

    // MARK: - Behavior

    private var behaviorSection: some View {
        VStack(spacing: FullioSpacing.lg) {
            spenderProfileCard

            if !insightEngine.weeklyPattern.isEmpty {
                weeklyPatternCard
            }

            if insightEngine.improvementScore != 0 {
                improvementCard
            }

            let behaviorInsights = insightEngine.insights.filter {
                $0.category == .behavior
            }
            ForEach(behaviorInsights) { insight in
                InsightCard(insight: insight)
            }
        }
    }

    // MARK: - Savings

    private var savingsSection: some View {
        VStack(spacing: FullioSpacing.lg) {
            savingsPotentialCard

            dailySavingsCard

            simulationCard

            let savingsInsights = insightEngine.insights.filter {
                $0.category == .saving || $0.category == .subscription
            }
            ForEach(savingsInsights) { insight in
                InsightCard(insight: insight)
            }
        }
    }

    // MARK: - Forecast

    private var forecastSection: some View {
        VStack(spacing: FullioSpacing.lg) {
            monthEndCard

            if financeManager.spendingAcceleration != 0 {
                accelerationCard
            }

            if let dub = financeManager.daysUntilBroke {
                daysUntilBrokeCard(dub)
            }

            let forecastInsights = insightEngine.insights.filter {
                $0.category == .forecast
            }
            ForEach(forecastInsights) { insight in
                InsightCard(insight: insight)
            }
        }
    }

    // MARK: - Behavior Cards

    private var spenderProfileCard: some View {
        HStack(spacing: FullioSpacing.md) {
            Circle()
                .fill(Color.fullioLightGreen)
                .frame(width: 56, height: 56)
                .overlay {
                    Image(systemName: insightEngine.spenderProfile.icon)
                        .font(.title2)
                        .foregroundStyle(.fullioDarkGreen)
                }

            VStack(alignment: .leading, spacing: FullioSpacing.xs) {
                Text("Il tuo profilo")
                    .font(FullioFont.caption())
                    .foregroundStyle(.fullioSecondaryText)

                Text(insightEngine.spenderProfile.rawValue)
                    .font(FullioFont.headline())
                    .foregroundStyle(.fullioBlack)

                Text(insightEngine.spenderProfile.description)
                    .font(FullioFont.body(13))
                    .foregroundStyle(.fullioSecondaryText)
            }

            Spacer()
        }
        .fullioCard()
    }

    private var weeklyPatternCard: some View {
        VStack(alignment: .leading, spacing: FullioSpacing.md) {
            Text("Pattern settimanale")
                .font(FullioFont.headline(16))
                .foregroundStyle(.fullioBlack)

            let sortedDays = ["Lun", "Mar", "Mer", "Gio", "Ven", "Sab", "Dom"]
            let maxValue = insightEngine.weeklyPattern.values.max() ?? 1

            HStack(alignment: .bottom, spacing: FullioSpacing.sm) {
                ForEach(sortedDays, id: \.self) { day in
                    let value = insightEngine.weeklyPattern[day] ?? 0
                    let height = maxValue > 0 ? (value / maxValue) * 80 : 0

                    VStack(spacing: 4) {
                        Text("\(Int(value))€")
                            .font(FullioFont.caption(9))
                            .foregroundStyle(.fullioSecondaryText)

                        RoundedRectangle(cornerRadius: 4)
                            .fill(Color.fullioSoftGreen.opacity(0.3 + (value / maxValue) * 0.7))
                            .frame(height: max(height, 4))

                        Text(day)
                            .font(FullioFont.caption(10))
                            .foregroundStyle(.fullioSecondaryText)
                    }
                    .frame(maxWidth: .infinity)
                }
            }
        }
        .fullioCard()
    }

    private var improvementCard: some View {
        let improving = insightEngine.improvementScore > 0
        return HStack(spacing: FullioSpacing.md) {
            Image(systemName: improving ? "arrow.down.circle.fill" : "arrow.up.circle.fill")
                .font(.title2)
                .foregroundStyle(improving ? .fullioSoftGreen : .fullioWarning)

            VStack(alignment: .leading, spacing: FullioSpacing.xs) {
                Text(improving ? "Stai migliorando!" : "Puoi migliorare")
                    .font(FullioFont.headline(16))
                    .foregroundStyle(.fullioBlack)

                Text(improving
                     ? "Spendi il \(Int(abs(insightEngine.improvementScore)))% in meno del mese scorso"
                     : "Hai speso il \(Int(abs(insightEngine.improvementScore)))% in più del mese scorso"
                )
                .font(FullioFont.body(13))
                .foregroundStyle(.fullioSecondaryText)
            }

            Spacer()
        }
        .fullioCard()
    }

    // MARK: - Savings Cards

    private var savingsPotentialCard: some View {
        VStack(alignment: .leading, spacing: FullioSpacing.md) {
            Text("Risparmio potenziale")
                .font(FullioFont.headline(16))
                .foregroundStyle(.fullioBlack)

            HStack(alignment: .firstTextBaseline, spacing: 4) {
                Text("\(Int(financeManager.savingsPotential))")
                    .font(FullioFont.number(36))
                    .foregroundStyle(.fullioDarkGreen)
                Text("€/mese")
                    .font(FullioFont.body())
                    .foregroundStyle(.fullioSecondaryText)
            }

            Text("Riducendo del 20% le spese non essenziali")
                .font(FullioFont.body(13))
                .foregroundStyle(.fullioSecondaryText)
        }
        .fullioCard()
    }

    private var dailySavingsCard: some View {
        HStack(spacing: FullioSpacing.md) {
            VStack(alignment: .leading, spacing: FullioSpacing.xs) {
                Text("Puoi mettere da parte oggi")
                    .font(FullioFont.caption())
                    .foregroundStyle(.fullioSecondaryText)

                HStack(alignment: .firstTextBaseline, spacing: 4) {
                    Text("\(Int(financeManager.dailySavingsSuggestion))")
                        .font(FullioFont.headline(24))
                        .foregroundStyle(.fullioDarkGreen)
                    Text("€")
                        .font(FullioFont.body())
                        .foregroundStyle(.fullioSecondaryText)
                }
            }

            Spacer()

            Image(systemName: "leaf.fill")
                .font(.title2)
                .foregroundStyle(.fullioSoftGreen)
        }
        .fullioCard()
    }

    private var simulationCard: some View {
        let sim = financeManager.simulateIfContinue(profile: profile ?? UserProfile())
        return VStack(alignment: .leading, spacing: FullioSpacing.md) {
            Text("Se continui così...")
                .font(FullioFont.headline(16))
                .foregroundStyle(.fullioBlack)

            HStack(spacing: FullioSpacing.lg) {
                SimulationPill(label: "3 mesi", amount: sim.savings3m)
                SimulationPill(label: "6 mesi", amount: sim.savings6m)
                SimulationPill(label: "12 mesi", amount: sim.savings12m)
            }
        }
        .fullioCard()
    }

    // MARK: - Forecast Cards

    private var monthEndCard: some View {
        ForecastCard(
            projectedSavings: financeManager.projectedSavings,
            budgetRisk: financeManager.budgetRisk
        )
    }

    private var accelerationCard: some View {
        let accelerating = financeManager.spendingAcceleration > 0
        return EmotionalBanner(
            message: accelerating
                ? "La tua spesa sta accelerando (+\(Int(financeManager.spendingAcceleration))%) — rallenta un po'"
                : "La tua spesa sta rallentando (\(Int(financeManager.spendingAcceleration))%) — ottimo ritmo!",
            type: accelerating ? .warning : .positive
        )
    }

    private func daysUntilBrokeCard(_ days: Int) -> some View {
        HStack(spacing: FullioSpacing.md) {
            VStack(alignment: .leading, spacing: FullioSpacing.xs) {
                Text("Al ritmo attuale")
                    .font(FullioFont.caption())
                    .foregroundStyle(.fullioSecondaryText)

                if days <= 0 {
                    Text("Budget esaurito")
                        .font(FullioFont.headline())
                        .foregroundStyle(.fullioWarning)
                } else {
                    Text("Hai ancora \(days) giorni di budget")
                        .font(FullioFont.headline(16))
                        .foregroundStyle(days < 7 ? .fullioWarning : .fullioBlack)
                }
            }

            Spacer()

            Image(systemName: days <= 5 ? "exclamationmark.triangle.fill" : "clock.fill")
                .font(.title2)
                .foregroundStyle(days <= 5 ? .fullioWarning : .fullioSoftGreen)
        }
        .fullioCard()
    }

    // MARK: - Empty State

    private var emptyInsightsState: some View {
        VStack(spacing: FullioSpacing.md) {
            Image(systemName: "lightbulb")
                .font(.system(size: 40))
                .foregroundStyle(.fullioNeutral)

            Text("Gli insight arriveranno presto")
                .font(FullioFont.headline(16))

            Text("Aggiungi qualche transazione e inizierò ad analizzare i tuoi pattern")
                .font(FullioFont.body(14))
                .foregroundStyle(.fullioSecondaryText)
                .multilineTextAlignment(.center)
        }
        .padding(.vertical, FullioSpacing.xxl)
    }

    // MARK: - Helpers

    private func refreshData() {
        financeManager.refresh(transactions: transactions, profile: profile)
        insightEngine.generateInsights(transactions: transactions, profile: profile)
    }
}

struct SimulationPill: View {
    let label: String
    let amount: Double

    var body: some View {
        VStack(spacing: 4) {
            Text(amount >= 0 ? "+\(Int(amount))€" : "\(Int(amount))€")
                .font(FullioFont.smallNumber(16))
                .foregroundStyle(amount >= 0 ? .fullioDarkGreen : .fullioWarning)
            Text(label)
                .font(FullioFont.caption(11))
                .foregroundStyle(.fullioSecondaryText)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, FullioSpacing.sm)
        .background(Color.fullioLightGreen.opacity(amount >= 0 ? 1 : 0))
        .background(Color.fullioLightWarning.opacity(amount < 0 ? 1 : 0))
        .clipShape(RoundedRectangle(cornerRadius: FullioRadius.sm))
    }
}

#Preview {
    InsightsView()
        .modelContainer(for: [Transaction.self, UserProfile.self], inMemory: true)
}
