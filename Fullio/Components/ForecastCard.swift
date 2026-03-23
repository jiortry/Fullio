import SwiftUI

struct ForecastCard: View {
    let projectedSavings: Double
    let budgetRisk: FinanceManager.BudgetRisk

    var body: some View {
        HStack(spacing: FullioSpacing.md) {
            VStack(alignment: .leading, spacing: FullioSpacing.xs) {
                Label(budgetRisk.rawValue, systemImage: budgetRisk.icon)
                    .font(FullioFont.caption())
                    .foregroundStyle(budgetRisk.color)

                if projectedSavings >= 0 {
                    Text("A fine mese risparmi")
                        .font(FullioFont.body(13))
                        .foregroundStyle(.fullioSecondaryText)

                    Text("\(Int(projectedSavings))€")
                        .font(FullioFont.headline())
                        .foregroundStyle(.fullioDarkGreen)
                } else {
                    Text("Rischio a fine mese")
                        .font(FullioFont.body(13))
                        .foregroundStyle(.fullioSecondaryText)

                    Text("-\(Int(abs(projectedSavings)))€")
                        .font(FullioFont.headline())
                        .foregroundStyle(.fullioWarning)
                }
            }

            Spacer()

            Circle()
                .fill(budgetRisk.color.opacity(0.15))
                .frame(width: 56, height: 56)
                .overlay {
                    Image(systemName: budgetRisk.icon)
                        .font(.title2)
                        .foregroundStyle(budgetRisk.color)
                }
        }
        .fullioCard()
    }
}

#Preview {
    VStack {
        ForecastCard(projectedSavings: 180, budgetRisk: .safe)
        ForecastCard(projectedSavings: -120, budgetRisk: .danger)
    }
    .padding()
    .background(Color.fullioBackground)
}
