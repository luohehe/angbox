import SwiftUI
import AVKit

struct AnalysisView: View {
    @EnvironmentObject var swingStore: SwingStore
    @Environment(\.dismiss) var dismiss
    @State private var swing: SwingData
    @State private var isAnalyzing = false
    @State private var analysisProgress: Double = 0
    @State private var selectedTab = 0
    @State private var analysisError: Error?
    @State private var showErrorAlert = false
    @State private var showCoachView = false
    @State private var showShareOptions = false
    @State private var showSaveSuccess = false
    @State private var showSaveError = false
    @State private var showInstagramNotInstalled = false
    @StateObject private var shareService = VideoShareService.shared

    private let analysisService = SwingAnalysisService()

    init(swing: SwingData) {
        _swing = State(initialValue: swing)
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    if let videoURL = swing.videoURL {
                        VideoPlayerView(url: videoURL)
                            .frame(height: 280)
                            .cornerRadius(16)
                            .padding(.horizontal)

                        // Video Action Buttons
                        VideoActionBar(
                            onSaveToAlbum: { saveToPhotoLibrary() },
                            onShareInstagram: { shareToInstagram() },
                            onShareMore: { shareService.shareVideo(videoURL: videoURL) },
                            isSaving: shareService.isSaving
                        )
                        .padding(.horizontal)
                    }

                    if isAnalyzing {
                        AnalyzingProgressView(progress: analysisProgress)
                            .padding()
                    } else if let analysis = swing.analysis {
                        ScoreCard(analysis: analysis)
                            .padding(.horizontal)

                        // Coach PJ Button
                        CoachPJButton {
                            showCoachView = true
                        }
                        .padding(.horizontal)

                        Picker("View", selection: $selectedTab) {
                            Text("Phases").tag(0)
                            Text("Metrics").tag(1)
                            Text("Feedback").tag(2)
                        }
                        .pickerStyle(.segmented)
                        .padding(.horizontal)

                        switch selectedTab {
                        case 0:
                            PhasesView(phases: analysis.phases)
                        case 1:
                            MetricsView(metrics: analysis.keyMetrics)
                        case 2:
                            FeedbackListView(feedback: analysis.feedback)
                        default:
                            EmptyView()
                        }
                    } else {
                        Button(action: startAnalysis) {
                            Label("Analyze Swing", systemImage: "waveform.path.ecg")
                                .font(.headline)
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.green)
                                .cornerRadius(12)
                        }
                        .padding(.horizontal)
                    }
                }
                .padding(.vertical)
            }
            .navigationTitle("Swing Analysis")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Close") {
                        dismiss()
                    }
                }

                if swing.analysis != nil {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        ShareLink(item: generateShareText()) {
                            Image(systemName: "square.and.arrow.up")
                        }
                    }
                }
            }
            .sheet(isPresented: $showCoachView) {
                CoachView(swing: swing)
            }
            .alert("Analysis Failed", isPresented: $showErrorAlert, presenting: analysisError) { _ in
                Button("OK", role: .cancel) {}
            } message: { error in
                Text(error.localizedDescription)
            }
            .alert("Saved!", isPresented: $showSaveSuccess) {
                Button("OK", role: .cancel) {}
            } message: {
                Text("Your swing video has been saved to your photo library.")
            }
            .alert("Save Failed", isPresented: $showSaveError) {
                Button("Open Settings") {
                    if let settingsURL = URL(string: UIApplication.openSettingsURLString) {
                        UIApplication.shared.open(settingsURL)
                    }
                }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text(shareService.saveError?.localizedDescription ?? "Failed to save video. Please check your photo library permissions.")
            }
            .alert("Instagram Not Installed", isPresented: $showInstagramNotInstalled) {
                Button("OK", role: .cancel) {}
            } message: {
                Text("Instagram is not installed on this device. Please install Instagram to share your swing videos.")
            }
        }
    }

    // MARK: - Video Sharing Actions

    private func saveToPhotoLibrary() {
        guard let videoURL = swing.videoURL else { return }

        Task {
            let success = await shareService.saveToPhotoLibrary(videoURL: videoURL)
            if success {
                showSaveSuccess = true
            } else {
                showSaveError = true
            }
        }
    }

    private func shareToInstagram() {
        guard let videoURL = swing.videoURL else { return }

        if shareService.isInstagramStoriesAvailable {
            _ = shareService.shareToInstagramStories(videoURL: videoURL)
        } else if shareService.isInstagramInstalled {
            // Save to library first, then user can share from Instagram
            Task {
                let success = await shareService.saveToPhotoLibrary(videoURL: videoURL)
                if success {
                    // Open Instagram
                    if let instagramURL = URL(string: "instagram://app") {
                        await UIApplication.shared.open(instagramURL)
                    }
                }
            }
        } else {
            showInstagramNotInstalled = true
        }
    }

    private func startAnalysis() {
        guard let videoURL = swing.videoURL else { return }

        isAnalyzing = true
        analysisError = nil

        Task { [weak swingStore] in
            do {
                let analysis = try await analysisService.analyzeSwing(videoURL: videoURL) { progress in
                    analysisProgress = progress
                }

                swing.analysis = analysis
                swingStore?.updateSwing(swing)
                isAnalyzing = false
            } catch {
                isAnalyzing = false
                analysisError = error
                showErrorAlert = true
            }
        }
    }

    private func generateShareText() -> String {
        guard let analysis = swing.analysis else { return "" }

        return """
        Golf Swing Analysis Results

        Overall Score: \(analysis.overallScore)/100 (\(analysis.scoreGrade))

        Phase Scores:
        - Address: \(analysis.phases.addressScore)
        - Backswing: \(analysis.phases.backswingScore)
        - Top: \(analysis.phases.topScore)
        - Downswing: \(analysis.phases.downswingScore)
        - Impact: \(analysis.phases.impactScore)
        - Follow Through: \(analysis.phases.followThroughScore)

        Analyzed with Golf Swing Analyzer
        """
    }
}

