import Foundation
import SwiftData

@Model
final class SavingsGoal {
    var id: UUID
    var name: String
    var targetAmount: Double
    var currentAmount: Double
    var deadline: Date?
    var icon: String
    var isActive: Bool
    var createdAt: Date

    init(
        name: String,
        targetAmount: Double,
        currentAmount: Double = 0,
        deadline: Date? = nil,
        icon: String = "star.fill",
        isActive: Bool = true
    ) {
        self.id = UUID()
        self.name = name
        self.targetAmount = targetAmount
        self.currentAmount = currentAmount
        self.deadline = deadline
        self.icon = icon
        self.isActive = isActive
        self.createdAt = .now
    }

    var progress: Double {
        guard targetAmount > 0 else { return 0 }
        return min(currentAmount / targetAmount, 1.0)
    }

    var remaining: Double {
        max(targetAmount - currentAmount, 0)
    }

    var formattedProgress: String {
        "\(Int(progress * 100))%"
    }

    var daysRemaining: Int? {
        guard let deadline else { return nil }
        return Calendar.current.dateComponents([.day], from: .now, to: deadline).day
    }

    var dailySavingsNeeded: Double? {
        guard let days = daysRemaining, days > 0 else { return nil }
        return remaining / Double(days)
    }

    var estimatedCompletionMessage: String {
        if progress >= 1.0 {
            return "Obiettivo raggiunto! 🎉"
        }
        if let days = daysRemaining {
            if days <= 0 {
                return "Scadenza passata — puoi ancora farcela"
            }
            if let daily = dailySavingsNeeded {
                return "Metti da parte \(String(format: "%.1f", daily))€/giorno per arrivarci"
            }
        }
        return "Continua così, sei sulla buona strada"
    }

    static var sampleGoals: [SavingsGoal] {
        let cal = Calendar.current
        return [
            SavingsGoal(name: "Vacanza estiva", targetAmount: 1500, currentAmount: 620,
                        deadline: cal.date(byAdding: .month, value: 3, to: .now),
                        icon: "airplane"),
            SavingsGoal(name: "Fondo emergenza", targetAmount: 3000, currentAmount: 1800,
                        icon: "shield.fill"),
            SavingsGoal(name: "MacBook nuovo", targetAmount: 2000, currentAmount: 450,
                        deadline: cal.date(byAdding: .month, value: 6, to: .now),
                        icon: "laptopcomputer"),
        ]
    }
}
