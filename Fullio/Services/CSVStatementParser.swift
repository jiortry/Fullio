import Foundation

final class CSVStatementParser: StatementParserProtocol {

    var supportedFormats: [StatementFormat] { [.csv] }

    func canParse(url: URL) -> Bool {
        url.pathExtension.lowercased() == "csv"
    }

    func parse(url: URL) throws -> ImportResult {
        let content = try readFileContent(url: url)
        let lines = content.components(separatedBy: .newlines).filter { !$0.trimmingCharacters(in: .whitespaces).isEmpty }

        guard lines.count >= 2 else {
            throw StatementParserError.noTransactionsFound
        }

        let delimiter = detectDelimiter(lines: lines)
        let headerRow = parseCSVLine(lines[0], delimiter: delimiter)

        if let mapping = detectColumnMapping(headers: headerRow) {
            return try parseWithMapping(lines: Array(lines.dropFirst()), delimiter: delimiter, mapping: mapping, fileName: url.lastPathComponent)
        }

        return try parseGenericCSV(lines: lines, delimiter: delimiter, fileName: url.lastPathComponent)
    }

    // MARK: - File Reading

    private func readFileContent(url: URL) throws -> String {
        let encodings: [String.Encoding] = [.utf8, .isoLatin1, .windowsCP1252, .macOSRoman]

        for encoding in encodings {
            if let content = try? String(contentsOf: url, encoding: encoding), !content.isEmpty {
                return content
            }
        }

        throw StatementParserError.invalidEncoding
    }

    // MARK: - Delimiter Detection

    private func detectDelimiter(lines: [String]) -> Character {
        let candidates: [Character] = [";", ",", "\t", "|"]
        let sample = Array(lines.prefix(5))

        var bestDelimiter: Character = ","
        var bestConsistency = 0

        for delimiter in candidates {
            let counts = sample.map { $0.filter { $0 == delimiter }.count }
            guard let first = counts.first, first > 0 else { continue }

            let consistent = counts.allSatisfy { $0 == first }
            if consistent && first > bestConsistency {
                bestConsistency = first
                bestDelimiter = delimiter
            }
        }

        return bestDelimiter
    }

    // MARK: - CSV Line Parsing (handles quoted fields)

    private func parseCSVLine(_ line: String, delimiter: Character) -> [String] {
        var fields: [String] = []
        var current = ""
        var inQuotes = false

        for char in line {
            if char == "\"" {
                inQuotes.toggle()
            } else if char == delimiter && !inQuotes {
                fields.append(current.trimmingCharacters(in: .whitespaces))
                current = ""
            } else {
                current.append(char)
            }
        }
        fields.append(current.trimmingCharacters(in: .whitespaces))
        return fields
    }

    // MARK: - Column Mapping

    struct ColumnMapping {
        var dateIndex: Int
        var amountIndex: Int
        var debitIndex: Int?
        var creditIndex: Int?
        var descriptionIndex: Int
        var merchantIndex: Int?
        var balanceIndex: Int?
        var currencyIndex: Int?
    }

    private func detectColumnMapping(headers: [String]) -> ColumnMapping? {
        let lower = headers.map { $0.lowercased().trimmingCharacters(in: .whitespacesAndNewlines) }

        var dateIdx: Int?
        var amountIdx: Int?
        var debitIdx: Int?
        var creditIdx: Int?
        var descIdx: Int?
        var merchantIdx: Int?

        for (i, h) in lower.enumerated() {
            if dateIdx == nil && matchesAny(h, ["data", "date", "data contabile", "data operazione",
                                                  "data registrazione", "booking date", "transaction date",
                                                  "started date", "completed date", "data valuta"]) {
                dateIdx = i
            }
            if matchesAny(h, ["importo", "amount", "ammontare", "valore", "somma",
                              "amount (eur)", "betrag", "montant"]) {
                amountIdx = i
            }
            if matchesAny(h, ["dare", "debit", "uscita", "uscite", "addebito", "soll"]) {
                debitIdx = i
            }
            if matchesAny(h, ["avere", "credit", "entrata", "entrate", "accredito", "haben"]) {
                creditIdx = i
            }
            if descIdx == nil && matchesAny(h, ["descrizione", "description", "causale", "dettagli",
                                                  "riferimento", "payment reference", "memo",
                                                  "oggetto", "motivo", "payee", "name",
                                                  "transaction type", "tipo"]) {
                descIdx = i
            }
            if merchantIdx == nil && matchesAny(h, ["esercente", "merchant", "payee", "beneficiario",
                                                      "destinatario", "ordinante"]) {
                merchantIdx = i
            }
        }

        guard let dIdx = dateIdx else { return nil }

        let aIdx = amountIdx ?? (debitIdx != nil || creditIdx != nil ? nil : nil)
        let dscIdx = descIdx ?? lower.firstIndex(where: { $0 != lower[dIdx] && !matchesAny($0, ["importo", "amount", "dare", "avere", "debit", "credit", "saldo", "balance", "valuta", "currency"]) })

        guard let finalDescIdx = dscIdx else { return nil }

        if amountIdx == nil && debitIdx == nil && creditIdx == nil { return nil }

        return ColumnMapping(
            dateIndex: dIdx,
            amountIndex: aIdx ?? 0,
            debitIndex: debitIdx,
            creditIndex: creditIdx,
            descriptionIndex: finalDescIdx,
            merchantIndex: merchantIdx
        )
    }

