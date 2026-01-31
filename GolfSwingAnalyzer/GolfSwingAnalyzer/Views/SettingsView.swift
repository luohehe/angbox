import SwiftUI

struct SettingsView: View {
    @AppStorage("cameraPosition") private var cameraPosition = "back"
    @AppStorage("videoQuality") private var videoQuality = "high"
    @AppStorage("autoAnalyze") private var autoAnalyze = true
    @AppStorage("hapticFeedback") private var hapticFeedback = true
    @AppStorage("showGuideLines") private var showGuideLines = true

    var body: some View {
        NavigationStack {
            List {
                Section("Recording") {
                    Picker("Camera", selection: $cameraPosition) {
                        Text("Back Camera").tag("back")
                        Text("Front Camera").tag("front")
                    }

                    Picker("Video Quality", selection: $videoQuality) {
                        Text("High (1080p)").tag("high")
                        Text("Medium (720p)").tag("medium")
                        Text("Low (480p)").tag("low")
                    }

                    Toggle("Show Guide Lines", isOn: $showGuideLines)
                }

                Section("Analysis") {
                    Toggle("Auto-Analyze After Recording", isOn: $autoAnalyze)
                }

                Section("Feedback") {
                    Toggle("Haptic Feedback", isOn: $hapticFeedback)
                }

                Section("About") {
                    HStack {
                        Text("Version")
                        Spacer()
                        Text("1.0.0")
                            .foregroundColor(.secondary)
                    }

                    Link(destination: URL(string: "https://example.com/privacy")!) {
                        HStack {
                            Text("Privacy Policy")
                            Spacer()
                            Image(systemName: "arrow.up.right")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }

                    Link(destination: URL(string: "https://example.com/terms")!) {
                        HStack {
                            Text("Terms of Service")
                            Spacer()
                            Image(systemName: "arrow.up.right")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                }

                Section("Support") {
                    Link(destination: URL(string: "mailto:support@example.com")!) {
                        HStack {
                            Image(systemName: "envelope")
                                .foregroundColor(.green)
                            Text("Contact Support")
                        }
                    }

                    Link(destination: URL(string: "https://example.com/faq")!) {
                        HStack {
                            Image(systemName: "questionmark.circle")
                                .foregroundColor(.green)
                            Text("FAQ")
                        }
                    }
                }

                Section {
                    Button(role: .destructive) {
                        // Reset all settings
                        cameraPosition = "back"
                        videoQuality = "high"
                        autoAnalyze = true
                        hapticFeedback = true
                        showGuideLines = true
                    } label: {
                        HStack {
                            Spacer()
                            Text("Reset All Settings")
                            Spacer()
                        }
                    }
                }
            }
            .navigationTitle("Settings")
        }
    }
}

#Preview {
    SettingsView()
}
