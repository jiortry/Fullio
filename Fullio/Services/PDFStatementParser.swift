import Foundation
import PDFKit

final class PDFStatementParser: StatementParserProtocol {

    var supportedFormats: [StatementFormat] { [.pdf] }

    func canParse(url: URL) -> Bool {
        url.pathExtension.lowercased() == "pdf"
    }

    func parse(url: URL) throws -> ImportResult {
        guard let document = PDFDocument(url: url) else {
            throw StatementParserError.unreadableFile
        }

        var fullText = ""
        for i in 0..<document.pageCount {
            if let page = document.page(at: i), let text = page.string {
                fullText += text + "\n"
            }
        }

        guard !fullText.isEmpty else {
            throw StatementParserError.parsingFailed("Impossibile estrarre testo dal PDF")
        }

        let lines = fullText.components(separatedBy: .newlines)
            .map { $0.trimmingCharacters(in: .whitespaces) }
            .filter { !$0.isEmpty }

        var transactions: [ParsedTransaction] = []
        var errors: [String] = []
        var processedLines = 0

        var i = 0
        while i < lines.count {
            processedLines += 1
            let line = lines[i]

            if let parsed = parseSingleLine(line) {
                transactions.append(parsed)
                i += 1
                continue
            }

            if i + 1 < lines.count {
                let combined = line + " " + lines[i + 1]
                if let parsed = parseSingleLine(combined) {
                    transactions.append(parsed)
                    i += 2
                    continue
                }
            }

            if i + 2 < lines.count {
                let combined = line + " " + lines[i + 1] + " " + lines[i + 2]
                if let parsed = parseSingleLine(combined) {
                    transactions.append(parsed)
                    i += 3
                    continue
                }
            }

            i += 1
        }

        guard !transactions.isEmpty else {
            throw StatementParserError.noTransactionsFound
        }

        return ImportResult(
            transactions: transactions.sorted { $0.date > $1.date },
            sourceFileName: url.lastPathComponent,
            detectedFormat: .pdf,
            parseErrors: errors,
            totalLinesProcessed: processedLines
        )
    }

    // MARK: - Line Parsing

    private func parseSingleLine(_ line: String) -> ParsedTransaction? {
        let patterns: [(regex: String, dateGroup: Int, descGroup: Int, amountGroup: Int)] = [
            // dd/MM/yyyy Description -1.234,56 or +1.234,56
            (#"(\d{1,2}[/.\-]\d{1,2}[/.\-]\d{2,4})\s+(.+?)\s+([+-]?\s*[\d.,]+(?:\s*€)?)\s*$"#, 1, 2, 3),
            // dd/MM/yyyy dd/MM/yyyy Description Amount (date valuta + date contabile)
            (#"(\d{1,2}[/.\-]\d{1,2}[/.\-]\d{2,4})\s+\d{1,2}[/.\-]\d{1,2}[/.\-]\d{2,4}\s+(.+?)\s+([+-]?\s*[\d.,]+(?:\s*€)?)\s*$"#, 1, 2, 3),
            // dd/MM Description Amount
            (#"(\d{1,2}[/.\-]\d{1,2})\s+(.+?)\s+([+-]?\s*[\d.,]+(?:\s*€)?)\s*$"#, 1, 2, 3),
            // yyyy-MM-dd Description Amount
            (#"(\d{4}[/.\-]\d{1,2}[/.\-]\d{1,2})\s+(.+?)\s+([+-]?\s*[\d.,]+(?:\s*€)?)\s*$"#, 1, 2, 3),
        ]

        for pattern in patterns {
            guard let regex = try? NSRegularExpression(pattern: pattern.regex),
                  let match = regex.firstMatch(in: line, range: NSRange(line.startIndex..., in: line)) else {
                continue
            }

            guard let dateRange = Range(match.range(at: pattern.dateGroup), in: line),
                  let descRange = Range(match.range(at: pattern.descGroup), in: line),
                  let amountRange = Range(match.range(at: pattern.amountGroup), in: line) else {
                continue
            }

            let dateStr = String(line[dateRange])
            let description = String(line[descRange]).trimmingCharacters(in: .whitespaces)
            // Esclude righe spurie estratte dal PDF (es. "1 /", "2 /" da tabelle o numerazione).
            guard !description.contains("/") else { continue }
            let amountStr = String(line[amountRange])

            guard let date = parseDate(dateStr),
                  let amount = parseAmount(amountStr),
                  abs(amount) >= 0.01 else {
                continue
            }

            guard description.count >= 2 else { continue }

            let isIncome = amount > 0 || CategoryMatcher.isLikelyIncome(description: description, amount: amount)
            let category = CategoryMatcher.match(description: description)

            return ParsedTransaction(
                date: date,
                amount: abs(amount),
                title: String(description.prefix(100)),
                merchant: "",
                isIncome: isIncome,
                suggestedCategory: isIncome ? (category.isExpense ? .income : category) : category,
                rawLine: line
            )
        }

        return nil
    }

    // MARK: - Date Parsing

    private func parseDate(_ string: String) -> Date? {
        let trimmed = string.trimmingCharacters(in: .whitespacesAndNewlines)

        let formats = [
            "dd/MM/yyyy", "d/MM/yyyy", "dd/M/yyyy", "d/M/yyyy",
            "dd-MM-yyyy", "d-MM-yyyy",
            "dd.MM.yyyy", "d.MM.yyyy",
            "yyyy-MM-dd", "yyyy/MM/dd",
            "dd/MM/yy", "d/MM/yy",
            "dd/MM", "d/MM", "dd/M", "d/M"
        ]

        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "it_IT")

        for format in formats {
            formatter.dateFormat = format
            if let date = formatter.date(from: trimmed) {
                if format.contains("yyyy") || format.contains("yy") {
                    if date > Date().addingTimeInterval(86400 * 30) { continue }
                    return date
                } else {
                    var components = Calendar.current.dateComponents([.day, .month], from: date)
                    components.year = Calendar.current.component(.year, from: Date())
                    return Calendar.current.date(from: components)
                }
            }
        }

        return nil
    }

    // MARK: - Amount Parsing

    private func parseAmount(_ string: String) -> Double? {
        var cleaned = string
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .replacingOccurrences(of: "€", with: "")
            .replacingOccurrences(of: " ", with: "")

        guard !cleaned.isEmpty else { return nil }

        let isNegative = cleaned.hasPrefix("-")
        cleaned = cleaned.replacingOccurrences(of: "+", with: "")
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

        guard let value = Double(cleaned), value > 0 else { return nil }
        return isNegative ? -value : value
    }
}