    private func matchesAny(_ value: String, _ targets: [String]) -> Bool {
        targets.contains { value == $0 || value.contains($0) }
    }

    // MARK: - Parse with Mapping

    private func parseWithMapping(lines: [String], delimiter: Character, mapping: ColumnMapping, fileName: String) throws -> ImportResult {
        var transactions: [ParsedTransaction] = []
        var errors: [String] = []

        for (index, line) in lines.enumerated() {
            let fields = parseCSVLine(line, delimiter: delimiter)
            let maxIdx = max(mapping.dateIndex, mapping.amountIndex,
                             mapping.debitIndex ?? 0, mapping.creditIndex ?? 0,
                             mapping.descriptionIndex, mapping.merchantIndex ?? 0)

            guard fields.count > maxIdx else {
                errors.append("Riga \(index + 2): colonne insufficienti")
                continue
            }

            guard let date = parseDate(fields[mapping.dateIndex]) else {
                errors.append("Riga \(index + 2): data non valida '\(fields[mapping.dateIndex])'")
                continue
            }

            var amount: Double = 0
            var isIncome = false

            if let debitIdx = mapping.debitIndex, let creditIdx = mapping.creditIndex {
                let debitStr = fields[debitIdx]
                let creditStr = fields[creditIdx]
                let debit = parseAmount(debitStr)
                let credit = parseAmount(creditStr)

                if credit > 0 {
                    amount = credit
                    isIncome = true
                } else {
                    amount = debit
                    isIncome = false
                }
            } else {
                amount = parseAmount(fields[mapping.amountIndex])
                isIncome = amount > 0
            }

            guard abs(amount) > 0.001 else { continue }

            let description = fields[mapping.descriptionIndex]
                .trimmingCharacters(in: .whitespacesAndNewlines)
            let merchant = mapping.merchantIndex.flatMap { fields.indices.contains($0) ? fields[$0] : nil }?
                .trimmingCharacters(in: .whitespacesAndNewlines) ?? ""

            let category = CategoryMatcher.match(description: description, merchant: merchant)
            if CategoryMatcher.isLikelyIncome(description: description, amount: amount) {
                isIncome = true
            }

            transactions.append(ParsedTransaction(
                date: date,
                amount: abs(amount),
                title: description.isEmpty ? "Transazione" : String(description.prefix(100)),
                merchant: String(merchant.prefix(50)),
                isIncome: isIncome,
                suggestedCategory: isIncome ? (category.isExpense ? .income : category) : category,
                rawLine: line
            ))
        }

        guard !transactions.isEmpty else {
            throw StatementParserError.noTransactionsFound
        }

        return ImportResult(
            transactions: transactions.sorted { $0.date > $1.date },
            sourceFileName: fileName,
            detectedFormat: .csv,
            parseErrors: errors,
            totalLinesProcessed: lines.count
        )
    }

    // MARK: - Generic CSV (no header or unrecognized header)

