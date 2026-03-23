import SwiftUI
import SwiftData

struct ProfileView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var profiles: [UserProfile]
    @Query private var transactions: [Transaction]

    @State private var showEditProfile = false
    @State private var showResetAlert = false

    private var profile: UserProfile? { profiles.first }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: FullioSpacing.lg) {
                    profileHeader

                    financialSummary

                    savingsModeSection

                    displayModeSection

                    subscriptionsSection

                    dataSection

                    Spacer(minLength: 100)
                }
                .padding(.horizontal, FullioSpacing.md)
                .padding(.top, FullioSpacing.sm)
            }
            .background(Color.fullioBackground)
            .navigationTitle("Profilo")
            .navigationBarTitleDisplayMode(.large)
            .sheet(isPresented: $showEditProfile) {
                EditProfileView()
            }
            .alert("Resettare tutti i dati?", isPresented: $showResetAlert) {
                Button("Annulla", role: .cancel) {}
                Button("Reset", role: .destructive) { resetAllData() }
            } message: {
                Text("Questa azione cancellerà tutte le transazioni e gli obiettivi. Non può essere annullata.")
            }
        }
    }

    // MARK: - Header

    private var profileHeader: some View {
        VStack(spacing: FullioSpacing.md) {
            Circle()
                .fill(Color.fullioLightGreen)
                .frame(width: 72, height: 72)
                .overlay {
                    Text(initials)
                        .font(FullioFont.title(28))
                        .foregroundStyle(.fullioDarkGreen)
                }

            if let name = profile?.name, !name.isEmpty {
                Text(name)
                    .font(FullioFont.headline())
                    .foregroundStyle(.fullioBlack)
            }

            Button {
                showEditProfile = true
            } label: {
                Text("Modifica profilo")
                    .font(FullioFont.caption())
                    .foregroundStyle(.fullioDarkGreen)
                    .padding(.horizontal, FullioSpacing.md)
                    .padding(.vertical, FullioSpacing.sm)
                    .background(Color.fullioLightGreen)
                    .clipShape(Capsule())
            }
        }
        .frame(maxWidth: .infinity)
        .fullioCard()
    }

    // MARK: - Financial Summary

    private var financialSummary: some View {
        VStack(spacing: FullioSpacing.md) {
            HStack {
                Text("Riepilogo finanziario")
                    .font(FullioFont.headline(16))
                    .foregroundStyle(.fullioBlack)
                Spacer()
            }

            if let p = profile {
                SummaryRow(label: "Entrate mensili", value: "\(Int(p.monthlyIncome))€")
                Divider()
                SummaryRow(label: "Spese fisse", value: "\(Int(p.fixedExpenses))€")
                Divider()
                SummaryRow(label: "Target risparmio", value: "\(Int(p.savingsTargetPercent * 100))%")
                Divider()
                SummaryRow(label: "Budget mensile", value: "\(Int(p.monthlyBudget))€",
                           valueColor: .fullioDarkGreen)
                Divider()
                SummaryRow(label: "Budget giornaliero", value: "\(String(format: "%.1f", p.dailyBudget))€",
                           valueColor: .fullioDarkGreen)
            }
        }
        .fullioCard()
    }

    // MARK: - Savings Mode

    private var savingsModeSection: some View {
        VStack(alignment: .leading, spacing: FullioSpacing.md) {
            Text("Modalità risparmio")
                .font(FullioFont.headline(16))
                .foregroundStyle(.fullioBlack)

            ForEach(SavingsMode.allCases, id: \.self) { mode in
                Button {
                    profile?.savingsMode = mode
                } label: {
                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text(mode.rawValue)
                                .font(FullioFont.body().weight(.medium))
                                .foregroundStyle(.fullioBlack)
                            Text(mode.description)
                                .font(FullioFont.caption(12))
                                .foregroundStyle(.fullioSecondaryText)
                        }

                        Spacer()

                        Image(systemName: profile?.savingsMode == mode
                              ? "checkmark.circle.fill" : "circle")
                        .font(.title3)
                        .foregroundStyle(profile?.savingsMode == mode
                                         ? .fullioDarkGreen : .fullioNeutral)
                    }
                    .padding(.vertical, FullioSpacing.xs)
                }
            }
        }
        .fullioCard()
    }

    // MARK: - Display Mode

    private var displayModeSection: some View {
        VStack(alignment: .leading, spacing: FullioSpacing.md) {
            Text("Modalità visualizzazione")
                .font(FullioFont.headline(16))
                .foregroundStyle(.fullioBlack)

            ForEach(DisplayMode.allCases, id: \.self) { mode in
                Button {
                    profile?.displayMode = mode
                } label: {
                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text(mode.rawValue)
                                .font(FullioFont.body().weight(.medium))
                                .foregroundStyle(.fullioBlack)
                            Text(mode.description)
                                .font(FullioFont.caption(12))
                                .foregroundStyle(.fullioSecondaryText)
                        }

                        Spacer()

                        Image(systemName: profile?.displayMode == mode
                              ? "checkmark.circle.fill" : "circle")
                        .font(.title3)
                        .foregroundStyle(profile?.displayMode == mode
                                         ? .fullioDarkGreen : .fullioNeutral)
                    }
                    .padding(.vertical, FullioSpacing.xs)
                }
            }
        }
        .fullioCard()
    }

    // MARK: - Subscriptions

    private var subscriptionsSection: some View {
        let subs = transactions.filter { $0.isSubscription }
        let total = subs.reduce(0) { $0 + $1.amount }

        return Group {
            if !subs.isEmpty {
                VStack(alignment: .leading, spacing: FullioSpacing.md) {
                    HStack {
                        Text("I tuoi abbonamenti")
                            .font(FullioFont.headline(16))
                            .foregroundStyle(.fullioBlack)
                        Spacer()
                        Text("\(String(format: "%.0f", total))€/mese")
                            .font(FullioFont.caption())
                            .foregroundStyle(.fullioSecondaryText)
                    }

                    ForEach(subs, id: \.id) { sub in
                        HStack {
                            Image(systemName: "repeat")
                                .foregroundStyle(.fullioSoftGreen)
                            Text(sub.title)
                                .font(FullioFont.body(14))
                            Spacer()
                            Text("\(String(format: "%.2f", sub.amount))€")
                                .font(FullioFont.smallNumber(14))
                        }
                    }
                }
                .fullioCard()
            }
        }
    }

    // MARK: - Data

    private var dataSection: some View {
        VStack(spacing: FullioSpacing.md) {
            Button {
                showResetAlert = true
            } label: {
                HStack {
                    Image(systemName: "trash")
                    Text("Resetta tutti i dati")
                }
                .font(FullioFont.body())
                .foregroundStyle(.fullioWarning)
                .frame(maxWidth: .infinity)
                .padding(.vertical, FullioSpacing.md)
            }
        }
        .fullioCard()
    }

    // MARK: - Helpers

    private var initials: String {
        guard let name = profile?.name, !name.isEmpty else { return "?" }
        let parts = name.split(separator: " ")
        let first = parts.first?.prefix(1) ?? "?"
        let last = parts.count > 1 ? String(parts.last!.prefix(1)) : ""
        return "\(first)\(last)".uppercased()
    }

    private func resetAllData() {
        do {
            try modelContext.delete(model: Transaction.self)
            try modelContext.delete(model: SavingsGoal.self)
        } catch {
            print("Reset failed: \(error)")
        }
    }
}

