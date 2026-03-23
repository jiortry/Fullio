import Foundation
import SwiftData
import SwiftUI

@Observable
final class FinanceManager {
    private var modelContext: ModelContext?

    var safeToSpend: Double = 0
    var monthlyForecast: Double = 0
    var weeklyTrend: Double = 0
    var daysUntilBroke: Int? = nil
    var todaySpent: Double = 0
    var thisWeekSpent: Double = 0
    var thisMonthSpent: Double = 0
    var thisMonthIncome: Double = 0
    var projectedSavings: Double = 0
    var budgetRisk: BudgetRisk = .safe
    var savingsPotential: Double = 0
    var dailySavingsSuggestion: Double = 0
    var spendingAcceleration: Double = 0
    var anomalies: [Transaction] = []
    var subscriptionTotal: Double = 0
    var recurringTotal: Double = 0

    enum BudgetRisk: String {
        case safe = "Sicuro"
        case caution = "Attenzione"
        case danger = "Rischio"

        var color: Color {
            switch self {
            case .safe: return .fullioSoftGreen
            case .caution: return .orange
            case .danger: return .fullioWarning
            }
        }

        var icon: String {
            switch self {
            case .safe: return "checkmark.shield.fill"
            case .caution: return "exclamationmark.triangle.fill"
            case .danger: return "xmark.shield.fill"
            }
        }
    }

    func configure(with context: ModelContext) {
        self.modelContext = context
    }

    func refresh(transactions: [Transaction], profile: UserProfile?) {
        guard let profile else { return }
        let cal = Calendar.current
        let now = Date()

        let monthTransactions = transactions.filter {
            cal.isDate($0.date, equalTo: now, toGranularity: .month)
        }

        let expenses = monthTransactions.filter { !$0.isIncome }
        let incomes = monthTransactions.filter { $0.isIncome }

        thisMonthSpent = expenses.reduce(0) { $0 + $1.amount }
        thisMonthIncome = incomes.reduce(0) { $0 + $1.amount }

        let todayExpenses = expenses.filter { cal.isDateInToday($0.date) }
        todaySpent = todayExpenses.reduce(0) { $0 + $1.amount }

        let weekStart = cal.dateInterval(of: .weekOfYear, for: now)?.start ?? now
        let weekExpenses = expenses.filter { $0.date >= weekStart }
        thisWeekSpent = weekExpenses.reduce(0) { $0 + $1.amount }

        calculateSafeToSpend(expenses: expenses, profile: profile)
        calculateForecast(expenses: expenses, profile: profile)
        calculateWeeklyTrend(transactions: transactions)
        calculateBudgetRisk(expenses: expenses, profile: profile)
        calculateDaysUntilBroke(expenses: expenses, profile: profile)
        calculateSavingsPotential(expenses: expenses, profile: profile)
        detectAnomalies(expenses: expenses)
        calculateSubscriptions(transactions: monthTransactions)
        calculateSpendingAcceleration(expenses: expenses)
        calculateDailySavings(profile: profile)
    }

    // MARK: - Feature 1: Safe-to-spend giornaliero

    private func calculateSafeToSpend(expenses: [Transaction], profile: UserProfile) {
        let cal = Calendar.current
        let now = Date()
        let dayOfMonth = cal.component(.day, from: now)
        let daysInMonth = cal.range(of: .day, in: .month, for: now)?.count ?? 30
        let remainingDays = max(daysInMonth - dayOfMonth + 1, 1)

        let totalBudget = profile.monthlyBudget
        let remainingBudget = totalBudget - thisMonthSpent + todaySpent
        safeToSpend = max(remainingBudget / Double(remainingDays), 0)
    }

    // MARK: - Feature 2 & 10: Forecast fine mese / surplus-deficit

    private func calculateForecast(expenses: [Transaction], profile: UserProfile) {
        let cal = Calendar.current
        let now = Date()
        let dayOfMonth = cal.component(.day, from: now)
        let daysInMonth = cal.range(of: .day, in: .month, for: now)?.count ?? 30

        guard dayOfMonth > 1 else {
            monthlyForecast = profile.monthlyBudget
            projectedSavings = profile.monthlySavingsTarget
            return
        }

        let dailyAverage = thisMonthSpent / Double(dayOfMonth)
        let projectedTotal = dailyAverage * Double(daysInMonth)
        monthlyForecast = profile.monthlyBudget - projectedTotal
        projectedSavings = profile.monthlyIncome - profile.fixedExpenses - projectedTotal
    }

    // MARK: - Feature 4: Rischio sforamento budget

    private func calculateBudgetRisk(expenses: [Transaction], profile: UserProfile) {
        let ratio = thisMonthSpent / max(profile.monthlyBudget, 1)
        let cal = Calendar.current
        let dayOfMonth = Double(cal.component(.day, from: Date()))
        let daysInMonth = Double(cal.range(of: .day, in: .month, for: Date())?.count ?? 30)
        let timeRatio = dayOfMonth / daysInMonth

        if ratio > timeRatio * 1.3 {
            budgetRisk = .danger
        } else if ratio > timeRatio * 1.1 {
            budgetRisk = .caution
        } else {
            budgetRisk = .safe
        }
    }

    // MARK: - Feature 6: Previsione giorni senza soldi

