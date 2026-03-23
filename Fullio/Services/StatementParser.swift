import Foundation
import UniformTypeIdentifiers

// MARK: - Parsed Transaction (intermediate representation)

struct ParsedTransaction: Identifiable, Hashable {
    let id = UUID()
    var date: Date
    var amount: Double
    var title: String
    var merchant: String
    var isIncome: Bool
    var suggestedCategory: TransactionCategory
    var isSelected: Bool = true
    var rawLine: String?

    var formattedAmount: String {
        let prefix = isIncome ? "+" : "-"
        return "\(prefix)\(String(format: "%.2f", abs(amount)))€"
    }

    var formattedDate: String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "it_IT")
        formatter.dateFormat = "d MMM yyyy"
        return formatter.string(from: date)
    }

    func toTransaction() -> Transaction {
        Transaction(
            amount: abs(amount),
            title: title,
            merchant: merchant,
            category: suggestedCategory,
            date: date,
            isIncome: isIncome
        )
    }
}

// MARK: - Import Result

struct ImportResult {
    let transactions: [ParsedTransaction]
    let sourceFileName: String
    let detectedFormat: StatementFormat
    let parseErrors: [String]
    let totalLinesProcessed: Int
}

// MARK: - Statement Format

enum StatementFormat: String {
    case csv = "CSV"
    case ofx = "OFX"
    case qfx = "QFX"
    case qif = "QIF"
    case pdf = "PDF"
    case unknown = "Sconosciuto"

    var icon: String {
        switch self {
        case .csv: return "tablecells"
        case .ofx, .qfx: return "building.columns"
        case .qif: return "doc.text"
        case .pdf: return "doc.richtext"
        case .unknown: return "questionmark.circle"
        }
    }
}

// MARK: - Parser Protocol

protocol StatementParserProtocol {
    var supportedFormats: [StatementFormat] { get }
    func canParse(url: URL) -> Bool
    func parse(url: URL) throws -> ImportResult
}

// MARK: - Parser Errors

enum StatementParserError: LocalizedError {
    case fileNotFound
    case unreadableFile
    case unsupportedFormat
    case noTransactionsFound
    case invalidEncoding
    case parsingFailed(String)

    var errorDescription: String? {
        switch self {
        case .fileNotFound:
            return "File non trovato"
        case .unreadableFile:
            return "Impossibile leggere il file"
        case .unsupportedFormat:
            return "Formato non supportato"
        case .noTransactionsFound:
            return "Nessuna transazione trovata nel file"
        case .invalidEncoding:
            return "Codifica del file non valida"
        case .parsingFailed(let detail):
            return "Errore durante l'analisi: \(detail)"
        }
    }
}

// MARK: - Supported File Types

extension UTType {
    static let ofx = UTType(filenameExtension: "ofx") ?? .data
    static let qfx = UTType(filenameExtension: "qfx") ?? .data
    static let qif = UTType(filenameExtension: "qif") ?? .data
}
