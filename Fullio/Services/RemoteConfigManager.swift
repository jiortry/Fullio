import Foundation
import SwiftUI

// MARK: - Remote Config Models

struct RemoteVersion: Codable {
    let version: String
    let build: Int
    let updatedAt: String
    let changelog: String
}

struct RemoteThemeColors: Codable {
    let darkGreen: String
    let softGreen: String
    let beige: String
    let black: String
    let warning: String
    let positive: String
    let neutral: String
    let cardBackground: String
    let background: String
    let secondaryText: String
    let lightGreen: String
    let lightWarning: String
    let lightBeige: String
}

struct RemoteThemeFont: Codable {
    let size: CGFloat
    let weight: String
    let design: String
}

struct RemoteTheme: Codable {
    let colors: RemoteThemeColors
    let fonts: [String: RemoteThemeFont]
    let spacing: [String: CGFloat]
    let radius: [String: CGFloat]
}

struct RemoteCategory: Codable {
    let key: String
    let label: String
    let icon: String
    let isExpense: Bool
}

struct RemoteCategoriesConfig: Codable {
    let categories: [RemoteCategory]
}

struct RemoteFeaturesConfig: Codable {
    let enableInsights: Bool
    let enableGoals: Bool
    let enableImport: Bool
    let enableProfile: Bool
    let enablePartnerMode: Bool
    let enableNotifications: Bool
    let enableWeeklyReport: Bool
    let enableSubscriptionAlert: Bool
    let enableImpulseWarning: Bool
    let enableSpendingStreaks: Bool
    let maxGoals: Int
    let maxTransactionsPerImport: Int
    let insightRefreshIntervalMinutes: Int
}

struct RemoteFullConfig: Codable {
    let version: RemoteVersion
    let theme: RemoteTheme
    let categories: RemoteCategoriesConfig
    let strings: RemoteStrings
    let features: RemoteFeaturesConfig
}

struct RemoteStrings: Codable {
    let greetings: [String]
    let emotionalMessages: EmotionalMessagesConfig
    let tabs: TabsConfig
    let spenderProfiles: [String: SpenderProfileConfig]
}

struct EmotionalMessagesConfig: Codable {
    let safeToSpend: [String: String]
    let monthEnd: [String: String]
    let weekend: [String: String]
    let improvement: [String: String]
}

struct TabsConfig: Codable {
    let home: String
    let activity: String
    let goals: String
    let insights: String
    let profile: String
}

struct SpenderProfileConfig: Codable {
    let label: String
    let description: String
    let icon: String
}

// MARK: - Remote Config Manager

@Observable
final class RemoteConfigManager {
    static let shared = RemoteConfigManager()

    /// URL del deploy Vercel (stessa repo, rootDirectory `web`). Sostituisci con il dominio del progetto.
    #if DEBUG
    var baseURL = "http://127.0.0.1:3000"
    #else
    var baseURL = "https://TUO-PROGETTO.vercel.app"
    #endif

    private(set) var remoteVersion: RemoteVersion?
    private(set) var isCheckingForUpdate = false
    private(set) var isDownloading = false
    private(set) var downloadProgress: Double = 0
    private(set) var lastError: String?

    var updateAvailable = false

    var localVersion: String {
        get { UserDefaults.standard.string(forKey: "fullio_config_version") ?? "0.0.0" }
        set { UserDefaults.standard.set(newValue, forKey: "fullio_config_version") }
    }

    private(set) var cachedConfig: RemoteFullConfig?
    private(set) var themeColors: RemoteThemeColors?
    private(set) var features: RemoteFeaturesConfig?
    private(set) var strings: RemoteStrings?
    private(set) var categories: [RemoteCategory]?

    private let configFileURL: URL = {
        let docs = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        return docs.appendingPathComponent("fullio_remote_config.json")
    }()

    private init() {
        loadLocalConfig()
    }

    // MARK: - Version Check

