import SwiftUI

struct QuickStatCard: View {
    let title: String
    let value: String
    let icon: String
    var color: Color = .fullioDarkGreen
    var subtitle: String? = nil

    var body: some View {
        VStack(alignment: .leading, spacing: FullioSpacing.sm) {
            HStack {
                Image(systemName: icon)
                    .font(.caption)
                    .foregroundStyle(color)

                Text(title)
                    .font(FullioFont.caption(11))
                    .foregroundStyle(.fullioSecondaryText)
            }

            Text(value)
                .font(FullioFont.headline(18))
                .foregroundStyle(.fullioBlack)
                .contentTransition(.numericText())

            if let subtitle {
                Text(subtitle)
                    .font(FullioFont.body(11))
                    .foregroundStyle(.fullioSecondaryText)
                    .lineLimit(1)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .fullioCard(padding: FullioSpacing.md)
    }
}

struct QuickStatRow: View {
    let stats: [(title: String, value: String, icon: String, color: Color)]

    var body: some View {
        HStack(spacing: FullioSpacing.sm) {
            ForEach(Array(stats.enumerated()), id: \.offset) { _, stat in
                QuickStatCard(
                    title: stat.title,
                    value: stat.value,
                    icon: stat.icon,
                    color: stat.color
                )
            }
        }
    }
}

#Preview {
    QuickStatRow(stats: [
        (title: "Oggi", value: "3.80€", icon: "clock", color: .fullioSoftGreen),
        (title: "Settimana", value: "142€", icon: "calendar", color: .fullioDarkGreen),
    ])
    .padding()
    .background(Color.fullioBackground)
}
