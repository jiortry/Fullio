import SwiftUI
import SwiftData

struct GoalsView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \SavingsGoal.createdAt, order: .reverse) private var goals: [SavingsGoal]
    @State private var showAddGoal = false
    @State private var selectedGoal: SavingsGoal?
    @State private var showAddMoney = false
    @State private var addMoneyAmount = ""

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: FullioSpacing.lg) {
                    if goals.isEmpty {
                        emptyState
                    } else {
                        summarySection
                        activeGoalsSection
                        completedGoalsSection
                    }

                    Spacer(minLength: 100)
                }
                .padding(.horizontal, FullioSpacing.md)
                .padding(.top, FullioSpacing.sm)
            }
            .background(Color.fullioBackground)
            .navigationTitle("Obiettivi")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showAddGoal = true
                    } label: {
                        Image(systemName: "plus.circle.fill")
                            .font(.title3)
                            .foregroundStyle(.fullioDarkGreen)
                    }
                }
            }
            .sheet(isPresented: $showAddGoal) {
                AddGoalView()
            }
            .sheet(isPresented: $showAddMoney) {
                addMoneySheet
            }
        }
    }

    // MARK: - Summary

    private var summarySection: some View {
        let totalSaved = goals.reduce(0) { $0 + $1.currentAmount }
        let totalTarget = goals.reduce(0) { $0 + $1.targetAmount }
        let overallProgress = totalTarget > 0 ? totalSaved / totalTarget : 0

        return VStack(spacing: FullioSpacing.md) {
            ZStack {
                ProgressRing(
                    progress: overallProgress,
                    lineWidth: 10,
                    size: 100
                )

                VStack(spacing: 2) {
                    Text("\(Int(overallProgress * 100))%")
                        .font(FullioFont.headline())
                        .foregroundStyle(.fullioDarkGreen)
                    Text("totale")
                        .font(FullioFont.caption(11))
                        .foregroundStyle(.fullioSecondaryText)
                }
            }

            Text("Hai risparmiato \(Int(totalSaved))€ su \(Int(totalTarget))€")
                .font(FullioFont.body(14))
                .foregroundStyle(.fullioSecondaryText)
        }
        .fullioCard()
    }

    // MARK: - Active Goals

    private var activeGoals: [SavingsGoal] {
        goals.filter { $0.isActive && $0.progress < 1.0 }
    }

    private var completedGoals: [SavingsGoal] {
        goals.filter { $0.progress >= 1.0 }
    }

    private var activeGoalsSection: some View {
        Group {
            if !activeGoals.isEmpty {
                VStack(alignment: .leading, spacing: FullioSpacing.sm) {
                    Text("In corso")
                        .font(FullioFont.headline(16))
                        .foregroundStyle(.fullioBlack)

                    ForEach(activeGoals, id: \.id) { goal in
                        GoalProgressCard(goal: goal)
                            .onTapGesture {
                                selectedGoal = goal
                                addMoneyAmount = ""
                                showAddMoney = true
                            }
                            .contextMenu {
                                Button("Aggiungi fondi", systemImage: "plus.circle") {
                                    selectedGoal = goal
                                    addMoneyAmount = ""
                                    showAddMoney = true
                                }
                                Button("Elimina", systemImage: "trash", role: .destructive) {
                                    modelContext.delete(goal)
                                }
                            }
                    }
                }
            }
        }
    }

    // MARK: - Completed Goals

    private var completedGoalsSection: some View {
        Group {
            if !completedGoals.isEmpty {
                VStack(alignment: .leading, spacing: FullioSpacing.sm) {
                    Text("Completati")
                        .font(FullioFont.headline(16))
                        .foregroundStyle(.fullioBlack)

                    ForEach(completedGoals, id: \.id) { goal in
                        GoalProgressCard(goal: goal)
                    }
                }
            }
        }
    }

    // MARK: - Empty State

    private var emptyState: some View {
        VStack(spacing: FullioSpacing.lg) {
            Spacer(minLength: 60)

            Image(systemName: "target")
                .font(.system(size: 48))
                .foregroundStyle(.fullioNeutral)

            Text("Nessun obiettivo")
                .font(FullioFont.headline())
                .foregroundStyle(.fullioBlack)

            Text("Crea il tuo primo obiettivo di risparmio\ne inizia a mettere da parte")
                .font(FullioFont.body(14))
                .foregroundStyle(.fullioSecondaryText)
                .multilineTextAlignment(.center)

            Button {
                showAddGoal = true
            } label: {
                Text("Crea obiettivo")
                    .font(FullioFont.body().weight(.semibold))
                    .foregroundStyle(.white)
                    .padding(.horizontal, FullioSpacing.xl)
                    .padding(.vertical, FullioSpacing.md)
                    .background(Color.fullioDarkGreen)
                    .clipShape(Capsule())
            }

            Spacer(minLength: 60)
        }
    }

    // MARK: - Add Money Sheet

    private var addMoneySheet: some View {
        NavigationStack {
            VStack(spacing: FullioSpacing.lg) {
                if let goal = selectedGoal {
                    VStack(spacing: FullioSpacing.sm) {
                        Image(systemName: goal.icon)
                            .font(.title)
                            .foregroundStyle(.fullioDarkGreen)

                        Text(goal.name)
                            .font(FullioFont.headline())

                        Text("Mancano \(Int(goal.remaining))€")
                            .font(FullioFont.body(14))
                            .foregroundStyle(.fullioSecondaryText)
                    }

                    HStack(alignment: .firstTextBaseline) {
                        TextField("0", text: $addMoneyAmount)
                            .font(FullioFont.number(48))
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.center)

                        Text("€")
                            .font(FullioFont.number(24))
                            .foregroundStyle(.fullioSecondaryText)
                    }
                    .padding(.vertical, FullioSpacing.lg)
                }

                Spacer()
            }
            .padding(FullioSpacing.lg)
            .background(Color.fullioBackground)
            .navigationTitle("Aggiungi fondi")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Annulla") { showAddMoney = false }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Aggiungi") {
                        if let amount = Double(addMoneyAmount.replacingOccurrences(of: ",", with: ".")),
                           let goal = selectedGoal {
                            goal.currentAmount += amount
                            showAddMoney = false
                        }
                    }
                    .font(.body.weight(.semibold))
                    .foregroundStyle(.fullioDarkGreen)
                    .disabled(addMoneyAmount.isEmpty)
                }
            }
        }
        .presentationDetents([.medium])
    }
}

#Preview {
    GoalsView()
        .modelContainer(for: SavingsGoal.self, inMemory: true)
}