struct SummaryRow: View {
    let label: String
    let value: String
    var valueColor: Color = .fullioBlack

    var body: some View {
        HStack {
            Text(label)
                .font(FullioFont.body(14))
                .foregroundStyle(.fullioSecondaryText)
            Spacer()
            Text(value)
                .font(FullioFont.body(14).weight(.semibold))
                .foregroundStyle(valueColor)
        }
    }
}

// MARK: - Edit Profile View

struct EditProfileView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Query private var profiles: [UserProfile]

    @State private var name = ""
    @State private var income = ""
    @State private var fixedExpenses = ""
    @State private var savingsPercent = 15.0

    private var profile: UserProfile? { profiles.first }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: FullioSpacing.lg) {
                    VStack(spacing: FullioSpacing.md) {
                        FullioTextField(title: "Nome", text: $name, placeholder: "Il tuo nome")

                        VStack(alignment: .leading, spacing: FullioSpacing.sm) {
                            Text("Entrate mensili")
                                .font(FullioFont.caption())
                                .foregroundStyle(.fullioSecondaryText)
                            HStack {
                                TextField("0", text: $income)
                                    .keyboardType(.decimalPad)
                                    .font(FullioFont.body())
                                Text("€")
                                    .foregroundStyle(.fullioSecondaryText)
                            }
                            .padding(FullioSpacing.sm)
                            .background(Color.fullioBackground)
                            .clipShape(RoundedRectangle(cornerRadius: FullioRadius.sm))
                        }

                        VStack(alignment: .leading, spacing: FullioSpacing.sm) {
                            Text("Spese fisse mensili")
                                .font(FullioFont.caption())
                                .foregroundStyle(.fullioSecondaryText)
                            HStack {
                                TextField("0", text: $fixedExpenses)
                                    .keyboardType(.decimalPad)
                                    .font(FullioFont.body())
                                Text("€")
                                    .foregroundStyle(.fullioSecondaryText)
                            }
                            .padding(FullioSpacing.sm)
                            .background(Color.fullioBackground)
                            .clipShape(RoundedRectangle(cornerRadius: FullioRadius.sm))
                        }

                        VStack(alignment: .leading, spacing: FullioSpacing.sm) {
                            Text("Obiettivo risparmio: \(Int(savingsPercent))%")
                                .font(FullioFont.caption())
                                .foregroundStyle(.fullioSecondaryText)

                            Slider(value: $savingsPercent, in: 5...50, step: 5)
                                .tint(.fullioDarkGreen)
                        }
                    }
                    .fullioCard()
                }
                .padding(FullioSpacing.md)
            }
            .background(Color.fullioBackground)
            .navigationTitle("Modifica profilo")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Annulla") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Salva") { saveProfile() }
                        .font(.body.weight(.semibold))
                        .foregroundStyle(.fullioDarkGreen)
                }
            }
            .onAppear {
                if let p = profile {
                    name = p.name
                    income = p.monthlyIncome > 0 ? String(Int(p.monthlyIncome)) : ""
                    fixedExpenses = p.fixedExpenses > 0 ? String(Int(p.fixedExpenses)) : ""
                    savingsPercent = p.savingsTargetPercent * 100
                }
            }
        }
    }

    private func saveProfile() {
        if let p = profile {
            p.name = name
            p.monthlyIncome = Double(income) ?? 0
            p.fixedExpenses = Double(fixedExpenses) ?? 0
            p.savingsTargetPercent = savingsPercent / 100
        }
        dismiss()
    }
}

#Preview {
    ProfileView()
        .modelContainer(for: [UserProfile.self, Transaction.self], inMemory: true)
}
