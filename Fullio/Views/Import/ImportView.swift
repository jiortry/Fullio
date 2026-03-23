import SwiftUI
import SwiftData
import UniformTypeIdentifiers

struct ImportView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    @State private var importManager = StatementImportManager()
    @State private var showFilePicker = false
    @State private var showCategoryEditor: UUID?

    var body: some View {
        NavigationStack {
            ZStack {
                Color.fullioBackground.ignoresSafeArea()

                if importManager.isLoading {
                    loadingView
                } else if let result = importManager.importResult {
                    previewView(result)
                } else if importManager.showSuccess {
                    successView
                } else {
                    startView
                }
            }
            .navigationTitle("Importa estratto conto")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Chiudi") { dismiss() }
                        .foregroundStyle(.fullioSecondaryText)
                }
            }
            .fileImporter(
                isPresented: $showFilePicker,
                allowedContentTypes: StatementImportManager.supportedTypes,
                allowsMultipleSelection: false
            ) { result in
                handleFileSelection(result)
            }
            .alert("Errore", isPresented: .init(
                get: { importManager.error != nil },
                set: { if !$0 { importManager.error = nil } }
            )) {
                Button("OK") { importManager.error = nil }
            } message: {
                Text(importManager.error ?? "")
            }
        }
    }

    // MARK: - Start View

    private var startView: some View {
        ScrollView {
            VStack(spacing: FullioSpacing.lg) {
                Spacer(minLength: FullioSpacing.xl)

                VStack(spacing: FullioSpacing.md) {
                    Image(systemName: "doc.badge.arrow.up")
                        .font(.system(size: 56))
                        .foregroundStyle(.fullioDarkGreen)

                    Text("Importa le tue transazioni")
                        .font(FullioFont.headline())
                        .foregroundStyle(.fullioBlack)

                    Text("Seleziona un file dal tuo dispositivo.\nFullio legge automaticamente ogni formato.")
                        .font(FullioFont.body(14))
                        .foregroundStyle(.fullioSecondaryText)
                        .multilineTextAlignment(.center)
                        .lineSpacing(4)
                }

                Button {
                    showFilePicker = true
                } label: {
                    HStack(spacing: FullioSpacing.sm) {
                        Image(systemName: "folder.badge.plus")
                        Text("Scegli file")
                    }
                    .font(FullioFont.body().weight(.semibold))
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, FullioSpacing.md)
                    .background(Color.fullioDarkGreen)
                    .clipShape(RoundedRectangle(cornerRadius: FullioRadius.md))
                }
                .padding(.horizontal, FullioSpacing.xl)

                supportedFormatsSection
            }
            .padding(FullioSpacing.md)
        }
    }

    // MARK: - Supported Formats

    private var supportedFormatsSection: some View {
        VStack(alignment: .leading, spacing: FullioSpacing.md) {
            Text("Formati supportati")
                .font(FullioFont.headline(16))
                .foregroundStyle(.fullioBlack)

            ForEach(formatDescriptions, id: \.format) { item in
                HStack(spacing: FullioSpacing.md) {
                    Image(systemName: item.icon)
                        .font(.title3)
                        .foregroundStyle(.fullioDarkGreen)
                        .frame(width: 32)

                    VStack(alignment: .leading, spacing: 2) {
                        Text(item.format)
                            .font(FullioFont.body(14).weight(.medium))
                            .foregroundStyle(.fullioBlack)
                        Text(item.description)
                            .font(FullioFont.caption(12))
                            .foregroundStyle(.fullioSecondaryText)
                    }

                    Spacer()
                }
            }
        }
        .fullioCard()
    }

    private var formatDescriptions: [(format: String, description: String, icon: String)] {
        [
            ("CSV", "Esportazione da qualsiasi banca", "tablecells"),
            ("PDF", "Estratti conto in formato PDF", "doc.richtext"),
            ("OFX / QFX", "Standard bancario internazionale", "building.columns"),
            ("QIF", "Formato Quicken / Money", "doc.text"),
        ]
    }

    // MARK: - Loading View

    private var loadingView: some View {
        VStack(spacing: FullioSpacing.lg) {
            ProgressView()
                .scaleEffect(1.5)
                .tint(.fullioDarkGreen)

            Text("Analisi del file in corso...")
                .font(FullioFont.body())
                .foregroundStyle(.fullioSecondaryText)
        }
    }

    // MARK: - Preview View

    private func previewView(_ result: ImportResult) -> some View {
        VStack(spacing: 0) {
            previewHeader(result)

            ScrollView {
                LazyVStack(spacing: 0) {
                    ForEach(result.transactions) { transaction in
                        ImportTransactionRow(
                            transaction: transaction,
                            onToggle: { importManager.toggleTransaction(id: transaction.id) },
                            onCategoryTap: { showCategoryEditor = transaction.id }
                        )

                        if transaction.id != result.transactions.last?.id {
                            Divider()
                                .padding(.leading, 56)
                        }
                    }
                }
                .fullioCard(padding: FullioSpacing.sm)
                .padding(.horizontal, FullioSpacing.md)
                .padding(.bottom, 120)
            }

            importBar
        }
        .sheet(item: $showCategoryEditor) { transactionId in
            CategoryPickerSheet(
                currentCategory: result.transactions.first(where: { $0.id == transactionId })?.suggestedCategory ?? .other,
                onSelect: { category in
                    importManager.updateCategory(id: transactionId, category: category)
                    showCategoryEditor = nil
                }
            )
            .presentationDetents([.medium])
        }
    }

    private func previewHeader(_ result: ImportResult) -> some View {
        VStack(spacing: FullioSpacing.sm) {
            HStack {
                Image(systemName: result.detectedFormat.icon)
                    .foregroundStyle(.fullioDarkGreen)
                Text(result.sourceFileName)
                    .font(FullioFont.body(14).weight(.medium))
                    .foregroundStyle(.fullioBlack)
                    .lineLimit(1)
                Spacer()
                Text(result.detectedFormat.rawValue)
                    .font(FullioFont.caption(11))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background(Color.fullioDarkGreen)
                    .clipShape(Capsule())
            }

            HStack {
                Text("\(importManager.selectedCount)/\(importManager.totalCount) selezionate")
                    .font(FullioFont.caption())
                    .foregroundStyle(.fullioSecondaryText)
                Spacer()

                Button("Tutte") { importManager.selectAll() }
                    .font(FullioFont.caption())
                    .foregroundStyle(.fullioDarkGreen)

                Text("·")
                    .foregroundStyle(.fullioNeutral)

                Button("Nessuna") { importManager.deselectAll() }
                    .font(FullioFont.caption())
                    .foregroundStyle(.fullioWarning)
            }

            if !result.parseErrors.isEmpty {
                HStack(spacing: 4) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .font(.caption2)
                    Text("\(result.parseErrors.count) righe non analizzabili")
                        .font(FullioFont.caption(11))
                }
                .foregroundStyle(.orange)
                .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
        .padding(FullioSpacing.md)
        .background(Color.fullioCardBackground)
    }

    // MARK: - Import Bar

    private var importBar: some View {
        VStack(spacing: 0) {
            Divider()
            HStack(spacing: FullioSpacing.md) {
                VStack(alignment: .leading, spacing: 2) {
                    Text("\(importManager.selectedCount) transazioni")
                        .font(FullioFont.body(14).weight(.medium))
                        .foregroundStyle(.fullioBlack)
                    Text("Totale: \(String(format: "%.2f", importManager.selectedTotal))€")
                        .font(FullioFont.caption(12))
                        .foregroundStyle(.fullioSecondaryText)
                }

                Spacer()

                Button {
                    importManager.importSelected(into: modelContext)
                } label: {
                    Text("Importa")
                        .font(FullioFont.body().weight(.semibold))
                        .foregroundStyle(.white)
                        .padding(.horizontal, FullioSpacing.xl)
                        .padding(.vertical, FullioSpacing.sm + 2)
                        .background(importManager.selectedCount > 0 ? Color.fullioDarkGreen : Color.fullioNeutral)
                        .clipShape(Capsule())
                }
                .disabled(importManager.selectedCount == 0)
            }
            .padding(.horizontal, FullioSpacing.md)
            .padding(.vertical, FullioSpacing.md)
            .background(Color.fullioCardBackground)
        }
    }

    // MARK: - Success View

    private var successView: some View {
        VStack(spacing: FullioSpacing.lg) {
            Spacer()

            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 64))
                .foregroundStyle(.fullioSoftGreen)

            Text("Importazione completata!")
                .font(FullioFont.headline())
                .foregroundStyle(.fullioBlack)

            Text("\(importManager.importedCount) transazioni importate con successo")
                .font(FullioFont.body(14))
                .foregroundStyle(.fullioSecondaryText)

            VStack(spacing: FullioSpacing.sm) {
                Button {
                    dismiss()
                } label: {
                    Text("Chiudi")
                        .font(FullioFont.body().weight(.semibold))
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, FullioSpacing.md)
                        .background(Color.fullioDarkGreen)
                        .clipShape(RoundedRectangle(cornerRadius: FullioRadius.md))
                }

                Button {
                    importManager.reset()
                } label: {
                    Text("Importa altro file")
                        .font(FullioFont.body())
                        .foregroundStyle(.fullioDarkGreen)
                }
            }
            .padding(.horizontal, FullioSpacing.xl)

            Spacer()
        }
        .padding(FullioSpacing.md)
    }

    // MARK: - File Handling

    private func handleFileSelection(_ result: Result<[URL], Error>) {
        switch result {
        case .success(let urls):
            guard let url = urls.first else { return }
            importManager.parseFile(at: url)
        case .failure(let error):
            importManager.error = error.localizedDescription
        }
    }
}

