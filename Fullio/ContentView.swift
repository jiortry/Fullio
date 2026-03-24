import SwiftUI
import SwiftData

struct ContentView: View {
    @Query private var profiles: [UserProfile]
    @State private var hasCompletedOnboarding = false
    @State private var showUpdateView = false
    @State private var configManager = RemoteConfigManager.shared

    var body: some View {
        ZStack {
            Group {
                if profiles.first?.hasCompletedOnboarding == true || hasCompletedOnboarding {
                    MainTabView()
                } else {
                    OnboardingView {
                        withAnimation(.easeInOut(duration: 0.5)) {
                            hasCompletedOnboarding = true
                        }
                    }
                }
            }
            .animation(.easeInOut, value: hasCompletedOnboarding)

            if showUpdateView {
                UpdateView(isPresented: $showUpdateView)
                    .transition(.opacity.combined(with: .scale(scale: 0.95)))
                    .zIndex(100)
            }
        }
        .onChange(of: configManager.updateAvailable) { _, available in
            if available {
                withAnimation(.easeInOut(duration: 0.4)) {
                    showUpdateView = true
                }
            }
        }
    }
}

struct MainTabView: View {
    @State private var selectedTab = 0

    init() {
        let appearance = UITabBarAppearance()
        appearance.configureWithOpaqueBackground()
        appearance.backgroundColor = UIColor(Color.fullioCardBackground)
        appearance.shadowColor = UIColor.black.withAlphaComponent(0.05)
        UITabBar.appearance().standardAppearance = appearance
        UITabBar.appearance().scrollEdgeAppearance = appearance
    }

    var body: some View {
        TabView(selection: $selectedTab) {
            Tab("Home", systemImage: "house.fill", value: 0) {
                HomeView()
            }

            Tab("Attività", systemImage: "list.bullet", value: 1) {
                ActivityView()
            }

            Tab("Obiettivi", systemImage: "target", value: 2) {
                GoalsView()
            }

            Tab("Insight", systemImage: "lightbulb.fill", value: 3) {
                InsightsView()
            }

            Tab("Profilo", systemImage: "person.fill", value: 4) {
                ProfileView()
            }
        }
        .tint(.fullioDarkGreen)
    }
}

#Preview {
    ContentView()
        .modelContainer(for: [Transaction.self, UserProfile.self, SavingsGoal.self], inMemory: true)
}
