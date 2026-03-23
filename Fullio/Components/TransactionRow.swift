import SwiftUI

struct TransactionRow: View {
    let transaction: Transaction

    var body: some View {
        HStack(spacing: FullioSpacing.md) {
            Circle()
                .fill(transaction.isIncome ? Color.fullioLightGreen : Color.fullioLightBeige)
                .frame(width: 44, height: 44)
                .overlay {
                    Image(systemName: transaction.category.icon)
                        .font(.body)
                        .foregroundStyle(transaction.isIncome ? .fullioSoftGreen : .fullioDarkGreen)
                }

            VStack(alignment: .leading, spacing: 2) {
                Text(transaction.title)
                    .font(FullioFont.body(15).weight(.medium))
                    .foregroundStyle(.fullioBlack)
                    .lineLimit(1)

                HStack(spacing: 4) {
                    if !transaction.merchant.isEmpty {
                        Text(transaction.merchant)
                            .font(FullioFont.caption(12))
                            .foregroundStyle(.fullioSecondaryText)
                    }

                    if transaction.isRecurring {
                        Image(systemName: "repeat")
                            .font(.system(size: 9))
                            .foregroundStyle(.fullioNeutral)
                    }

                    if transaction.isPending {
                        Text("In attesa")
                            .font(FullioFont.caption(10))
                            .foregroundStyle(.orange)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(.orange.opacity(0.1))
                            .clipShape(Capsule())
                    }
                }
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 2) {
                Text(transaction.formattedAmount)
                    .font(FullioFont.smallNumber(15))
                    .foregroundStyle(transaction.isIncome ? .fullioSoftGreen : .fullioBlack)

                Text(transaction.formattedDate)
                    .font(FullioFont.caption(11))
                    .foregroundStyle(.fullioSecondaryText)
            }
        }
        .padding(.vertical, FullioSpacing.xs)
    }
}

#Preview {
    VStack {
        ForEach(Transaction.sampleTransactions.prefix(5), id: \.id) { t in
            TransactionRow(transaction: t)
            Divider()
        }
    }
    .padding()
}
