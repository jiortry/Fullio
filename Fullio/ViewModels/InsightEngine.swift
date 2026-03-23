import Foundation

@Observable
final class InsightEngine {
    var insights: [Insight] = []
    var spenderProfile: SpenderProfile = .unknown
    var expensiveDays: [String] = []
    var weeklyPattern: [String: Double] = [:]
    var improvementScore: Double = 0

    func generateInsights(transactions: [Transaction], profile: UserProfile?) {
        guard let profile else { return }
        var results: [Insight] = []

        results.append(contentsOf: analyzeWeeklyComparison(transactions: transactions))
        results.append(contentsOf: analyzeSubscriptions(transactions: transactions))
        results.append(contentsOf: analyzeCategoryTrends(transactions: transactions, profile: profile))
        results.append(contentsOf: analyzeExpensiveDays(transactions: transactions))
        results.append(contentsOf: analyzeSpendingStreaks(transactions: transactions, profile: profile))
        results.append(contentsOf: analyzeImpulsePurchases(transactions: transactions))
        results.append(contentsOf: generateSavingSuggestions(transactions: transactions))

        classifySpenderProfile(transactions: transactions)
        calculateWeeklyPattern(transactions: transactions)
        calculateImprovementScore(transactions: transactions)

        insights = results.sorted { $0.type == .warning && $1.type != .warning }
    }

    // MARK: - Feature 7 & 29: Weekly comparison + improvement

    private func analyzeWeeklyComparison(transactions: [Transaction]) -> [Insight] {
        let cal = Calendar.current
        let now = Date()

        guard let thisWeekStart = cal.dateInterval(of: .weekOfYear, for: now)?.start,
              let lastWeekStart = cal.date(byAdding: .weekOfYear, value: -1, to: thisWeekStart) else {
            return []
        }

        let thisWeek = transactions.filter { !$0.isIncome && $0.date >= thisWeekStart }
            .reduce(0) { $0 + $1.amount }
        let lastWeek = transactions.filter {
            !$0.isIncome && $0.date >= lastWeekStart && $0.date < thisWeekStart
        }.reduce(0) { $0 + $1.amount }

        guard lastWeek > 0 else { return [] }

        let change = ((thisWeek - lastWeek) / lastWeek) * 100

        if change < -10 {
            return [Insight(
                type: .positive, category: .spending,
                title: "Stai migliorando!",
                message: "Questa settimana hai speso il \(Int(abs(change)))% in meno rispetto alla scorsa.",
                icon: "arrow.down.forward",
                relatedAmount: lastWeek - thisWeek
            )]
        } else if change > 20 {
            return [Insight(
                type: .warning, category: .spending,
                title: "Settimana più costosa",
                message: "Hai speso il \(Int(change))% in più della scorsa settimana. Puoi rallentare.",
                icon: "arrow.up.forward",
                relatedAmount: thisWeek - lastWeek
            )]
        }
        return []
    }

    // MARK: - Feature 45: Alert abbonamenti

    private func analyzeSubscriptions(transactions: [Transaction]) -> [Insight] {
        let subs = transactions.filter { $0.isSubscription }
        let total = subs.reduce(0) { $0 + $1.amount }

        guard total > 30 else { return [] }

        return [Insight(
            type: .suggestion, category: .subscription,
            title: "Rivedi i tuoi abbonamenti",
            message: "Spendi \(String(format: "%.0f", total))€/mese in abbonamenti. Vale la pena controllarli.",
            icon: "repeat",
            actionLabel: "Vedi abbonamenti",
            relatedAmount: total
        )]
    }

    // MARK: - Feature 15: Riduzione consigliata per categoria

