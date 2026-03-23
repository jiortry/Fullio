import Foundation
import SwiftData

enum SavingsMode: String, Codable, CaseIterable {
    case soft = "Soft"
    case aggressive = "Aggressivo"

    var description: String {
        switch self {
        case .soft: return "Risparmio graduale, senza stress"
        case .aggressive: return "Massimizza il risparmio ogni giorno"
        }
    }

    var savingsMultiplier: Double {
        switch self {
        case .soft: return 0.10
        case .aggressive: return 0.25
        }
    }
}

enum DisplayMode: String, Codable, CaseIterable {
    case lowStress = "Low-stress"
    case fullControl = "Controllo totale"

    var description: String {
        switch self {
        case .lowStress: return "Meno numeri, più messaggi"
        case .fullControl: return "Tutti i dettagli, sempre"
        }
    }
}

enum SpenderProfile: String, Codable {
    case impulsive = "Impulsivo"
    case stable = "Stabile"
    case saver = "Risparmiatore"
    case emotional = "Emotivo"
    case social = "Sociale"
    case unknown = "In analisi"

    var icon: String {
        switch self {
        case .impulsive: return "bolt.fill"
        case .stable: return "equal.circle.fill"
        case .saver: return "leaf.fill"
        case .emotional: return "heart.fill"
        case .social: return "person.2.fill"
        case .unknown: return "questionmark.circle.fill"
        }
    }

    var description: String {
        switch self {
        case .impulsive: return "Tendi a spendere d'impulso — piccole pause ti aiutano"
        case .stable: return "Sei costante e prevedibile — ottima base"
        case .saver: return "Risparmi naturalmente — continua così"
        case .emotional: return "Le emozioni influenzano la spesa — riconoscerlo è il primo passo"
        case .social: return "Le uscite sociali pesano — bilancia con giornate leggere"
        case .unknown: return "Sto ancora imparando i tuoi pattern"
        }
    }
}

@Model
final class UserProfile {
    var id: UUID
    var name: String
    var monthlyIncome: Double
    var fixedExpenses: Double
    var savingsTargetPercent: Double
    var hasCompletedOnboarding: Bool
    var savingsModeRaw: String
    var displayModeRaw: String
    var spenderProfileRaw: String
    var partnerMode: Bool
    var notificationsEnabled: Bool
    var createdAt: Date

    var savingsMode: SavingsMode {
        get { SavingsMode(rawValue: savingsModeRaw) ?? .soft }
        set { savingsModeRaw = newValue.rawValue }
    }

    var displayMode: DisplayMode {
        get { DisplayMode(rawValue: displayModeRaw) ?? .lowStress }
        set { displayModeRaw = newValue.rawValue }
    }

    var spenderProfile: SpenderProfile {
        get { SpenderProfile(rawValue: spenderProfileRaw) ?? .unknown }
        set { spenderProfileRaw = newValue.rawValue }
    }

    init(
        name: String = "",
        monthlyIncome: Double = 0,
        fixedExpenses: Double = 0,
        savingsTargetPercent: Double = 0.15,
        hasCompletedOnboarding: Bool = false
    ) {
        self.id = UUID()
        self.name = name
        self.monthlyIncome = monthlyIncome
        self.fixedExpenses = fixedExpenses
        self.savingsTargetPercent = savingsTargetPercent
        self.hasCompletedOnboarding = hasCompletedOnboarding
        self.savingsModeRaw = SavingsMode.soft.rawValue
        self.displayModeRaw = DisplayMode.lowStress.rawValue
        self.spenderProfileRaw = SpenderProfile.unknown.rawValue
        self.partnerMode = false
        self.notificationsEnabled = true
        self.createdAt = .now
    }

    var monthlyBudget: Double {
        monthlyIncome - fixedExpenses - (monthlyIncome * savingsTargetPercent)
    }

    var dailyBudget: Double {
        let daysInMonth = Double(Calendar.current.range(of: .day, in: .month, for: .now)?.count ?? 30)
        return monthlyBudget / daysInMonth
    }

    var monthlySavingsTarget: Double {
        monthlyIncome * savingsTargetPercent
    }
}
