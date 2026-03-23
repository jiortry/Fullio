import SwiftUI

// MARK: - Brand Colors

extension Color {
    static let fullioDarkGreen = Color(hex: "0F3D2E")
    static let fullioSoftGreen = Color(hex: "5FAF8F")
    static let fullioBeige = Color(hex: "F5F1E8")
    static let fullioBlack = Color(hex: "1C1C1C")
    static let fullioWarning = Color(hex: "E57373")
    static let fullioPositive = Color(hex: "5FAF8F")
    static let fullioNeutral = Color(hex: "B8B0A2")
    static let fullioCardBackground = Color.white
    static let fullioBackground = Color(hex: "F5F1E8")
    static let fullioSecondaryText = Color(hex: "8A8278")
    static let fullioLightGreen = Color(hex: "E8F5EE")
    static let fullioLightWarning = Color(hex: "FFF0F0")
    static let fullioLightBeige = Color(hex: "FAF8F4")
}

// Lets `.foregroundStyle(.fullio…)` and similar resolve when contextual type is `ShapeStyle`.
extension ShapeStyle where Self == Color {
    static var fullioDarkGreen: Color { Color.fullioDarkGreen }
    static var fullioSoftGreen: Color { Color.fullioSoftGreen }
    static var fullioBeige: Color { Color.fullioBeige }
    static var fullioBlack: Color { Color.fullioBlack }
    static var fullioWarning: Color { Color.fullioWarning }
    static var fullioPositive: Color { Color.fullioPositive }
    static var fullioNeutral: Color { Color.fullioNeutral }
    static var fullioCardBackground: Color { Color.fullioCardBackground }
    static var fullioBackground: Color { Color.fullioBackground }
    static var fullioSecondaryText: Color { Color.fullioSecondaryText }
    static var fullioLightGreen: Color { Color.fullioLightGreen }
    static var fullioLightWarning: Color { Color.fullioLightWarning }
    static var fullioLightBeige: Color { Color.fullioLightBeige }
}

extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: .alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 6:
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8:
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (255, 0, 0, 0)
        }
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}

// MARK: - Typography

struct FullioFont {
    static func title(_ size: CGFloat = 28) -> Font {
        .system(size: size, weight: .bold, design: .rounded)
    }

    static func headline(_ size: CGFloat = 20) -> Font {
        .system(size: size, weight: .semibold, design: .rounded)
    }

    static func body(_ size: CGFloat = 16) -> Font {
        .system(size: size, weight: .regular, design: .rounded)
    }

    static func caption(_ size: CGFloat = 13) -> Font {
        .system(size: size, weight: .medium, design: .rounded)
    }

    static func number(_ size: CGFloat = 36) -> Font {
        .system(size: size, weight: .bold, design: .rounded)
    }

    static func smallNumber(_ size: CGFloat = 20) -> Font {
        .system(size: size, weight: .semibold, design: .monospaced)
    }
}

// MARK: - Spacing

struct FullioSpacing {
    static let xs: CGFloat = 4
    static let sm: CGFloat = 8
    static let md: CGFloat = 16
    static let lg: CGFloat = 24
    static let xl: CGFloat = 32
    static let xxl: CGFloat = 48
}

// MARK: - Corner Radius

struct FullioRadius {
    static let sm: CGFloat = 12
    static let md: CGFloat = 16
    static let lg: CGFloat = 24
    static let xl: CGFloat = 32
    static let full: CGFloat = 100
}

// MARK: - Card Style Modifier

struct FullioCardStyle: ViewModifier {
    var padding: CGFloat = FullioSpacing.lg

    func body(content: Content) -> some View {
        content
            .padding(padding)
            .background(Color.fullioCardBackground)
            .clipShape(RoundedRectangle(cornerRadius: FullioRadius.lg))
            .shadow(color: .black.opacity(0.04), radius: 8, x: 0, y: 2)
    }
}

extension View {
    func fullioCard(padding: CGFloat = FullioSpacing.lg) -> some View {
        modifier(FullioCardStyle(padding: padding))
    }
}

// MARK: - Emotional Messages

struct EmotionalMessages {
    static func safeToSpendMessage(amount: Double, dailyBudget: Double) -> String {
        let ratio = amount / max(dailyBudget, 1)
        if ratio >= 1.0 {
            return "Oggi sei in ottima forma! Puoi stare tranquillo."
        } else if ratio >= 0.7 {
            return "Sei in linea, continua così."
        } else if ratio >= 0.4 {
            return "Attenzione, ma sei ancora in controllo."
        } else {
            return "Giornata stretta — piccoli gesti fanno la differenza."
        }
    }

    static func monthEndMessage(projected: Double) -> String {
        if projected > 0 {
            return "Se continui così, a fine mese risparmi \(Int(projected))€"
        } else {
            return "Attenzione: potresti chiudere il mese con \(Int(abs(projected)))€ in meno"
        }
    }

    static func weekendMessage(weekendSpending: Double, average: Double) -> String {
        if weekendSpending > average * 1.3 {
            return "Weekend sopra la media — niente panico, puoi recuperare"
        } else {
            return "Weekend sotto controllo, ottimo lavoro!"
        }
    }

    static func improvementMessage(thisWeek: Double, lastWeek: Double) -> String {
        if thisWeek < lastWeek {
            return "Stai migliorando! Questa settimana hai speso meno."
        } else if thisWeek == lastWeek {
            return "Costante come sempre — la stabilità è un superpotere."
        } else {
            return "Questa settimana hai speso un po' di più. Puoi migliorare."
        }
    }

    static let greetings: [String] = [
        "Ciao! Ecco il tuo riepilogo di oggi.",
        "Bentornato! Vediamo come va.",
        "Eccoti! Oggi si risparmia.",
        "Ciao! Sei sulla buona strada.",
    ]

    static var randomGreeting: String {
        greetings.randomElement() ?? greetings[0]
    }
}
