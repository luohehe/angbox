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
                    }

                    if isAnalyzing {
                        AnalyzingProgressView(progress: analysisProgress)
                            .padding()
                    } else if let analysis = swing.analysis {
                        ScoreCard(analysis: analysis)
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
            .alert("Analysis Failed", isPresented: $showErrorAlert, presenting: analysisError) { _ in
                Button("OK", role: .cancel) {}
            } message: { error in
                Text(error.localizedDescription)
            }
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

#Preview {
    AnalysisView(swing: SwingData())
        .environmentObject(SwingStore())
}
