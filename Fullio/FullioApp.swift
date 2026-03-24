import SwiftUI
import SwiftData

@main
struct FullioApp: App {
    @State private var configManager = RemoteConfigManager.shared

    var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            Transaction.self,
            UserProfile.self,
            SavingsGoal.self,
        ])
        let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)

        do {
            return try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .task {
                    await configManager.checkForUpdate()
                }
        }
        .modelContainer(sharedModelContainer)
    }
}