    func checkForUpdate() async {
        guard !isCheckingForUpdate else { return }

        await MainActor.run { isCheckingForUpdate = true }

        defer {
            Task { @MainActor in isCheckingForUpdate = false }
        }

        do {
            guard let url = URL(string: "\(baseURL)/api/version") else { return }
            let (data, response) = try await URLSession.shared.data(from: url)

            guard let httpResponse = response as? HTTPURLResponse,
                  httpResponse.statusCode == 200 else { return }

            let versionInfo = try JSONDecoder().decode(RemoteVersion.self, from: data)

            await MainActor.run {
                self.remoteVersion = versionInfo
                if self.localVersion != versionInfo.version {
                    self.updateAvailable = true
                }
            }
        } catch {
            await MainActor.run {
                self.lastError = error.localizedDescription
            }
        }
    }

    // MARK: - Download Update

    func downloadUpdate() async {
        guard !isDownloading else { return }

        await MainActor.run {
            isDownloading = true
            downloadProgress = 0
            lastError = nil
        }

        do {
            guard let url = URL(string: "\(baseURL)/api/config") else { return }

            await MainActor.run { downloadProgress = 0.2 }

            let (data, response) = try await URLSession.shared.data(from: url)

            guard let httpResponse = response as? HTTPURLResponse,
                  httpResponse.statusCode == 200 else {
                throw URLError(.badServerResponse)
            }

            await MainActor.run { downloadProgress = 0.6 }

            let fullConfig = try JSONDecoder().decode(RemoteFullConfig.self, from: data)

            await MainActor.run { downloadProgress = 0.8 }

            try data.write(to: configFileURL, options: .atomic)

            await MainActor.run {
                self.downloadProgress = 1.0
                self.localVersion = fullConfig.version.version
                self.updateAvailable = false
                self.applyConfig(fullConfig)
            }

            try? await Task.sleep(for: .milliseconds(500))

        } catch {
            await MainActor.run {
                self.lastError = error.localizedDescription
            }
        }

        await MainActor.run {
            isDownloading = false
        }
    }

    // MARK: - Local Config

    private func loadLocalConfig() {
        guard FileManager.default.fileExists(atPath: configFileURL.path) else { return }

        do {
            let data = try Data(contentsOf: configFileURL)
            let config = try JSONDecoder().decode(RemoteFullConfig.self, from: data)
            applyConfig(config)
        } catch {
            // First launch or corrupted cache — use defaults
        }
    }

    private func applyConfig(_ config: RemoteFullConfig) {
        cachedConfig = config
        themeColors = config.theme.colors
        features = config.features
        strings = config.strings
        categories = config.categories.categories
    }

    // MARK: - Convenience

    func greeting() -> String {
        if let greetings = strings?.greetings, !greetings.isEmpty {
            return greetings.randomElement() ?? greetings[0]
        }
        return EmotionalMessages.randomGreeting
    }

    func isFeatureEnabled(_ feature: String) -> Bool {
        guard let features else { return true }

        switch feature {
        case "insights": return features.enableInsights
        case "goals": return features.enableGoals
        case "import": return features.enableImport
        case "profile": return features.enableProfile
        case "partnerMode": return features.enablePartnerMode
        case "notifications": return features.enableNotifications
        case "weeklyReport": return features.enableWeeklyReport
        case "subscriptionAlert": return features.enableSubscriptionAlert
        case "impulseWarning": return features.enableImpulseWarning
        case "spendingStreaks": return features.enableSpendingStreaks
        default: return true
        }
    }

    func color(for key: String) -> Color? {
        guard let colors = themeColors else { return nil }

        let hex: String? = switch key {
        case "darkGreen": colors.darkGreen
        case "softGreen": colors.softGreen
        case "beige": colors.beige
        case "black": colors.black
        case "warning": colors.warning
        case "positive": colors.positive
        case "neutral": colors.neutral
        case "cardBackground": colors.cardBackground
        case "background": colors.background
        case "secondaryText": colors.secondaryText
        case "lightGreen": colors.lightGreen
        case "lightWarning": colors.lightWarning
        case "lightBeige": colors.lightBeige
        default: nil
        }

        guard let hex else { return nil }
        return Color(hex: hex)
    }
}
