import Foundation

final class OFXStatementParser: StatementParserProtocol {

    var supportedFormats: [StatementFormat] { [.ofx, .qfx] }

    func canParse(url: URL) -> Bool {
        let ext = url.pathExtension.lowercased()
        return ext == "ofx" || ext == "qfx"
    }

    func parse(url: URL) throws -> ImportResult {
        let content = try readContent(url: url)
        let format: StatementFormat = url.pathExtension.lowercased() == "qfx" ? .qfx : .ofx

        let transactionBlocks = extractBlocks(from: content, tag: "STMTTRN")

        guard !transactionBlocks.isEmpty else {
            throw StatementParserError.noTransactionsFound
        }

        var transactions: [ParsedTransaction] = []
        var errors: [String] = []

        for (index, block) in transactionBlocks.enumerated() {
            guard let dateStr = extractValue(from: block, tag: "DTPOSTED"),
                  let date = parseOFXDate(dateStr),
                  let amountStr = extractValue(from: block, tag: "TRNAMT"),
                  let amount = parseOFXAmount(amountStr) else {
                errors.append("Blocco \(index + 1): dati incompleti")
                continue
            }

            let name = extractValue(from: block, tag: "NAME") ?? ""
            let memo = extractValue(from: block, tag: "MEMO") ?? ""
            let trnType = extractValue(from: block, tag: "TRNTYPE") ?? ""

            let description = name.isEmpty ? memo : name
            let merchant = name.isEmpty ? "" : memo

            let isIncome = amount > 0 || trnType.uppercased() == "CREDIT" || trnType.uppercased() == "DEP"
            let category = CategoryMatcher.match(description: description, merchant: merchant)

            transactions.append(ParsedTransaction(
                date: date,
                amount: abs(amount),
                title: description.isEmpty ? "Transazione \(trnType)" : String(description.prefix(100)),
                merchant: String(merchant.prefix(50)),
                isIncome: isIncome,
                suggestedCategory: isIncome ? (category.isExpense ? .income : category) : category
            ))
        }

        guard !transactions.isEmpty else {
            throw StatementParserError.noTransactionsFound
        }

        return ImportResult(
            transactions: transactions.sorted { $0.date > $1.date },
            sourceFileName: url.lastPathComponent,
            detectedFormat: format,
            parseErrors: errors,
            totalLinesProcessed: transactionBlocks.count
        )
    }

    // MARK: - Helpers

    private func readContent(url: URL) throws -> String {
        let encodings: [String.Encoding] = [.utf8, .isoLatin1, .windowsCP1252, .ascii]
        for encoding in encodings {
            if let content = try? String(contentsOf: url, encoding: encoding), !content.isEmpty {
                return content
            }
        }
        throw StatementParserError.invalidEncoding
    }

    private func extractBlocks(from content: String, tag: String) -> [String] {
        var blocks: [String] = []
        let openTag = "<\(tag)>"
        let closeTag = "</\(tag)>"

        var searchRange = content.startIndex..<content.endIndex

        while let openRange = content.range(of: openTag, range: searchRange) {
            if let closeRange = content.range(of: closeTag, range: openRange.upperBound..<content.endIndex) {
                let block = String(content[openRange.upperBound..<closeRange.lowerBound])
                blocks.append(block)
                searchRange = closeRange.upperBound..<content.endIndex
            } else {
                let remaining = String(content[openRange.upperBound..<content.endIndex])
                if let nextOpen = remaining.range(of: openTag) {
                    blocks.append(String(remaining[remaining.startIndex..<nextOpen.lowerBound]))
                } else {
                    blocks.append(remaining)
                }
                break
            }
        }

        if blocks.isEmpty {
            let sgmlBlocks = extractSGMLBlocks(from: content, tag: tag)
            return sgmlBlocks
        }

        return blocks
    }

    private func extractSGMLBlocks(from content: String, tag: String) -> [String] {
        let openTag = "<\(tag)>"
        var blocks: [String] = []
        let lines = content.components(separatedBy: .newlines)
        var currentBlock: [String] = []
        var inBlock = false

        for line in lines {
            let trimmed = line.trimmingCharacters(in: .whitespaces)
            if trimmed.uppercased().hasPrefix(openTag.uppercased()) {
                if inBlock && !currentBlock.isEmpty {
                    blocks.append(currentBlock.joined(separator: "\n"))
                }
                currentBlock = []
                inBlock = true
            } else if inBlock {
                if trimmed.hasPrefix("</\(tag)>") {
                    blocks.append(currentBlock.joined(separator: "\n"))
                    currentBlock = []
                    inBlock = false
                } else {
                    currentBlock.append(trimmed)
                }
            }
        }

        if inBlock && !currentBlock.isEmpty {
            blocks.append(currentBlock.joined(separator: "\n"))
        }

        return blocks
    }

    private func extractValue(from block: String, tag: String) -> String? {
        let patterns = [
            "<\(tag)>([^<\\n]+)",
            "<\(tag)>\\s*([^<\\n]+)"
        ]

        for pattern in patterns {
            if let regex = try? NSRegularExpression(pattern: pattern, options: .caseInsensitive),
               let match = regex.firstMatch(in: block, range: NSRange(block.startIndex..., in: block)),
               let range = Range(match.range(at: 1), in: block) {
                let value = String(block[range]).trimmingCharacters(in: .whitespacesAndNewlines)
                if !value.isEmpty { return value }
            }
        }

        return nil
    }

    private func parseOFXDate(_ string: String) -> Date? {
        let cleaned = string.trimmingCharacters(in: .whitespacesAndNewlines)
        let dateOnly = String(cleaned.prefix(8))

        let formatter = DateFormatter()
        formatter.dateFormat = "yyyyMMdd"
        formatter.locale = Locale(identifier: "en_US_POSIX")
        return formatter.date(from: dateOnly)
    }

    private func parseOFXAmount(_ string: String) -> Double? {
        var cleaned = string
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .replacingOccurrences(of: ",", with: ".")
            .replacingOccurrences(of: " ", with: "")

        let isNeg = cleaned.hasPrefix("-")
        cleaned = cleaned.replacingOccurrences(of: "+", with: "")

        let dots = cleaned.filter { $0 == "." }.count
        if dots > 1 {
            let parts = cleaned.components(separatedBy: ".")
            cleaned = parts.dropLast().joined() + "." + (parts.last ?? "")
        }

        guard let val = Double(cleaned) else { return nil }
        return isNeg ? val : val
    }
}
