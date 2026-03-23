import SwiftUI
import SwiftData

struct AddGoalView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    @State private var name = ""
    @State private var targetAmount = ""
    @State private var hasDeadline = false
    @State private var deadline = Calendar.current.date(byAdding: .month, value: 3, to: .now) ?? .now
    @State private var selectedIcon = "star.fill"

    private let iconOptions = [
        "star.fill", "airplane", "car.fill", "house.fill",
        "laptopcomputer", "iphone", "gift.fill", "heart.fill",
        "shield.fill", "graduationcap.fill", "beach.umbrella.fill", "trophy.fill",
        "camera.fill", "gamecontroller.fill", "bicycle", "tshirt.fill",
    ]

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: FullioSpacing.lg) {
                    iconSection
                    detailsSection

                    if hasDeadline, let target = Double(targetAmount.replacingOccurrences(of: ",", with: ".")), target > 0 {
                        previewSection(target: target)
                    }
                }
                .padding(FullioSpacing.md)
            }
            .background(Color.fullioBackground)
            .navigationTitle("Nuovo obiettivo")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Annulla") { dismiss() }
                        .foregroundStyle(.fullioSecondaryText)
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Crea") { saveGoal() }
                        .font(.body.weight(.semibold))
                        .foregroundStyle(.fullioDarkGreen)
                        .disabled(name.isEmpty || targetAmount.isEmpty)
                }
            }
        }
    }

    // MARK: - Icon Section

    private var iconSection: some View {
        VStack(spacing: FullioSpacing.md) {
            Circle()
                .fill(Color.fullioLightGreen)
                .frame(width: 72, height: 72)
                .overlay {
                    Image(systemName: selectedIcon)
                        .font(.title)
                        .foregroundStyle(.fullioDarkGreen)
                }

            let columns = Array(repeating: GridItem(.flexible()), count: 8)
            LazyVGrid(columns: columns, spacing: FullioSpacing.sm) {
                ForEach(iconOptions, id: \.self) { icon in
                    Button {
                        selectedIcon = icon
                    } label: {
                        Image(systemName: icon)
                            .font(.body)
                            .frame(width: 36, height: 36)
                            .foregroundStyle(selectedIcon == icon ? .white : .fullioDarkGreen)
                            .background(selectedIcon == icon ? Color.fullioDarkGreen : Color.fullioLightGreen)
                            .clipShape(Circle())
                    }
                }
            }
        }
        .fullioCard()
    }

    // MARK: - Details Section

    private var detailsSection: some View {
        VStack(spacing: FullioSpacing.md) {
            FullioTextField(title: "Nome obiettivo", text: $name, placeholder: "es. Vacanza estiva")

            VStack(alignment: .leading, spacing: FullioSpacing.sm) {
                Text("Quanto vuoi risparmiare?")
                    .font(FullioFont.caption())
                    .foregroundStyle(.fullioSecondaryText)

                HStack(alignment: .firstTextBaseline) {
                    TextField("0", text: $targetAmount)
                        .font(FullioFont.number(36))
                        .keyboardType(.decimalPad)

                    Text("€")
                        .font(FullioFont.number(20))
                        .foregroundStyle(.fullioSecondaryText)
                }
            }

            Toggle("Imposta scadenza", isOn: $hasDeadline)
                .font(FullioFont.body())
                .tint(.fullioDarkGreen)

            if hasDeadline {
                DatePicker("Entro il", selection: $deadline, in: Date()..., displayedComponents: .date)
                    .font(FullioFont.body())
                    .tint(.fullioDarkGreen)
            }
        }
        .fullioCard()
    }

    // MARK: - Preview Section

    private func previewSection(target: Double) -> some View {
        let days = Calendar.current.dateComponents([.day], from: .now, to: deadline).day ?? 90
        let dailyNeeded = days > 0 ? target / Double(days) : 0
        let monthlyNeeded = dailyNeeded * 30

        return VStack(alignment: .leading, spacing: FullioSpacing.sm) {
            Text("Per raggiungere l'obiettivo")
                .font(FullioFont.headline(16))
                .foregroundStyle(.fullioBlack)

            HStack(spacing: FullioSpacing.lg) {
                VStack {
                    Text("\(String(format: "%.1f", dailyNeeded))€")
                        .font(FullioFont.headline())
                        .foregroundStyle(.fullioDarkGreen)
                    Text("al giorno")
                        .font(FullioFont.caption(11))
                        .foregroundStyle(.fullioSecondaryText)
                }

                VStack {
                    Text("\(Int(monthlyNeeded))€")
                        .font(FullioFont.headline())
                        .foregroundStyle(.fullioDarkGreen)
                    Text("al mese")
                        .font(FullioFont.caption(11))
                        .foregroundStyle(.fullioSecondaryText)
                }
            }
            .frame(maxWidth: .infinity)
        }
        .fullioCard()
    }

    // MARK: - Save

    private func saveGoal() {
        guard let target = Double(targetAmount.replacingOccurrences(of: ",", with: ".")) else { return }

        let goal = SavingsGoal(
            name: name,
            targetAmount: target,
            deadline: hasDeadline ? deadline : nil,
            icon: selectedIcon
        )

        modelContext.insert(goal)
        dismiss()
    }
}

#Preview {
    AddGoalView()
        .modelContainer(for: SavingsGoal.self, inMemory: true)
}