    private func analyzeCategoryTrends(transactions: [Transaction], profile: UserProfile) -> [Insight] {
        let expenses = transactions.filter { !$0.isIncome }
        let total = expenses.reduce(0) { $0 + $1.amount }
        guard total > 0 else { return [] }

        var grouped: [TransactionCategory: Double] = [:]
        for t in expenses {
            grouped[t.category, default: 0] += t.amount
        }

        var results: [Insight] = []
        for (cat, amount) in grouped {
            let percentage = amount / total * 100
            if percentage > 30 && cat.isExpense {
                results.append(Insight(
                    type: .suggestion, category: .spending,
                    title: "\(cat.rawValue): \(Int(percentage))% del totale",
                    message: "Questa categoria pesa molto. Ridurla del 20% ti farebbe risparmiare \(String(format: "%.0f", amount * 0.2))€.",
                    icon: cat.icon,
                    relatedAmount: amount * 0.2
                ))
            }
        }

        return results
    }

    // MARK: - Feature 25: Analisi "giorni costosi"

    private func analyzeExpensiveDays(transactions: [Transaction]) -> [Insight] {
        let cal = Calendar.current
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "it_IT")
        formatter.dateFormat = "EEEE"

        var dayTotals: [Int: (total: Double, count: Int)] = [:]
        let expenses = transactions.filter { !$0.isIncome }

        for t in expenses {
            let weekday = cal.component(.weekday, from: t.date)
            dayTotals[weekday, default: (0, 0)].total += t.amount
            dayTotals[weekday, default: (0, 0)].count += 1
        }

        let dayAverages = dayTotals.mapValues { $0.total / max(Double($0.count), 1) }
        guard let maxDay = dayAverages.max(by: { $0.value < $1.value }) else { return [] }

        let dayName: String = {
            var comps = DateComponents()
            comps.weekday = maxDay.key
            if let date = cal.nextDate(after: Date(), matching: comps, matchingPolicy: .nextTime, direction: .backward) {
                return formatter.string(from: date).capitalized
            }
            return "Giorno \(maxDay.key)"
        }()

        expensiveDays = [dayName]