    private func calculateDaysUntilBroke(expenses: [Transaction], profile: UserProfile) {
        let cal = Calendar.current
        let dayOfMonth = cal.component(.day, from: Date())

        guard dayOfMonth > 2 else {
            daysUntilBroke = nil
            return
        }

        let dailyAverage = thisMonthSpent / Double(dayOfMonth)
        guard dailyAverage > 0 else {
            daysUntilBroke = nil
            return
        }

        let remaining = profile.monthlyBudget - thisMonthSpent
        if remaining <= 0 {
            daysUntilBroke = 0
        } else {
            let days = Int(remaining / dailyAverage)
            daysUntilBroke = days
        }
    }

    // MARK: - Feature 7: Analisi trend spesa settimanale

    private func calculateWeeklyTrend(transactions: [Transaction]) {
        let cal = Calendar.current
        let now = Date()

        guard let thisWeekStart = cal.dateInterval(of: .weekOfYear, for: now)?.start,
              let lastWeekStart = cal.date(byAdding: .weekOfYear, value: -1, to: thisWeekStart) else {
            weeklyTrend = 0
            return
        }

        let thisWeekExpenses = transactions.filter {
            !$0.isIncome && $0.date >= thisWeekStart && $0.date < now
        }
        let lastWeekExpenses = transactions.filter {
            !$0.isIncome && $0.date >= lastWeekStart && $0.date < thisWeekStart
        }

        let thisWeekTotal = thisWeekExpenses.reduce(0) { $0 + $1.amount }
        let lastWeekTotal = lastWeekExpenses.reduce(0) { $0 + $1.amount }

        guard lastWeekTotal > 0 else {
            weeklyTrend = 0
            return
        }

        weeklyTrend = ((thisWeekTotal - lastWeekTotal) / lastWeekTotal) * 100
    }

    // MARK: - Feature 8: Rilevazione spese anomale

    private func detectAnomalies(expenses: [Transaction]) {
        guard expenses.count >= 5 else {
            anomalies = []
            return
        }

        let amounts = expenses.map(\.amount)
        let mean = amounts.reduce(0, +) / Double(amounts.count)
        let variance = amounts.map { pow($0 - mean, 2) }.reduce(0, +) / Double(amounts.count)
        let stdDev = sqrt(variance)
        let threshold = mean + 2 * stdDev

        anomalies = expenses.filter { $0.amount > threshold }
    }

    // MARK: - Feature 9: Analisi accelerazione spesa

    private func calculateSpendingAcceleration(expenses: [Transaction]) {
        let cal = Calendar.current
        let now = Date()

        let last7 = expenses.filter {
            guard let weekAgo = cal.date(byAdding: .day, value: -7, to: now) else { return false }
            return $0.date >= weekAgo
        }
        let prev7 = expenses.filter {
            guard let weekAgo = cal.date(byAdding: .day, value: -7, to: now),
                  let twoWeeksAgo = cal.date(byAdding: .day, value: -14, to: now) else { return false }
            return $0.date >= twoWeeksAgo && $0.date < weekAgo
        }

        let recentRate = last7.reduce(0) { $0 + $1.amount } / 7.0
        let previousRate = prev7.reduce(0) { $0 + $1.amount } / 7.0

        guard previousRate > 0 else {
            spendingAcceleration = 0
            return
        }

        spendingAcceleration = ((recentRate - previousRate) / previousRate) * 100
    }

    // MARK: - Feature 16: Risparmio potenziale mensile

    private func calculateSavingsPotential(expenses: [Transaction], profile: UserProfile) {
        let nonEssential = expenses.filter {
            [.entertainment, .shopping, .food].contains($0.category)
        }
        let nonEssentialTotal = nonEssential.reduce(0) { $0 + $1.amount }
        savingsPotential = nonEssentialTotal * 0.20
    }

    // MARK: - Feature 14: Quanto puoi mettere da parte oggi

    private func calculateDailySavings(profile: UserProfile) {
        let surplus = safeToSpend - (profile.dailyBudget * 0.7)
        dailySavingsSuggestion = max(surplus, 0)
    }

    // MARK: - Feature 36: Riconoscimento abbonamenti

    private func calculateSubscriptions(transactions: [Transaction]) {
        let subs = transactions.filter { $0.isSubscription }
        subscriptionTotal = subs.reduce(0) { $0 + $1.amount }

        let recurring = transactions.filter { $0.isRecurring && !$0.isSubscription }
        recurringTotal = recurring.reduce(0) { $0 + $1.amount }
    }

    // MARK: - Feature 5: Simulazione "se continuo così"

    func simulateIfContinue(profile: UserProfile) -> (savings3m: Double, savings6m: Double, savings12m: Double) {
        let monthlySavings = projectedSavings
        return (
            savings3m: monthlySavings * 3,
            savings6m: monthlySavings * 6,
            savings12m: monthlySavings * 12
        )
    }

    // MARK: - Feature 18: "Se tagli X → risparmi Y"

    func cutSimulation(category: TransactionCategory, reduction: Double, transactions: [Transaction]) -> Double {
        let catTotal = transactions.filter { $0.category == category && !$0.isIncome }
            .reduce(0) { $0 + $1.amount }
        return catTotal * reduction * 12
    }

    // MARK: - Category breakdown

    func categoryBreakdown(transactions: [Transaction]) -> [(category: TransactionCategory, total: Double, percentage: Double)] {
        let expenses = transactions.filter { !$0.isIncome }
        let total = expenses.reduce(0) { $0 + $1.amount }
        guard total > 0 else { return [] }

        var grouped: [TransactionCategory: Double] = [:]
        for t in expenses {
            grouped[t.category, default: 0] += t.amount
        }

        return grouped.map { (category: $0.key, total: $0.value, percentage: $0.value / total * 100) }
            .sorted { $0.total > $1.total }
    }
}
