import SwiftUI
import SwiftData

struct OnboardingView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var profiles: [UserProfile]

    @State private var currentStep = 0
    @State private var name = ""
    @State private var income = ""
    @State private var fixedExpenses = ""
    @State private var savingsPercent = 15.0
    @State private var savingsMode: SavingsMode = .soft

    var onComplete: () -> Void

    private let totalSteps = 4

    var body: some View {
        VStack(spacing: 0) {
            progressBar

            TabView(selection: $currentStep) {
                welcomeStep.tag(0)
                incomeStep.tag(1)
                expensesStep.tag(2)
                savingsStep.tag(3)
            }
            .tabViewStyle(.page(indexDisplayMode: .never))
            .animation(.easeInOut(duration: 0.3), value: currentStep)

            bottomBar
        }
        .background(Color.fullioBackground)
    }

    // MARK: - Progress Bar

    private var progressBar: some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                Rectangle()
                    .fill(Color.fullioSoftGreen.opacity(0.2))

                Rectangle()
                    .fill(Color.fullioDarkGreen)
                    .frame(width: geo.size.width * CGFloat(currentStep + 1) / CGFloat(totalSteps))
                    .animation(.easeInOut(duration: 0.3), value: currentStep)
            }
        }
        .frame(height: 4)
    }

    // MARK: - Step 1: Welcome

    private var welcomeStep: some View {
        VStack(spacing: FullioSpacing.xl) {
            Spacer()

            Image(systemName: "leaf.fill")
                .font(.system(size: 64))
                .foregroundStyle(.fullioDarkGreen)

            VStack(spacing: FullioSpacing.md) {
                Text("Benvenuto in Fullio")
                    .font(FullioFont.title())
                    .foregroundStyle(.fullioBlack)

                Text("Il tuo assistente personale\nper risparmiare senza pensarci")
                    .font(FullioFont.body())
                    .foregroundStyle(.fullioSecondaryText)
                    .multilineTextAlignment(.center)
            }

            VStack(spacing: FullioSpacing.md) {
                Text("Come ti chiami?")
                    .font(FullioFont.headline(18))
                    .foregroundStyle(.fullioBlack)

                TextField("Il tuo nome", text: $name)
                    .font(FullioFont.body())
                    .padding(FullioSpacing.md)
                    .background(Color.fullioCardBackground)
                    .clipShape(RoundedRectangle(cornerRadius: FullioRadius.md))
                    .multilineTextAlignment(.center)
            }
            .padding(.horizontal, FullioSpacing.xl)

            Spacer()
        }
    }

    // MARK: - Step 2: Income

    private var incomeStep: some View {
        VStack(spacing: FullioSpacing.xl) {
            Spacer()

            VStack(spacing: FullioSpacing.md) {
                Image(systemName: "banknote.fill")
                    .font(.system(size: 40))
                    .foregroundStyle(.fullioDarkGreen)

                Text("Quanto guadagni al mese?")
                    .font(FullioFont.headline(22))
                    .foregroundStyle(.fullioBlack)

                Text("Non deve essere preciso, una stima va benissimo")
                    .font(FullioFont.body(14))
                    .foregroundStyle(.fullioSecondaryText)
                    .multilineTextAlignment(.center)
            }

            HStack(alignment: .firstTextBaseline, spacing: 4) {
                TextField("0", text: $income)
                    .font(FullioFont.number(48))
                    .keyboardType(.numberPad)
                    .multilineTextAlignment(.center)

                Text("€")
                    .font(FullioFont.number(24))
                    .foregroundStyle(.fullioSecondaryText)
            }
            .padding(.horizontal, FullioSpacing.xl)

            quickAmountButtons(amounts: [1200, 1500, 1800, 2200, 2500, 3000], binding: $income)

            Spacer()
        }
    }

    // MARK: - Step 3: Fixed Expenses

    private var expensesStep: some View {
        VStack(spacing: FullioSpacing.xl) {
            Spacer()

            VStack(spacing: FullioSpacing.md) {
                Image(systemName: "house.fill")
                    .font(.system(size: 40))
                    .foregroundStyle(.fullioDarkGreen)

                Text("Quanto spendi di fisso?")
                    .font(FullioFont.headline(22))
                    .foregroundStyle(.fullioBlack)

                Text("Affitto, bollette, assicurazione...\nTutto ciò che paghi ogni mese")
                    .font(FullioFont.body(14))
                    .foregroundStyle(.fullioSecondaryText)
                    .multilineTextAlignment(.center)
            }

            HStack(alignment: .firstTextBaseline, spacing: 4) {
                TextField("0", text: $fixedExpenses)
                    .font(FullioFont.number(48))
                    .keyboardType(.numberPad)
                    .multilineTextAlignment(.center)

                Text("€")
                    .font(FullioFont.number(24))
                    .foregroundStyle(.fullioSecondaryText)
            }
            .padding(.horizontal, FullioSpacing.xl)

            quickAmountButtons(amounts: [400, 600, 800, 1000, 1200, 1500], binding: $fixedExpenses)

            Spacer()
        }
    }

    // MARK: - Step 4: Savings Goal

    private var savingsStep: some View {
        VStack(spacing: FullioSpacing.xl) {
            Spacer()

            VStack(spacing: FullioSpacing.md) {
                Image(systemName: "target")
                    .font(.system(size: 40))
                    .foregroundStyle(.fullioDarkGreen)

                Text("Quanto vuoi risparmiare?")
                    .font(FullioFont.headline(22))
                    .foregroundStyle(.fullioBlack)

                Text("\(Int(savingsPercent))% del tuo stipendio")
                    .font(FullioFont.number(36))
                    .foregroundStyle(.fullioDarkGreen)

                if let inc = Double(income), inc > 0 {
                    Text("≈ \(Int(inc * savingsPercent / 100))€ al mese")
                        .font(FullioFont.body())
                        .foregroundStyle(.fullioSecondaryText)
                }

                Slider(value: $savingsPercent, in: 5...40, step: 5)
                    .tint(.fullioDarkGreen)
                    .padding(.horizontal, FullioSpacing.xl)
            }

            VStack(spacing: FullioSpacing.sm) {
                Text("Modalità")
                    .font(FullioFont.caption())
                    .foregroundStyle(.fullioSecondaryText)

                HStack(spacing: FullioSpacing.md) {
                    ForEach(SavingsMode.allCases, id: \.self) { mode in
                        Button {
                            savingsMode = mode
                        } label: {
                            VStack(spacing: 4) {
                                Text(mode.rawValue)
                                    .font(FullioFont.body().weight(.medium))
                                Text(mode == .soft ? "Graduale" : "Intenso")
                                    .font(FullioFont.caption(11))
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, FullioSpacing.md)
                            .foregroundStyle(savingsMode == mode ? .white : .fullioDarkGreen)
                            .background(savingsMode == mode ? Color.fullioDarkGreen : Color.fullioCardBackground)
                            .clipShape(RoundedRectangle(cornerRadius: FullioRadius.md))
                        }
                    }
                }
                .padding(.horizontal, FullioSpacing.lg)
            }

            Spacer()
        }
    }

    // MARK: - Quick Amount Buttons

    private func quickAmountButtons(amounts: [Int], binding: Binding<String>) -> some View {
        let columns = Array(repeating: GridItem(.flexible()), count: 3)
        return LazyVGrid(columns: columns, spacing: FullioSpacing.sm) {
            ForEach(amounts, id: \.self) { amount in
                Button {
                    binding.wrappedValue = String(amount)
                } label: {
                    Text("\(amount)€")
                        .font(FullioFont.body(14).weight(.medium))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, FullioSpacing.sm)
                        .foregroundStyle(binding.wrappedValue == String(amount) ? .white : .fullioDarkGreen)
                        .background(binding.wrappedValue == String(amount) ? Color.fullioDarkGreen : Color.fullioCardBackground)
                        .clipShape(RoundedRectangle(cornerRadius: FullioRadius.sm))
                }
            }
        }
        .padding(.horizontal, FullioSpacing.xl)
    }

    // MARK: - Bottom Bar

    private var bottomBar: some View {
        HStack {
            if currentStep > 0 {
                Button {
                    withAnimation { currentStep -= 1 }
                } label: {
                    Text("Indietro")
                        .font(FullioFont.body().weight(.medium))
                        .foregroundStyle(.fullioSecondaryText)
                }
            }

            Spacer()

            Button {
                if currentStep < totalSteps - 1 {
                    withAnimation { currentStep += 1 }
                } else {
                    completeOnboarding()
                }
            } label: {
                Text(currentStep == totalSteps - 1 ? "Iniziamo!" : "Avanti")
                    .font(FullioFont.body().weight(.semibold))
                    .foregroundStyle(.white)
                    .padding(.horizontal, FullioSpacing.xl)
                    .padding(.vertical, FullioSpacing.md)
                    .background(Color.fullioDarkGreen)
                    .clipShape(Capsule())
            }
        }
        .padding(.horizontal, FullioSpacing.lg)
        .padding(.vertical, FullioSpacing.md)
        .background(Color.fullioBackground)
    }

    // MARK: - Complete

    private func completeOnboarding() {
        let profile: UserProfile
        if let existing = profiles.first {
            profile = existing
        } else {
            profile = UserProfile()
            modelContext.insert(profile)
        }

        profile.name = name
        profile.monthlyIncome = Double(income) ?? 0
        profile.fixedExpenses = Double(fixedExpenses) ?? 0
        profile.savingsTargetPercent = savingsPercent / 100
        profile.savingsMode = savingsMode
        profile.hasCompletedOnboarding = true

        onComplete()
    }
}

#Preview {
    OnboardingView(onComplete: {})
        .modelContainer(for: [UserProfile.self, Transaction.self, SavingsGoal.self], inMemory: true)
}
