import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var themeManager: ThemeManager
    @AppStorage("cameraPosition") private var cameraPosition = "back"
    @AppStorage("videoQuality") private var videoQuality = "high"
    @AppStorage("autoAnalyze") private var autoAnalyze = true
    @AppStorage("hapticFeedback") private var hapticFeedback = true
    @AppStorage("showGuideLines") private var showGuideLines = true

    // Static URL constants
    private enum URLs {
        static let privacy = URL(string: "https://neverob.app/privacy")!
        static let terms = URL(string: "https://neverob.app/terms")!
        static let support = URL(string: "mailto:support@neverob.app")!
        static let faq = URL(string: "https://neverob.app/faq")!
    }

    var body: some View {
        NavigationStack {
            List {
                // App Branding Header
                Section {
                    AppBrandingHeader()
                }
                .listRowBackground(Color.clear)

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

                Section("Appearance") {
                    Toggle("Use System Theme", isOn: $themeManager.useSystemTheme)

                    if !themeManager.useSystemTheme {
                        Toggle("Dark Mode", isOn: $themeManager.isDarkMode)
                    }

                    Toggle("Haptic Feedback", isOn: $hapticFeedback)
                }

                Section("About") {
                    HStack {
                        Text("Version")
                        Spacer()
                        Text("1.0.0")
                            .foregroundColor(.secondary)
                    }

                    HStack {
                        Text("Build")
                        Spacer()
                        Text("2024.1")
                            .foregroundColor(.secondary)
                    }

                    Link(destination: URLs.privacy) {
                        SettingsLinkRow(title: "Privacy Policy", icon: "hand.raised.fill", color: .blue)
                    }

                    Link(destination: URLs.terms) {
                        SettingsLinkRow(title: "Terms of Service", icon: "doc.text.fill", color: .gray)
                    }
                }

                Section("Support") {
                    Link(destination: URLs.support) {
                        SettingsLinkRow(title: "Contact Support", icon: "envelope.fill", color: .neverOBGreen)
                    }

                    Link(destination: URLs.faq) {
                        SettingsLinkRow(title: "FAQ", icon: "questionmark.circle.fill", color: .orange)
                    }
                }

                Section {
                    Button(role: .destructive) {
                        resetSettings()
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

    private func resetSettings() {
        cameraPosition = "back"
        videoQuality = "high"
        autoAnalyze = true
        hapticFeedback = true
        showGuideLines = true
        themeManager.useSystemTheme = true
    }
}

// MARK: - App Branding Header
struct AppBrandingHeader: View {
    var body: some View {
        VStack(spacing: AppSpacing.md) {
            // Logo
            NeverOBIconMinimal(size: 72)

            // App Name
            HStack(spacing: 4) {
                Text("Never")
                    .font(.system(size: 24, weight: .medium, design: .rounded))
                    .foregroundColor(.primary)

                Text("OB")
                    .font(.system(size: 24, weight: .bold, design: .rounded))
                    .foregroundColor(.neverOBGreen)
            }

            // Tagline
            Text("AI-Powered Golf Swing Analysis")
                .font(AppTypography.caption1)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, AppSpacing.md)
    }
}

// MARK: - Settings Link Row
struct SettingsLinkRow: View {
    let title: String
    let icon: String
    let color: Color

    var body: some View {
        HStack(spacing: AppSpacing.sm) {
            Image(systemName: icon)
                .font(.system(size: 16))
                .foregroundColor(color)
                .frame(width: 28)

            Text(title)
                .foregroundColor(.primary)

            Spacer()

            Image(systemName: "arrow.up.right")
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }
}

#Preview {
    SettingsView()
        .environmentObject(ThemeManager())
}