        return [Insight(
            type: .neutral, category: .behavior,
            title: "Il \(dayName) è il tuo giorno più costoso",
            message: "In media spendi \(String(format: "%.0f", maxDay.value))€ di \(dayName).",
            icon: "calendar"
        )]
    }

    // MARK: - Feature 30: Spending streaks

    private func analyzeSpendingStreaks(transactions: [Transaction], profile: UserProfile) -> [Insight] {
        let cal = Calendar.current
        let now = Date()
        var streakDays = 0

        for dayOffset in 0..<30 {
            guard let date = cal.date(byAdding: .day, value: -dayOffset, to: now) else { break }
            let dayExpenses = transactions.filter {
                !$0.isIncome && cal.isDate($0.date, inSameDayAs: date)
            }.reduce(0) { $0 + $1.amount }

            if dayExpenses <= profile.dailyBudget {
                streakDays += 1
            } else {
                break
            }
        }

        if streakDays >= 7 {
            return [Insight(
                type: .achievement, category: .saving,
                title: "\(streakDays) giorni sotto budget!",
                message: "Hai rispettato il limite giornaliero per \(streakDays) giorni consecutivi.",
                icon: "star.fill"
            )]
        }
        return []
    }

    // MARK: - Feature 44: Warning spese impulsive

    private func analyzeImpulsePurchases(transactions: [Transaction]) -> [Insight] {
        let cal = Calendar.current
        let now = Date()

        let todayExpenses = transactions.filter {
            !$0.isIncome && cal.isDateInToday($0.date)
        }

        if todayExpenses.count >= 4 {
            return [Insight(
                type: .warning, category: .behavior,
                title: "Giornata già movimentata",
                message: "Hai già \(todayExpenses.count) spese oggi. Prenditi un momento prima della prossima.",
                icon: "hand.raised.fill"
            )]
        }

        let recent3Hours = todayExpenses.filter {
            $0.date.timeIntervalSince(now) > -10800
        }
        if recent3Hours.count >= 3 {
            return [Insight(
                type: .warning, category: .behavior,
                title: "Rallenta un attimo",
                message: "\(recent3Hours.count) spese nelle ultime 3 ore — stai acquistando d'impulso?",
                icon: "bolt.fill"
            )]
        }

        return []
    }

    // MARK: - Feature 18: "Se tagli X → risparmi Y"

    private func generateSavingSuggestions(transactions: [Transaction]) -> [Insight] {
        let cal = Calendar.current
        let now = Date()

        let last30 = transactions.filter {
            guard let monthAgo = cal.date(byAdding: .month, value: -1, to: now) else { return false }
            return !$0.isIncome && $0.date >= monthAgo
        }

        var grouped: [TransactionCategory: Double] = [:]
        for t in last30 {
            grouped[t.category, default: 0] += t.amount
        }

        var suggestions: [Insight] = []
        let discretionary: [TransactionCategory] = [.entertainment, .food, .shopping]

        for cat in discretionary {
            guard let total = grouped[cat], total > 50 else { continue }
            let yearly = total * 12 * 0.3
            suggestions.append(Insight(
                type: .suggestion, category: .saving,
                title: "Se riduci \(cat.rawValue) del 30%...",
                message: "Risparmieresti circa \(String(format: "%.0f", yearly))€ all'anno.",
                icon: cat.icon,
                actionLabel: "Vedi dettaglio",
                relatedAmount: yearly
            ))
        }

        return suggestions
    }

    // MARK: - Feature 21: Profilo spender

    private func classifySpenderProfile(transactions: [Transaction]) {
        let expenses = transactions.filter { !$0.isIncome }
        guard expenses.count >= 10 else {
            spenderProfile = .unknown
            return
        }

        let cal = Calendar.current
        let amounts = expenses.map(\.amount)
        let mean = amounts.reduce(0, +) / Double(amounts.count)
        let variance = amounts.map { pow($0 - mean, 2) }.reduce(0, +) / Double(amounts.count)
        let cv = sqrt(variance) / max(mean, 1)

        let weekendExpenses = expenses.filter {
            let weekday = cal.component(.weekday, from: $0.date)
            return weekday == 1 || weekday == 7
        }
        let weekendRatio = Double(weekendExpenses.count) / Double(expenses.count)

        let socialCategories: Set<TransactionCategory> = [.entertainment, .food]
        let socialExpenses = expenses.filter { socialCategories.contains($0.category) }
        let socialRatio = Double(socialExpenses.count) / Double(expenses.count)

        if cv > 1.5 {
            spenderProfile = .impulsive
        } else if socialRatio > 0.5 {
            spenderProfile = .social
        } else if weekendRatio > 0.5 {
            spenderProfile = .emotional
        } else if cv < 0.5 {
            spenderProfile = .stable
        } else {
            spenderProfile = .stable
        }
    }

    // MARK: - Feature 23: Pattern settimanali

    private func calculateWeeklyPattern(transactions: [Transaction]) {
        let cal = Calendar.current
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "it_IT")
        formatter.dateFormat = "EEE"

        var dayTotals: [String: [Double]] = [:]
        let expenses = transactions.filter { !$0.isIncome }

        for t in expenses {
            let dayName = formatter.string(from: t.date).capitalized
            dayTotals[dayName, default: []].append(t.amount)
        }

        weeklyPattern = dayTotals.mapValues { values in
            values.reduce(0, +) / max(Double(values.count), 1)
        }
    }

    // MARK: - Feature 29: Improvement score

    private func calculateImprovementScore(transactions: [Transaction]) {
        let cal = Calendar.current
        let now = Date()

        guard let twoMonthsAgo = cal.date(byAdding: .month, value: -2, to: now),
              let oneMonthAgo = cal.date(byAdding: .month, value: -1, to: now) else {
            improvementScore = 0
            return
        }

        let lastMonth = transactions.filter {
            !$0.isIncome && $0.date >= oneMonthAgo
        }.reduce(0) { $0 + $1.amount }

        let prevMonth = transactions.filter {
            !$0.isIncome && $0.date >= twoMonthsAgo && $0.date < oneMonthAgo
        }.reduce(0) { $0 + $1.amount }

        guard prevMonth > 0 else {
            improvementScore = 0
            return
        }

        improvementScore = ((prevMonth - lastMonth) / prevMonth) * 100
    }
}
