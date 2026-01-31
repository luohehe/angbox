import SwiftUI

@main
struct GolfSwingAnalyzerApp: App {
    @StateObject private var swingStore = SwingStore()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(swingStore)
        }
    }
}
