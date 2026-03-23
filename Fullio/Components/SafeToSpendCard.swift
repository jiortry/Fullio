import SwiftUI

struct SafeToSpendCard: View {
    let amount: Double
    let dailyBudget: Double
    let message: String

    private var ratio: Double {
        amount / max(dailyBudget, 1)
    }

    private var accentColor: Color {
        if ratio >= 0.7 { return .fullioSoftGreen }
        if ratio >= 0.4 { return .orange }
        return .fullioWarning
    }

    var body: some View {
        VStack(spacing: FullioSpacing.md) {
            Text("Oggi puoi spendere")
                .font(FullioFont.caption())
                .foregroundStyle(.fullioSecondaryText)

            HStack(alignment: .firstTextBaseline, spacing: 4) {
                Text("\(Int(amount))")
                    .font(FullioFont.number(52))
                    .foregroundStyle(.fullioBlack)
                    .contentTransition(.numericText())

                Text("€")
                    .font(FullioFont.number(28))
                    .foregroundStyle(.fullioSecondaryText)
            }

            ProgressView(value: min(ratio, 1.0))
                .tint(accentColor)
                .scaleEffect(y: 2)
                .clipShape(Capsule())

            Text(message)
                .font(FullioFont.body(14))
                .foregroundStyle(.fullioSecondaryText)
                .multilineTextAlignment(.center)
        }
        .fullioCard()
    }
}

#Preview {
    SafeToSpendCard(
        amount: 21,
        dailyBudget: 30,
        message: "Oggi sei in ottima forma! Puoi stare tranquillo."
    )
    .padding()
    .background(Color.fullioBackground)
}