struct VideoPlayerView: View {
    let url: URL
    @State private var player: AVPlayer?

    var body: some View {
        VideoPlayer(player: player)
            .onAppear {
                player = AVPlayer(url: url)
            }
            .onDisappear {
                player?.pause()
                player?.replaceCurrentItem(with: nil)
                player = nil
            }
    }
}

struct AnalyzingProgressView: View {
    let progress: Double

    var body: some View {
        VStack(spacing: 16) {
            ProgressView(value: progress)
                .progressViewStyle(LinearProgressViewStyle(tint: .green))

            HStack {
                Image(systemName: "figure.golf")
                    .foregroundColor(.green)

                Text("Analyzing your swing...")
                    .foregroundColor(.secondary)

                Spacer()

                Text("\(Int(progress * 100))%")
                    .fontWeight(.medium)
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

struct ScoreCard: View {
    let analysis: SwingAnalysis

    var body: some View {
        VStack(spacing: 16) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Overall Score")
                        .font(.subheadline)
                        .foregroundColor(.secondary)

                    Text(analysis.scoreGrade)
                        .font(.title3)
                        .fontWeight(.medium)
                }

                Spacer()

                ZStack {
                    Circle()
                        .stroke(Color.gray.opacity(0.3), lineWidth: 8)
                        .frame(width: 80, height: 80)

                    Circle()
                        .trim(from: 0, to: Double(analysis.overallScore) / 100)
                        .stroke(ScoreColorHelper.color(for: analysis.overallScore), style: StrokeStyle(lineWidth: 8, lineCap: .round))
                        .frame(width: 80, height: 80)
                        .rotationEffect(.degrees(-90))

                    Text("\(analysis.overallScore)")
                        .font(.title)
                        .fontWeight(.bold)
                }
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(16)
    }
}

// MARK: - Consolidated Score Color Helper
enum ScoreColorHelper {
    static func color(for score: Int) -> Color {
        switch score {
        case 90...100: return .green
        case 80..<90: return .blue
        case 70..<80: return .yellow
        case 60..<70: return .orange
        default: return .red
        }
    }

    static func phaseColor(for score: Int) -> Color {
        switch score {
        case 85...100: return .green
        case 70..<85: return .yellow
        default: return .orange
        }
    }
}

struct PhasesView: View {
    let phases: SwingPhases

    var body: some View {
        VStack(spacing: 12) {
            PhaseRow(name: "Address", score: phases.addressScore, icon: "figure.stand")
            PhaseRow(name: "Backswing", score: phases.backswingScore, icon: "arrow.up.right")
            PhaseRow(name: "Top Position", score: phases.topScore, icon: "arrow.up")
            PhaseRow(name: "Downswing", score: phases.downswingScore, icon: "arrow.down.right")
            PhaseRow(name: "Impact", score: phases.impactScore, icon: "bolt.fill")
            PhaseRow(name: "Follow Through", score: phases.followThroughScore, icon: "arrow.right")
        }
        .padding(.horizontal)
    }
}

struct PhaseRow: View {
    let name: String
    let score: Int
    let icon: String

    private var scoreColor: Color {
        ScoreColorHelper.phaseColor(for: score)
    }

    var body: some View {
        HStack {
            Image(systemName: icon)
                .foregroundColor(.green)
                .frame(width: 30)

            Text(name)

            Spacer()

            Text("\(score)")
                .fontWeight(.semibold)
                .foregroundColor(scoreColor)

            ProgressView(value: Double(score) / 100)
                .progressViewStyle(LinearProgressViewStyle(tint: scoreColor))
                .frame(width: 80)
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

struct MetricsView: View {
    let metrics: SwingMetrics

    var body: some View {
        VStack(spacing: 12) {
            MetricRow(name: "Hip Rotation", value: "\(Int(metrics.hipRotation))°", icon: "arrow.triangle.2.circlepath")
            MetricRow(name: "Shoulder Rotation", value: "\(Int(metrics.shoulderRotation))°", icon: "arrow.triangle.2.circlepath")
            MetricRow(name: "Spine Angle", value: "\(Int(metrics.spineAngle))°", icon: "arrow.up.and.down")
            MetricRow(name: "Tempo", value: String(format: "%.1f:1", metrics.tempo), icon: "metronome")
            MetricRow(name: "Swing Plane", value: metrics.swingPlane.rawValue, icon: "arrow.up.forward")
            MetricRow(name: "Balance", value: metrics.balance.rawValue, icon: "scale.3d")
        }
        .padding(.horizontal)
    }
}

struct MetricRow: View {
    let name: String
    let value: String
    let icon: String

    var body: some View {
        HStack {
            Image(systemName: icon)
                .foregroundColor(.green)
                .frame(width: 30)

            Text(name)

            Spacer()

            Text(value)
                .fontWeight(.semibold)
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

struct FeedbackListView: View {
    let feedback: [SwingFeedback]

    var body: some View {
        VStack(spacing: 12) {
            ForEach(feedback) { item in
                FeedbackCard(feedback: item)
            }
        }
        .padding(.horizontal)
    }
}

struct FeedbackCard: View {
    let feedback: SwingFeedback

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: feedbackIcon)
                    .foregroundColor(feedbackColor)

                Text(feedback.title)
                    .font(.headline)

                Spacer()

                Text(feedback.category.rawValue)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color(.systemGray5))
                    .cornerRadius(8)
            }

            Text(feedback.description)
                .font(.subheadline)
                .foregroundColor(.secondary)

            HStack(spacing: 8) {
                Image(systemName: "lightbulb.fill")
                    .foregroundColor(.yellow)
                    .font(.caption)

                Text(feedback.suggestion)
                    .font(.caption)
                    .foregroundColor(.primary)
            }
            .padding(12)
            .background(Color.yellow.opacity(0.1))
            .cornerRadius(8)
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(16)
    }

    var feedbackIcon: String {
        switch feedback.severity {
        case .positive: return "checkmark.circle.fill"
        case .suggestion: return "lightbulb.fill"
        case .warning: return "exclamationmark.triangle.fill"
        case .critical: return "xmark.circle.fill"
        }
    }

    var feedbackColor: Color {
        switch feedback.severity {
        case .positive: return .green
        case .suggestion: return .blue
        case .warning: return .orange
        case .critical: return .red
        }
    }
}

// MARK: - Coach PJ Button
struct CoachPJButton: View {
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                // Coach Avatar
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [.neverOBGreen, .neverOBGreen.opacity(0.7)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 44, height: 44)

                    Text("PJ")
                        .font(.system(size: 16, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                }

                VStack(alignment: .leading, spacing: 2) {
                    Text("Ask Coach PJ")
                        .font(.headline)
                        .foregroundColor(.primary)

                    Text("Get personalized tips and drills")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.neverOBGreen)
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.neverOBGreen.opacity(0.1))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color.neverOBGreen.opacity(0.3), lineWidth: 1)
                    )
            )
        }
    }
}

