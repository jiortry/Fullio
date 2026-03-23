import SwiftUI
import SwiftData

struct AddTransactionView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    @State private var title = ""
    @State private var amount = ""
    @State private var merchant = ""
    @State private var category: TransactionCategory = .other
    @State private var date = Date()
    @State private var isIncome = false
    @State private var isRecurring = false
    @State private var isSubscription = false
    @State private var note = ""

    @FocusState private var amountFocused: Bool

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: FullioSpacing.lg) {
                    amountSection
                    detailsSection
                    optionsSection
                }
                .padding(FullioSpacing.md)
            }
            .background(Color.fullioBackground)
            .navigationTitle("Nuova transazione")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Annulla") { dismiss() }
                        .foregroundStyle(.fullioSecondaryText)
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Salva") { saveTransaction() }
                        .font(.body.weight(.semibold))
                        .foregroundStyle(.fullioDarkGreen)
                        .disabled(title.isEmpty || amount.isEmpty)
                }
            }
            .onAppear { amountFocused = true }
        }
    }

    // MARK: - Amount Section

    private var amountSection: some View {
        VStack(spacing: FullioSpacing.md) {
            Picker("Tipo", selection: $isIncome) {
                Text("Uscita").tag(false)
                Text("Entrata").tag(true)
            }
            .pickerStyle(.segmented)

            HStack(alignment: .firstTextBaseline, spacing: 4) {
                TextField("0", text: $amount)
                    .font(FullioFont.number(48))
                    .foregroundStyle(.fullioBlack)
                    .keyboardType(.decimalPad)
                    .multilineTextAlignment(.center)
                    .focused($amountFocused)

                Text("€")
                    .font(FullioFont.number(24))
                    .foregroundStyle(.fullioSecondaryText)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, FullioSpacing.lg)
        }
        .fullioCard()
    }

    // MARK: - Details Section

    private var detailsSection: some View {
        VStack(spacing: FullioSpacing.md) {
            FullioTextField(title: "Descrizione", text: $title, placeholder: "es. Spesa settimanale")
            FullioTextField(title: "Esercente", text: $merchant, placeholder: "es. Esselunga (opzionale)")

            VStack(alignment: .leading, spacing: FullioSpacing.sm) {
                Text("Categoria")
                    .font(FullioFont.caption())
                    .foregroundStyle(.fullioSecondaryText)

                categoryGrid
            }

            DatePicker("Data", selection: $date, displayedComponents: .date)
                .font(FullioFont.body())
                .tint(.fullioDarkGreen)
        }
        .fullioCard()
    }

    // MARK: - Category Grid

    private var categoryGrid: some View {
        let columns = Array(repeating: GridItem(.flexible(), spacing: FullioSpacing.sm), count: 4)
        let categories = TransactionCategory.allCases.filter {
            isIncome ? !$0.isExpense : $0.isExpense
        }

        return LazyVGrid(columns: columns, spacing: FullioSpacing.sm) {
            ForEach(categories) { cat in
                Button {
                    category = cat
                } label: {
                    VStack(spacing: 4) {
                        Image(systemName: cat.icon)
                            .font(.body)
                        Text(cat.rawValue)
                            .font(FullioFont.caption(10))
                            .lineLimit(1)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, FullioSpacing.sm)
                    .foregroundStyle(category == cat ? .white : .fullioDarkGreen)
                    .background(category == cat ? Color.fullioDarkGreen : Color.fullioLightGreen)
                    .clipShape(RoundedRectangle(cornerRadius: FullioRadius.sm))
                }
            }
        }
    }

    // MARK: - Options Section

    private var optionsSection: some View {
        VStack(spacing: FullioSpacing.md) {
            Toggle("Ricorrente", isOn: $isRecurring)
                .font(FullioFont.body())
                .tint(.fullioDarkGreen)

            if isRecurring {
                Toggle("Abbonamento", isOn: $isSubscription)
                    .font(FullioFont.body())
                    .tint(.fullioDarkGreen)
            }

            VStack(alignment: .leading, spacing: FullioSpacing.sm) {
                Text("Note (opzionale)")
                    .font(FullioFont.caption())
                    .foregroundStyle(.fullioSecondaryText)

                TextField("Aggiungi una nota...", text: $note, axis: .vertical)
                    .font(FullioFont.body())
                    .lineLimit(3)
                    .padding(FullioSpacing.sm)
                    .background(Color.fullioBackground)
                    .clipShape(RoundedRectangle(cornerRadius: FullioRadius.sm))
            }
        }
        .fullioCard()
    }

    // MARK: - Save

    private func saveTransaction() {
        guard let amountValue = Double(amount.replacingOccurrences(of: ",", with: ".")) else { return }

        let transaction = Transaction(
            amount: amountValue,
            title: title,
            merchant: merchant,
            category: category,
            date: date,
            isRecurring: isRecurring,
            isSubscription: isSubscription,
            note: note.isEmpty ? nil : note,
            isIncome: isIncome
        )

        modelContext.insert(transaction)
        dismiss()
    }
}

// MARK: - Custom Text Field

struct FullioTextField: View {
    let title: String
    @Binding var text: String
    var placeholder: String = ""

    var body: some View {
        VStack(alignment: .leading, spacing: FullioSpacing.sm) {
            Text(title)
                .font(FullioFont.caption())
                .foregroundStyle(.fullioSecondaryText)

            TextField(placeholder, text: $text)
                .font(FullioFont.body())
                .padding(FullioSpacing.sm)
                .background(Color.fullioBackground)
                .clipShape(RoundedRectangle(cornerRadius: FullioRadius.sm))
        }
    }
}

#Preview {
    AddTransactionView()
        .modelContainer(for: Transaction.self, inMemory: true)
}