// MARK: - Import Transaction Row

struct ImportTransactionRow: View {
    let transaction: ParsedTransaction
    let onToggle: () -> Void
    let onCategoryTap: () -> Void

    var body: some View {
        HStack(spacing: FullioSpacing.sm) {
            Button(action: onToggle) {
                Image(systemName: transaction.isSelected ? "checkmark.circle.fill" : "circle")
                    .font(.title3)
                    .foregroundStyle(transaction.isSelected ? .fullioDarkGreen : .fullioNeutral)
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(transaction.title)
                    .font(FullioFont.body(14).weight(.medium))
                    .foregroundStyle(transaction.isSelected ? .fullioBlack : .fullioNeutral)
                    .lineLimit(1)

                HStack(spacing: 4) {
                    if !transaction.merchant.isEmpty {
                        Text(transaction.merchant)
                            .font(FullioFont.caption(11))
                            .foregroundStyle(.fullioSecondaryText)
                            .lineLimit(1)
                    }

                    Text(transaction.formattedDate)
                        .font(FullioFont.caption(11))
                        .foregroundStyle(.fullioSecondaryText)
                }
            }

            Spacer()

            Button(action: onCategoryTap) {
                Image(systemName: transaction.suggestedCategory.icon)
                    .font(.caption)
                    .foregroundStyle(.fullioDarkGreen)
                    .padding(6)
                    .background(Color.fullioLightGreen)
                    .clipShape(Circle())
            }

            Text(transaction.formattedAmount)
                .font(FullioFont.smallNumber(14))
                .foregroundStyle(transaction.isIncome ? .fullioSoftGreen : .fullioBlack)
        }
        .padding(.horizontal, FullioSpacing.sm)
        .padding(.vertical, FullioSpacing.sm)
        .opacity(transaction.isSelected ? 1 : 0.5)
    }
}

