import SwiftUI

struct ContentView: View {
    @StateObject private var themeManager = ThemeManager()
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

            SettingsView()
                .tabItem {
                    Label("Settings", systemImage: "gearshape.fill")
                }
                .tag(2)
        }
        .tint(.golfGreen)
        .preferredColorScheme(themeManager.colorScheme)
        .environmentObject(themeManager)
    }
}

#Preview {
    ContentView()
        .environmentObject(SwingStore())
}
