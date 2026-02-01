import SwiftUI

struct ContentView: View {
    @StateObject private var themeManager = ThemeManager()
    @StateObject private var userSession = UserSession.shared
    @State private var selectedTab = 0

    var body: some View {
        TabView(selection: $selectedTab) {
            RecordingView()
                .tabItem {
                    Label("Record", systemImage: "video.circle.fill")
                }
                .tag(0)

            HistoryView()
                .tabItem {
                    Label("Dashboard", systemImage: "chart.bar.fill")
                }
                .tag(1)

            SocialTabView()
                .tabItem {
                    Label("Social", systemImage: "person.2.fill")
                }
                .tag(2)

            SettingsView()
                .tabItem {
                    Label("Settings", systemImage: "gearshape.fill")
                }
                .tag(3)
        }
        .tint(.neverOBGreen)
        .preferredColorScheme(themeManager.colorScheme)
        .environmentObject(themeManager)
        .environmentObject(userSession)
    }
}

// MARK: - Social Tab View
struct SocialTabView: View {
    @State private var selectedSection: SocialSection = .leaderboard

    enum SocialSection: String, CaseIterable {
        case leaderboard = "Leaderboard"
        case friends = "Friends"
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Section Picker
                Picker("Section", selection: $selectedSection) {
                    ForEach(SocialSection.allCases, id: \.self) { section in
                        Text(section.rawValue).tag(section)
                    }
                }
                .pickerStyle(.segmented)
                .padding(.horizontal, AppSpacing.md)
                .padding(.vertical, AppSpacing.sm)

                // Content
                Group {
                    switch selectedSection {
                    case .leaderboard:
                        LeaderboardView()
                    case .friends:
                        FriendsView()
                    }
                }
            }
            .background(Color.backgroundPrimary)
            .navigationTitle("Social")
            .navigationBarTitleDisplayMode(.large)
        }
    }
}

#Preview {
    ContentView()
        .environmentObject(SwingStore())
}

#Preview("Social Tab") {
    SocialTabView()
        .environmentObject(UserSession.shared)
}