    private func parseGenericCSV(lines: [String], delimiter: Character, fileName: String) throws -> ImportResult {
        var transactions: [ParsedTransaction] = []
        var errors: [String] = []

        let hasHeader = !containsDate(parseCSVLine(lines[0], delimiter: delimiter))
        let dataLines = hasHeader ? Array(lines.dropFirst()) : lines

        for (index, line) in dataLines.enumerated() {
            let fields = parseCSVLine(line, delimiter: delimiter)
            guard fields.count >= 2 else { continue }

            var date: Date?
            var amount: Double?
            var description = ""

            for field in fields {
                if date == nil, let d = parseDate(field) {
                    date = d
                } else if amount == nil {
                    let parsed = parseAmount(field)
                    if abs(parsed) > 0.001 {
                        amount = parsed
                    } else if !field.isEmpty {
                        description += (description.isEmpty ? "" : " ") + field
                    }
                } else if !field.isEmpty {
                    description += (description.isEmpty ? "" : " ") + field
                }
            }

            guard let finalDate = date, let finalAmount = amount else {
                errors.append("Riga \(index + (hasHeader ? 2 : 1)): impossibile analizzare")
                continue
            }

            let isIncome = finalAmount > 0 || CategoryMatcher.isLikelyIncome(description: description, amount: finalAmount)
            let category = CategoryMatcher.match(description: description)

            transactions.append(ParsedTransaction(
                date: finalDate,
                amount: abs(finalAmount),
                title: description.isEmpty ? "Transazione" : String(description.prefix(100)),
                merchant: "",
                isIncome: isIncome,
                suggestedCategory: isIncome ? (category.isExpense ? .income : category) : category,
                rawLine: line
            ))
        }

        guard !transactions.isEmpty else {
            throw StatementParserError.noTransactionsFound
        }

        return ImportResult(
            transactions: transactions.sorted { $0.date > $1.date },
            sourceFileName: fileName,
            detectedFormat: .csv,
            parseErrors: errors,
            totalLinesProcessed: lines.count
        )
    }

    private func containsDate(_ fields: [String]) -> Bool {
        fields.contains { parseDate($0) != nil }
    }

    // MARK: - Date Parsing

    private func parseDate(_ string: String) -> Date? {
        let trimmed = string.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return nil }

        let formats = [
            "dd/MM/yyyy", "d/MM/yyyy", "dd/M/yyyy",
            "dd-MM-yyyy", "d-MM-yyyy",
            "dd.MM.yyyy", "d.MM.yyyy",
            "yyyy-MM-dd", "yyyy/MM/dd",
            "MM/dd/yyyy", "M/dd/yyyy",
            "dd/MM/yy", "d/MM/yy",
            "yyyy-MM-dd'T'HH:mm:ss",
            "yyyy-MM-dd HH:mm:ss",
            "dd MMM yyyy", "d MMM yyyy",
            "dd MMMM yyyy",
            "yyyyMMdd"
        ]

        let locales = [Locale(identifier: "it_IT"), Locale(identifier: "en_US")]

        for locale in locales {
            let formatter = DateFormatter()
            formatter.locale = locale
            for format in formats {
                formatter.dateFormat = format
                if let date = formatter.date(from: trimmed) {
                    if date > Date().addingTimeInterval(86400) { continue }
                    if date < Calendar.current.date(byAdding: .year, value: -10, to: Date())! { continue }
                    return date
                }
            }
        }

        return nil
    }

    // MARK: - Amount Parsing

    private func parseAmount(_ string: String) -> Double {
        var cleaned = string
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .replacingOccurrences(of: "€", with: "")
            .replacingOccurrences(of: "$", with: "")
            .replacingOccurrences(of: "£", with: "")
            .replacingOccurrences(of: "EUR", with: "")
            .replacingOccurrences(of: "USD", with: "")
            .replacingOccurrences(of: " ", with: "")
            .trimmingCharacters(in: .whitespaces)

        guard !cleaned.isEmpty else { return 0 }

        let isNegative = cleaned.hasPrefix("-") || cleaned.hasSuffix("-")
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
            let parts = cleaned.components(separatedBy: ",")
            if parts.count == 2 && (parts[1].count <= 2 || parts[1].count == 3) {
                cleaned = cleaned.replacingOccurrences(of: ",", with: ".")
            } else {
                cleaned = cleaned.replacingOccurrences(of: ",", with: "")
            }
        }

        guard let value = Double(cleaned) else { return 0 }
        return isNegative ? -value : value
    }
}