// MARK: - Category Picker Sheet

struct CategoryPickerSheet: View {
    let currentCategory: TransactionCategory
    let onSelect: (TransactionCategory) -> Void

    var body: some View {
        NavigationStack {
            ScrollView {
                let columns = Array(repeating: GridItem(.flexible(), spacing: FullioSpacing.sm), count: 3)

                LazyVGrid(columns: columns, spacing: FullioSpacing.sm) {
                    ForEach(TransactionCategory.allCases) { cat in
                        Button {
                            onSelect(cat)
                        } label: {
                            VStack(spacing: 6) {
                                Image(systemName: cat.icon)
                                    .font(.title3)
                                Text(cat.rawValue)
                                    .font(FullioFont.caption(11))
                                    .lineLimit(1)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, FullioSpacing.md)
                            .foregroundStyle(currentCategory == cat ? .white : .fullioDarkGreen)
                            .background(currentCategory == cat ? Color.fullioDarkGreen : Color.fullioLightGreen)
                            .clipShape(RoundedRectangle(cornerRadius: FullioRadius.sm))
                        }
                    }
                }
                .padding(FullioSpacing.md)
            }
            .background(Color.fullioBackground)
            .navigationTitle("Categoria")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}

// MARK: - UUID Identifiable for Sheet

extension UUID: @retroactive Identifiable {
    public var id: UUID { self }
}

#Preview {
    ImportView()
        .modelContainer(for: Transaction.self, inMemory: true)
}
