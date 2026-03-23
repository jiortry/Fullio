import Foundation
import SwiftData

// MARK: - Transaction Category

enum TransactionCategory: String, Codable, CaseIterable, Identifiable {
    case food = "Cibo"
    case transport = "Trasporti"
    case entertainment = "Svago"
    case shopping = "Shopping"
    case health = "Salute"
    case bills = "Bollette"
    case subscriptions = "Abbonamenti"
    case home = "Casa"
    case education = "Formazione"
    case travel = "Viaggi"
    case transfers = "Trasferimenti"
    case salary = "Stipendio"
    case income = "Entrata"
    case other = "Altro"

    var id: String { rawValue }

    var icon: String {
        switch self {
        case .food: return "fork.knife"
        case .transport: return "car.fill"
        case .entertainment: return "gamecontroller.fill"
        case .shopping: return "bag.fill"
        case .health: return "heart.fill"
        case .bills: return "doc.text.fill"
        case .subscriptions: return "repeat"
        case .home: return "house.fill"
        case .education: return "book.fill"
        case .travel: return "airplane"
        case .transfers: return "arrow.left.arrow.right"
        case .salary: return "banknote.fill"
        case .income: return "plus.circle.fill"
        case .other: return "ellipsis.circle.fill"
        }
    }

    var isExpense: Bool {
        self != .salary && self != .income && self != .transfers
    }
}

// MARK: - Transaction Model

@Model
final class Transaction {
    var id: UUID
    var amount: Double
    var title: String
    var merchant: String
    var categoryRaw: String
    var date: Date
    var isRecurring: Bool
    var isSubscription: Bool
    var tags: [String]
    var note: String?
    var isPending: Bool
    var isIncome: Bool

    var category: TransactionCategory {
        get { TransactionCategory(rawValue: categoryRaw) ?? .other }
        set { categoryRaw = newValue.rawValue }
    }

    init(
        amount: Double,
        title: String,
        merchant: String = "",
        category: TransactionCategory = .other,
        date: Date = .now,
        isRecurring: Bool = false,
        isSubscription: Bool = false,
        tags: [String] = [],
        note: String? = nil,
        isPending: Bool = false,
        isIncome: Bool = false
    ) {
        self.id = UUID()
        self.amount = abs(amount)
        self.title = title
        self.merchant = merchant
        self.categoryRaw = category.rawValue
        self.date = date
        self.isRecurring = isRecurring
        self.isSubscription = isSubscription
        self.tags = tags
        self.note = note
        self.isPending = isPending
        self.isIncome = isIncome
    }

    var signedAmount: Double {
        isIncome ? amount : -amount
    }

    var formattedAmount: String {
        let prefix = isIncome ? "+" : "-"
        return "\(prefix)\(String(format: "%.2f", amount))€"
    }

    var formattedDate: String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "it_IT")
        if Calendar.current.isDateInToday(date) {
            return "Oggi"
        } else if Calendar.current.isDateInYesterday(date) {
            return "Ieri"
        } else {
            formatter.dateFormat = "d MMM"
            return formatter.string(from: date)
        }
    }
}

// MARK: - Sample Data

extension Transaction {
    static var sampleTransactions: [Transaction] {
        let cal = Calendar.current
        let now = Date()
        return [
            Transaction(amount: 2200, title: "Stipendio", category: .salary,
                        date: cal.date(byAdding: .day, value: -25, to: now)!, isIncome: true),
            Transaction(amount: 45.50, title: "Spesa settimanale", merchant: "Esselunga",
                        category: .food, date: cal.date(byAdding: .day, value: -1, to: now)!),
            Transaction(amount: 3.80, title: "Caffè e cornetto", merchant: "Bar Roma",
                        category: .food, date: now),
            Transaction(amount: 35, title: "Pieno benzina", merchant: "ENI",
                        category: .transport, date: cal.date(byAdding: .day, value: -2, to: now)!),
            Transaction(amount: 12.99, title: "Netflix", merchant: "Netflix",
                        category: .subscriptions, date: cal.date(byAdding: .day, value: -5, to: now)!,
                        isRecurring: true, isSubscription: true),
            Transaction(amount: 9.99, title: "Spotify", merchant: "Spotify",
                        category: .subscriptions, date: cal.date(byAdding: .day, value: -5, to: now)!,
                        isRecurring: true, isSubscription: true),
            Transaction(amount: 89, title: "Cena fuori", merchant: "Ristorante Bella Napoli",
                        category: .entertainment, date: cal.date(byAdding: .day, value: -3, to: now)!),
            Transaction(amount: 25, title: "Taxi", merchant: "FreeNow",
                        category: .transport, date: cal.date(byAdding: .day, value: -3, to: now)!),
            Transaction(amount: 650, title: "Affitto", merchant: "Proprietario",
                        category: .home, date: cal.date(byAdding: .day, value: -20, to: now)!,
                        isRecurring: true),
            Transaction(amount: 120, title: "Bolletta luce", merchant: "Enel",
                        category: .bills, date: cal.date(byAdding: .day, value: -15, to: now)!,
                        isRecurring: true),
            Transaction(amount: 55, title: "Scarpe running", merchant: "Decathlon",
                        category: .shopping, date: cal.date(byAdding: .day, value: -7, to: now)!),
            Transaction(amount: 150, title: "Visita medica", merchant: "Studio Dr. Rossi",
                        category: .health, date: cal.date(byAdding: .day, value: -10, to: now)!),
            Transaction(amount: 8.50, title: "Pranzo", merchant: "Paninoteca",
                        category: .food, date: cal.date(byAdding: .day, value: -1, to: now)!),
            Transaction(amount: 29.90, title: "Libro", merchant: "Amazon",
                        category: .education, date: cal.date(byAdding: .day, value: -4, to: now)!),
            Transaction(amount: 15, title: "Aperitivo", merchant: "Spritz Bar",
                        category: .entertainment, date: cal.date(byAdding: .day, value: -6, to: now)!),
        ]
    }
}