// MARK: - Video Action Bar
struct VideoActionBar: View {
    let onSaveToAlbum: () -> Void
    let onShareInstagram: () -> Void
    let onShareMore: () -> Void
    let isSaving: Bool

    var body: some View {
        HStack(spacing: AppSpacing.sm) {
            // Save to Album
            VideoActionButton(
                icon: "square.and.arrow.down.fill",
                title: "Save",
                color: .neverOBGreen,
                isLoading: isSaving,
                action: onSaveToAlbum
            )

            // Share to Instagram
            VideoActionButton(
                icon: "camera.fill",
                title: "Instagram",
                color: .instagramGradient,
                action: onShareInstagram
            )

            // More Share Options
            VideoActionButton(
                icon: "square.and.arrow.up",
                title: "More",
                color: .blue,
                action: onShareMore
            )
        }
    }
}

// MARK: - Video Action Button
struct VideoActionButton: View {
    let icon: String
    let title: String
    let color: Color
    var isLoading: Bool = false
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 6) {
                if isLoading {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        .frame(width: 24, height: 24)
                } else {
                    Image(systemName: icon)
                        .font(.system(size: 20, weight: .medium))
                        .foregroundColor(.white)
                }

                Text(title)
                    .font(AppTypography.caption2)
                    .foregroundColor(.white)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, AppSpacing.sm)
            .background(color)
            .cornerRadius(AppCornerRadius.medium)
        }
        .disabled(isLoading)
    }
}

// MARK: - Instagram Gradient Color
extension Color {
    static let instagramGradient = Color(red: 0.88, green: 0.19, blue: 0.42) // Instagram pink/purple
}

#Preview {
    AnalysisView(swing: SwingData())
        .environmentObject(SwingStore())
}

#Preview("Coach Button") {
    CoachPJButton {}
        .padding()
}

#Preview("Video Action Bar") {
    VideoActionBar(
        onSaveToAlbum: {},
        onShareInstagram: {},
        onShareMore: {},
        isSaving: false
    )
    .padding()
}
