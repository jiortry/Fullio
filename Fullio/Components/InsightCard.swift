import SwiftUI

struct InsightCard: View {
    let insight: Insight

    private var accentColor: Color {
        switch insight.type {
        case .positive, .achievement: return .fullioSoftGreen
        case .warning: return .fullioWarning
        case .neutral: return .fullioNeutral
        case .suggestion: return .fullioDarkGreen
        }
    }

    private var backgroundColor: Color {
        switch insight.type {
        case .positive, .achievement: return .fullioLightGreen
        case .warning: return .fullioLightWarning
        case .neutral: return .fullioLightBeige
        case .suggestion: return .fullioLightGreen
        }
    }

    var body: some View {
        HStack(alignment: .top, spacing: FullioSpacing.md) {
            Circle()
                .fill(backgroundColor)
                .frame(width: 44, height: 44)
                .overlay {
                    Image(systemName: insight.icon)
                        .font(.body.weight(.semibold))
                        .foregroundStyle(accentColor)
                }

            VStack(alignment: .leading, spacing: FullioSpacing.xs) {
                Text(insight.title)
                    .font(FullioFont.body(15).weight(.semibold))
                    .foregroundStyle(.fullioBlack)

                Text(insight.message)
                    .font(FullioFont.body(13))
                    .foregroundStyle(.fullioSecondaryText)
                    .lineLimit(3)

                if let actionLabel = insight.actionLabel {
                    Text(actionLabel)
                        .font(FullioFont.caption())
                        .foregroundStyle(.fullioDarkGreen)
                        .padding(.top, 2)
                }
            }

            Spacer(minLength: 0)

            if let amount = insight.relatedAmount {
                Text("\(Int(amount))€")
                    .font(FullioFont.smallNumber(16))
                    .foregroundStyle(accentColor)
            }
        }
        .fullioCard(padding: FullioSpacing.md)
    }
}

#Preview {
    VStack {
        ForEach(Insight.sampleInsights.prefix(3)) { insight in
            InsightCard(insight: insight)
        }
    }
    .padding()
    .background(Color.fullioBackground)
}
