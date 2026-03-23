import Foundation

final class QIFStatementParser: StatementParserProtocol {

    var supportedFormats: [StatementFormat] { [.qif] }

    func canParse(url: URL) -> Bool {
        url.pathExtension.lowercased() == "qif"
    }

    func parse(url: URL) throws -> ImportResult {
        let content = try readContent(url: url)
        let records = splitRecords(content)

        guard !records.isEmpty else {
            throw StatementParserError.noTransactionsFound
        }

        var transactions: [ParsedTransaction] = []
        var errors: [String] = []

        for (index, record) in records.enumerated() {
            guard let parsed = parseRecord(record) else {
                errors.append("Record \(index + 1): dati incompleti")
                continue
            }
            transactions.append(parsed)
        }

        guard !transactions.isEmpty else {
            throw StatementParserError.noTransactionsFound
        }

        return ImportResult(
            transactions: transactions.sorted { $0.date > $1.date },
            sourceFileName: url.lastPathComponent,
            detectedFormat: .qif,
            parseErrors: errors,
            totalLinesProcessed: records.count
        )
    }

    // MARK: - Helpers

    private func readContent(url: URL) throws -> String {
        let encodings: [String.Encoding] = [.utf8, .isoLatin1, .windowsCP1252]
        for encoding in encodings {
            if let content = try? String(contentsOf: url, encoding: encoding), !content.isEmpty {
                return content
            }
        }
        throw StatementParserError.invalidEncoding
    }

    private func splitRecords(_ content: String) -> [[String]] {
        let lines = content.components(separatedBy: .newlines)
        var records: [[String]] = []
        var current: [String] = []

        for line in lines {
            let trimmed = line.trimmingCharacters(in: .whitespacesAndNewlines)
            if trimmed == "^" {
                if !current.isEmpty {
                    records.append(current)
                    current = []
                }
            } else if trimmed.hasPrefix("!") {
                continue
            } else if !trimmed.isEmpty {
                current.append(trimmed)
            }
        }

        if !current.isEmpty {
            records.append(current)
        }

        return records
    }

    private func parseRecord(_ lines: [String]) -> ParsedTransaction? {
        var date: Date?
        var amount: Double?
        var payee = ""
        var memo = ""
        var category = ""
        var number = ""

        for line in lines {
            guard !line.isEmpty else { continue }
            let code = line.first!
            let value = String(line.dropFirst())

            switch code {
            case "D":
                date = parseQIFDate(value)
            case "T", "U":
                amount = parseQIFAmount(value)
            case "P":
                payee = value.trimmingCharacters(in: .whitespaces)
            case "M":
                memo = value.trimmingCharacters(in: .whitespaces)
            case "L":
                category = value.trimmingCharacters(in: .whitespaces)
            case "N":
                number = value.trimmingCharacters(in: .whitespaces)
            default:
                break
            }
        }

        guard let finalDate = date, let finalAmount = amount else { return nil }

        let description = payee.isEmpty ? (memo.isEmpty ? "Transazione \(number)".trimmingCharacters(in: .whitespaces) : memo) : payee
        let merchant = payee.isEmpty ? "" : memo

        let isIncome = finalAmount > 0 || CategoryMatcher.isLikelyIncome(description: description, amount: finalAmount)
        let detectedCategory = CategoryMatcher.match(description: description, merchant: merchant)

        return ParsedTransaction(
            date: finalDate,
            amount: abs(finalAmount),
            title: description.isEmpty ? "Transazione" : String(description.prefix(100)),
            merchant: String(merchant.prefix(50)),
            isIncome: isIncome,
            suggestedCategory: isIncome ? (detectedCategory.isExpense ? .income : detectedCategory) : detectedCategory
        )
    }

    private func parseQIFDate(_ string: String) -> Date? {
        let trimmed = string.trimmingCharacters(in: .whitespacesAndNewlines)

        let formats = [
            "M/d/yyyy", "MM/dd/yyyy", "M/d'yy", "MM/dd'yy",
            "d/M/yyyy", "dd/MM/yyyy", "d/M'yy", "dd/MM'yy",
            "M-d-yyyy", "MM-dd-yyyy",
            "d-M-yyyy", "dd-MM-yyyy",
            "yyyy-MM-dd", "yyyy/MM/dd"
        ]

        let locales = [Locale(identifier: "en_US_POSIX"), Locale(identifier: "it_IT")]
        let formatted = trimmed.replacingOccurrences(of: "'", with: "/")

        for locale in locales {
            let formatter = DateFormatter()
            formatter.locale = locale
            for format in formats {
                formatter.dateFormat = format
                if let date = formatter.date(from: formatted) {
                    return date
                }
            }
        }

        return nil
    }

    private func parseQIFAmount(_ string: String) -> Double? {
        var cleaned = string
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .replacingOccurrences(of: " ", with: "")

        let isNeg = cleaned.hasPrefix("-")
        cleaned = cleaned.replacingOccurrences(of: "-", with: "")

        if cleaned.contains(",") && cleaned.contains(".") {
            let lastComma = cleaned.lastIndex(of: ",")!
            let lastDot = cleaned.lastIndex(of: ".")!
            if lastComma > lastDot {
                cleaned = cleaned.replacingOccurrences(of: ".", with: "")
                cleaned = cleaned.replacingOccurrences(of: ",", with: ".")
            } else {
                cleaned = cleaned.replacingOccurrences(of: ",", with: "")
            }
        } else if cleaned.contains(",") {
            cleaned = cleaned.replacingOccurrences(of: ",", with: ".")
        }

        guard let value = Double(cleaned) else { return nil }
        return isNeg ? -value : value
    }
}
