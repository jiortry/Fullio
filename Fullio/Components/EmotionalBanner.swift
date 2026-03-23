import SwiftUI

struct EmotionalBanner: View {
    let message: String
    var type: BannerType = .neutral

    enum BannerType {
        case positive, warning, neutral

        var backgroundColor: Color {
            switch self {
            case .positive: return .fullioLightGreen
            case .warning: return .fullioLightWarning
            case .neutral: return .fullioLightBeige
            }
        }

        var icon: String {
            switch self {
            case .positive: return "sparkles"
            case .warning: return "exclamationmark.circle"
            case .neutral: return "info.circle"
            }
        }

        var iconColor: Color {
            switch self {
            case .positive: return .fullioSoftGreen
            case .warning: return .fullioWarning
            case .neutral: return .fullioNeutral
            }
        }
    }

    var body: some View {
        HStack(spacing: FullioSpacing.sm) {
            Image(systemName: type.icon)
                .font(.body)
                .foregroundStyle(type.iconColor)

            Text(message)
                .font(FullioFont.body(14))
                .foregroundStyle(.fullioBlack)

            Spacer()
        }
        .padding(FullioSpacing.md)
        .background(type.backgroundColor)
        .clipShape(RoundedRectangle(cornerRadius: FullioRadius.md))
    }
}

#Preview {
    VStack(spacing: 12) {
        EmotionalBanner(message: "Oggi sei in ottima forma!", type: .positive)
        EmotionalBanner(message: "Attenzione: weekend sopra la media", type: .warning)
        EmotionalBanner(message: "Sei costante, continua così", type: .neutral)
    }
    .padding()
    .background(Color.fullioBackground)
}
