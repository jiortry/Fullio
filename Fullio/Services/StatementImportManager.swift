import Foundation
import SwiftUI
import SwiftData
import UniformTypeIdentifiers

@Observable
final class StatementImportManager {

    var importResult: ImportResult?
    var isLoading = false
    var error: String?
    var importedCount = 0
    var showSuccess = false

    private let parsers: [StatementParserProtocol] = [
        CSVStatementParser(),
        OFXStatementParser(),
        QIFStatementParser(),
        PDFStatementParser()
    ]

    static let supportedTypes: [UTType] = [
        .commaSeparatedText,
        .pdf,
        .ofx,
        .qfx,
        .qif,
        .plainText,
        .data
    ]

    // MARK: - Parse File

    func parseFile(at url: URL) {
        isLoading = true
        error = nil
        importResult = nil

        let accessing = url.startAccessingSecurityScopedResource()
        defer {
            if accessing { url.stopAccessingSecurityScopedResource() }
        }

        do {
            guard let parser = parsers.first(where: { $0.canParse(url: url) }) else {
                let ext = url.pathExtension.lowercased()
                if ext == "txt" || ext == "csv" {
                    let csvParser = CSVStatementParser()
                    importResult = try csvParser.parse(url: url)
                } else {
                    throw StatementParserError.unsupportedFormat
                }
                isLoading = false
                return
            }

            importResult = try parser.parse(url: url)
        } catch let parseError as StatementParserError {
            error = parseError.errorDescription
        } catch {
            self.error = "Errore: \(error.localizedDescription)"
        }

        isLoading = false
    }

    // MARK: - Toggle Selection

    func toggleTransaction(id: UUID) {
        guard var result = importResult else { return }
        if let index = result.transactions.firstIndex(where: { $0.id == id }) {
            var updated = result.transactions
            updated[index].isSelected.toggle()
            importResult = ImportResult(
                transactions: updated,
                sourceFileName: result.sourceFileName,
                detectedFormat: result.detectedFormat,
                parseErrors: result.parseErrors,
                totalLinesProcessed: result.totalLinesProcessed
            )
        }
    }

    func selectAll() {
        guard let result = importResult else { return }
        let updated = result.transactions.map { t -> ParsedTransaction in
            var copy = t
            copy.isSelected = true
            return copy
        }
        importResult = ImportResult(
            transactions: updated,
            sourceFileName: result.sourceFileName,
            detectedFormat: result.detectedFormat,
            parseErrors: result.parseErrors,
            totalLinesProcessed: result.totalLinesProcessed
        )
    }

    func deselectAll() {
        guard let result = importResult else { return }
        let updated = result.transactions.map { t -> ParsedTransaction in
            var copy = t
            copy.isSelected = false
            return copy
        }
        importResult = ImportResult(
            transactions: updated,
            sourceFileName: result.sourceFileName,
            detectedFormat: result.detectedFormat,
            parseErrors: result.parseErrors,
            totalLinesProcessed: result.totalLinesProcessed
        )
    }

    func updateCategory(id: UUID, category: TransactionCategory) {
        guard let result = importResult else { return }
        if let index = result.transactions.firstIndex(where: { $0.id == id }) {
            var updated = result.transactions
            updated[index].suggestedCategory = category
            importResult = ImportResult(
                transactions: updated,
                sourceFileName: result.sourceFileName,
                detectedFormat: result.detectedFormat,
                parseErrors: result.parseErrors,
                totalLinesProcessed: result.totalLinesProcessed
            )
        }
    }

    // MARK: - Import to SwiftData

    func importSelected(into context: ModelContext) {
        guard let result = importResult else { return }

        let selected = result.transactions.filter { $0.isSelected }
        for parsed in selected {
            let transaction = parsed.toTransaction()
            context.insert(transaction)
        }

        importedCount = selected.count
        showSuccess = true
        importResult = nil
    }

    // MARK: - Stats

    var selectedCount: Int {
        importResult?.transactions.filter { $0.isSelected }.count ?? 0
    }

    var totalCount: Int {
        importResult?.transactions.count ?? 0
    }

    var selectedTotal: Double {
        importResult?.transactions.filter { $0.isSelected }.reduce(0) { $0 + $1.amount } ?? 0
    }

    func reset() {
        importResult = nil
        isLoading = false
        error = nil
        importedCount = 0
        showSuccess = false
    }
}
