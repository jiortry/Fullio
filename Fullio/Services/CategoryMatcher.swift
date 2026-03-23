import Foundation

struct CategoryMatcher {

    // MARK: - Keyword Map

    private static let categoryKeywords: [TransactionCategory: [String]] = [
        .food: [
            "spesa", "supermercato", "esselunga", "coop", "conad", "lidl", "eurospin",
            "carrefour", "pam", "despar", "simply", "aldi", "penny", "md discount",
            "ristorante", "pizzeria", "trattoria", "osteria", "bar", "caffè", "caffe",
            "mcdonald", "burger king", "kfc", "subway", "starbucks", "domino",
            "deliveroo", "glovo", "just eat", "uber eats", "foodora",
            "panetteria", "macelleria", "pescheria", "gelateria", "pasticceria",
            "pranzo", "cena", "colazione", "cornetto", "panino", "pizza",
            "grocery", "food", "restaurant", "bakery"
        ],
        .transport: [
            "benzina", "carburante", "diesel", "eni", "q8", "ip", "total", "shell",
            "autostrada", "pedaggio", "telepass", "parcheggio", "parking",
            "taxi", "uber", "bolt", "freenow", "cabify", "lyft",
            "treno", "trenitalia", "italo", "frecciarossa",
            "metro", "atm", "atac", "autobus", "bus",
            "aereo", "volo", "ryanair", "easyjet", "alitalia", "ita airways",
            "car sharing", "enjoy", "sharenow", "blablacar",
            "fuel", "petrol", "gasoline", "transport"
        ],
        .entertainment: [
            "cinema", "teatro", "concerto", "museo", "mostra",
            "aperitivo", "spritz", "cocktail", "pub", "discoteca", "club",
            "gioco", "gaming", "playstation", "xbox", "nintendo", "steam",
            "ticketone", "ticketmaster", "eventbrite",
            "svago", "divertimento", "entertainment", "movie"
        ],
        .shopping: [
            "amazon", "ebay", "zalando", "asos", "shein", "zara", "h&m",
            "primark", "bershka", "pull & bear", "stradivarius",
            "mediaworld", "unieuro", "trony", "euronics",
            "ikea", "leroy merlin", "bricocenter", "obi",
            "decathlon", "cisalfa", "foot locker", "nike", "adidas",
            "apple", "samsung", "huawei",
            "scarpe", "vestiti", "abbigliamento", "shopping",
            "aliexpress", "wish", "temu"
        ],
        .health: [
            "farmacia", "parafarmacia", "medicina", "medico", "dottore", "dott",
            "ospedale", "clinica", "ambulatorio", "laboratorio", "analisi",
            "dentista", "oculista", "fisioterapia", "psicologo",
            "palestra", "gym", "fitness", "yoga", "pilates",
            "pharmacy", "doctor", "hospital", "health"
        ],
        .bills: [
            "bolletta", "enel", "eni gas", "a2a", "acea", "iren", "hera",
            "edison", "sorgenia", "illumia",
            "acqua", "gas", "luce", "elettricità", "rifiuti", "tari",
            "telefono", "tim", "vodafone", "wind", "tre", "iliad", "fastweb", "ho.",
            "internet", "fibra", "adsl", "wifi",
            "assicurazione", "rca", "polizza",
            "condominio", "spese condominiali",
            "utility", "bill", "electric", "water", "insurance"
        ],
        .subscriptions: [
            "netflix", "spotify", "disney+", "disney plus", "amazon prime",
            "apple tv", "apple music", "icloud", "apple one",
            "dazn", "now tv", "sky", "paramount",
            "youtube premium", "twitch", "crunchyroll",
            "adobe", "microsoft 365", "office",
            "chatgpt", "openai", "copilot",
            "gym pass", "classpass",
            "subscription", "abbonamento", "rinnovo"
        ],
        .home: [
            "affitto", "mutuo", "rata mutuo", "canone",
            "mobili", "arredamento", "casa", "home",
            "pulizia", "detersivo", "sapone",
            "manutenzione", "idraulico", "elettricista",
            "rent", "mortgage", "furniture"
        ],
        .education: [
            "libro", "libri", "book", "ebook", "kindle", "audible",
            "corso", "corsi", "udemy", "coursera", "skillshare", "masterclass",
            "università", "scuola", "college", "university",
            "formazione", "training", "workshop", "seminario",
            "education", "learning", "study"
        ],
        .travel: [
            "hotel", "booking", "airbnb", "trivago", "expedia",
            "valigia", "viaggio", "vacanza", "holiday",
            "agenzia viaggi", "tour", "escursione",
            "noleggio auto", "rent a car", "hertz", "avis", "europcar",
            "travel", "trip", "flight"
        ],
        .transfers: [
            "bonifico", "giroconto", "trasferimento", "transfer",
            "paypal", "satispay", "bancomat pay",
            "ricarica", "prelievo", "versamento",
            "wire", "sepa"
        ],
        .salary: [
            "stipendio", "salario", "retribuzione", "busta paga",
            "compenso", "onorario", "parcella",
            "salary", "payroll", "wage"
        ],
        .income: [
            "rimborso", "cashback", "refund",
            "dividendo", "interessi", "cedola",
            "vendita", "incasso",
            "income", "revenue", "dividend", "interest"
        ]
    ]

    // MARK: - Match

    static func match(description: String, merchant: String = "") -> TransactionCategory {
        let combined = "\(description) \(merchant)".lowercased()

        var bestMatch: TransactionCategory = .other
        var bestScore = 0

        for (category, keywords) in categoryKeywords {
            var score = 0
            for keyword in keywords {
                if combined.contains(keyword) {
                    score += keyword.count
                }
            }
            if score > bestScore {
                bestScore = score
                bestMatch = category
            }
        }

        return bestMatch
    }

    static func isLikelyIncome(description: String, amount: Double) -> Bool {
        if amount > 0 { return true }

        let desc = description.lowercased()
        let incomeKeywords = [
            "stipendio", "salario", "salary", "payroll",
            "rimborso", "refund", "cashback",
            "dividendo", "dividend", "interessi", "interest",
            "vendita", "incasso", "accredito", "versamento",
            "bonifico in entrata", "income", "credit"
        ]
        return incomeKeywords.contains { desc.contains($0) }
    }
}
