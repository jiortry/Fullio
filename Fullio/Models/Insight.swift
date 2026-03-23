import Foundation

enum InsightType: String, Codable {
    case positive
    case warning
    case neutral
    case suggestion
    case achievement
}

enum InsightCategory: String, Codable {
    case spending
    case saving
    case behavior
    case forecast
    case subscription
    case goal
}

struct Insight: Identifiable {
    let id: UUID
    let type: InsightType
    let category: InsightCategory
    let title: String
    let message: String
    let icon: String
    let date: Date
    let actionLabel: String?
    let relatedAmount: Double?

    init(
        type: InsightType,
        category: InsightCategory,
        title: String,
        message: String,
        icon: String = "lightbulb.fill",
        actionLabel: String? = nil,
        relatedAmount: Double? = nil
    ) {
        self.id = UUID()
        self.type = type
        self.category = category
        self.title = title
        self.message = message
        self.icon = icon
        self.date = .now
        self.actionLabel = actionLabel
        self.relatedAmount = relatedAmount
    }

    static var sampleInsights: [Insight] {
        [
            Insight(type: .positive, category: .saving,
                    title: "Stai migliorando!",
                    message: "Questa settimana hai speso il 15% in meno rispetto alla scorsa.",
                    icon: "arrow.down.forward",
                    relatedAmount: 42),
            Insight(type: .warning, category: .spending,
                    title: "Weekend sopra la media",
                    message: "Sabato e domenica hai speso 89€ — la tua media weekend è 55€.",
                    icon: "exclamationmark.triangle.fill",
                    relatedAmount: 89),
            Insight(type: .suggestion, category: .subscription,
                    title: "Abbonamento da rivedere?",
                    message: "Non usi Spotify da 3 settimane. Risparmieresti 9.99€/mese.",
                    icon: "repeat",
                    actionLabel: "Rivedi abbonamenti",
                    relatedAmount: 9.99),
            Insight(type: .neutral, category: .behavior,
                    title: "Il martedì è il tuo giorno più costoso",
                    message: "Negli ultimi 30 giorni, il martedì spendi in media 28€.",
                    icon: "calendar"),
            Insight(type: .positive, category: .goal,
                    title: "Vacanza estiva: 41% raggiunto",
                    message: "A questo ritmo, raggiungerai l'obiettivo in 4 mesi.",
                    icon: "airplane",
                    relatedAmount: 620),
            Insight(type: .suggestion, category: .saving,
                    title: "Se tagli i caffè fuori...",
                    message: "Spendi ~45€/mese in caffè. Dimezzando, risparmi 270€/anno.",
                    icon: "cup.and.saucer.fill",
                    actionLabel: "Vedi dettaglio",
                    relatedAmount: 270),
            Insight(type: .warning, category: .forecast,
                    title: "Rischio sforamento",
                    message: "Se continui con questo ritmo, potresti sforare il budget di 120€.",
                    icon: "chart.line.downtrend.xyaxis",
                    relatedAmount: 120),
            Insight(type: .achievement, category: .saving,
                    title: "7 giorni sotto budget!",
                    message: "Hai rispettato il limite giornaliero per una settimana intera.",
                    icon: "star.fill"),
        ]
    }
}
