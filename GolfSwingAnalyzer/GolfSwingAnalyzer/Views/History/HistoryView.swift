import SwiftUI

struct HistoryView: View {
    @EnvironmentObject var swingStore: SwingStore
    @State private var selectedSwing: SwingData?
    @State private var showingDeleteAlert = false
    @State private var swingToDelete: SwingData?

    var body: some View {
        NavigationStack {
            ScrollView {
                if swingStore.swings.isEmpty {
                    EmptyDashboardView()
                        .padding(.top, AppSpacing.xxl)
                } else {
                    VStack(spacing: AppSpacing.lg) {
                        // Score Highlight Card
                        if swingStore.averageScore > 0 {
                            ScoreHighlightCard(
                                score: swingStore.averageScore,
                                totalSwings: swingStore.totalSwings,
                                improvement: swingStore.recentImprovement
                            )
                            .padding(.horizontal, AppSpacing.md)
                        }

                        // Stats Overview
                        StatsOverviewSection(swingStore: swingStore)

                        // Recent Swings
                        RecentSwingsSection(
                            swings: swingStore.swings,
                            onSelect: { swing in selectedSwing = swing },
                            onDelete: { swing in
                                swingToDelete = swing
                                showingDeleteAlert = true
                            }
                        )
                    }
                    .padding(.vertical, AppSpacing.md)
                }
            }
            .background(Color.backgroundPrimary)
            .navigationTitle("Dashboard")
            .sheet(item: $selectedSwing) { swing in
                AnalysisView(swing: swing)
                    .environmentObject(swingStore)
            }
            .alert("Delete Swing?", isPresented: $showingDeleteAlert, presenting: swingToDelete) { swing in
                Button("Cancel", role: .cancel) {}
                Button("Delete", role: .destructive) {
                    withAnimation {
                        swingStore.deleteSwing(swing)
                    }
                }
            } message: { _ in
                Text("This will permanently delete this swing recording and its analysis.")
            }
        }
    }
}

// MARK: - Empty Dashboard
struct EmptyDashboardView: View {
    var body: some View {
        EmptyStateView(
            icon: "figure.golf",
            title: "No Swings Yet",
            message: "Record your first swing to start tracking your progress and see detailed analytics.",
            actionTitle: nil,
            action: nil
        )
    }
}

// MARK: - Score Highlight Card
struct ScoreHighlightCard: View {
    let score: Int
    let totalSwings: Int
    let improvement: Int?

    var body: some View {
        GolfCard {
            HStack(spacing: AppSpacing.lg) {
                // Score Ring
                ScoreRing(score: score, size: 100, lineWidth: 8)

                // Stats
                VStack(alignment: .leading, spacing: AppSpacing.sm) {
                    Text("Your Average")
                        .font(AppTypography.subheadline)
                        .foregroundColor(.secondary)

                    if let improvement = improvement {
                        HStack(spacing: AppSpacing.xxs) {
                            Image(systemName: improvement >= 0 ? "arrow.up.circle.fill" : "arrow.down.circle.fill")
                                .foregroundColor(improvement >= 0 ? .scoreExcellent : .scoreNeedsWork)

                            Text(improvement >= 0 ? "+\(improvement) points" : "\(improvement) points")
                                .font(AppTypography.headline)
                                .foregroundColor(improvement >= 0 ? .scoreExcellent : .scoreNeedsWork)
                        }

                        Text("compared to previous sessions")
                            .font(AppTypography.caption1)
                            .foregroundColor(.secondary)
                    } else {
                        Text("Record more swings to see trends")
                            .font(AppTypography.caption1)
                            .foregroundColor(.secondary)
                    }

                    Divider()

                    HStack {
                        Image(systemName: "video.fill")
                            .font(.system(size: 12))
                            .foregroundColor(.golfGreen)
                        Text("\(totalSwings) swings analyzed")
                            .font(AppTypography.caption1)
                            .foregroundColor(.secondary)
                    }
                }

                Spacer()
            }
        }
    }
}

// MARK: - Stats Overview Section
struct StatsOverviewSection: View {
    @ObservedObject var swingStore: SwingStore

    private var bestScore: Int {
        swingStore.swings.compactMap { $0.analysis?.overallScore }.max() ?? 0
    }

    var body: some View {
        VStack(alignment: .leading, spacing: AppSpacing.sm) {
            SectionHeader("Statistics")

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: AppSpacing.sm) {
                    StatCard(
                        title: "Total Swings",
                        value: "\(swingStore.totalSwings)",
                        subtitle: "recorded",
                        icon: "video.fill",
                        color: .golfGreen
                    )

                    StatCard(
                        title: "Avg Score",
                        value: "\(swingStore.averageScore)",
                        subtitle: "out of 100",
                        icon: "chart.bar.fill",
                        color: .scoreGreat
                    )

                    if let improvement = swingStore.recentImprovement {
                        StatCard(
                            title: "Trend",
                            value: improvement >= 0 ? "+\(improvement)" : "\(improvement)",
                            subtitle: "vs last 5",
                            icon: improvement >= 0 ? "arrow.up.right" : "arrow.down.right",
                            color: improvement >= 0 ? .scoreExcellent : .scoreNeedsWork
                        )
                    }

                    StatCard(
                        title: "Best Score",
                        value: "\(bestScore)",
                        subtitle: "personal best",
                        icon: "trophy.fill",
                        color: .orange
                    )
                }
                .padding(.horizontal, AppSpacing.md)
            }
        }
    }
}

// MARK: - Recent Swings Section
struct RecentSwingsSection: View {
    let swings: [SwingData]
    let onSelect: (SwingData) -> Void
    let onDelete: (SwingData) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: AppSpacing.sm) {
            SectionHeader("Recent Swings")

            LazyVStack(spacing: AppSpacing.sm) {
                ForEach(swings) { swing in
                    SwingCard(swing: swing)
                        .onTapGesture { onSelect(swing) }
                        .contextMenu {
                            Button(role: .destructive) {
                                onDelete(swing)
                            } label: {
                                Label("Delete", systemImage: "trash")
                            }
                        }
                }
            }
            .padding(.horizontal, AppSpacing.md)
        }
    }
}

// MARK: - Swing Card
struct SwingCard: View {
    let swing: SwingData

    // Static DateFormatter for performance
    private static let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter
    }()

    var body: some View {
        GolfCard {
            HStack(spacing: AppSpacing.md) {
                // Score Badge
                ScoreBadge(score: swing.analysis?.overallScore)

                // Info
                VStack(alignment: .leading, spacing: AppSpacing.xxs) {
                    Text(Self.dateFormatter.string(from: swing.recordedAt))
                        .font(AppTypography.headline)
                        .foregroundColor(.primary)

                    HStack(spacing: AppSpacing.md) {
                        if let analysis = swing.analysis {
                            Label(analysis.scoreGrade, systemImage: "star.fill")
                                .font(AppTypography.caption1)
                                .foregroundColor(.secondary)
                        } else {
                            Label("Not Analyzed", systemImage: "hourglass")
                                .font(AppTypography.caption1)
                                .foregroundColor(.orange)
                        }

                        Label(formattedDuration, systemImage: "timer")
                            .font(AppTypography.caption1)
                            .foregroundColor(.secondary)
                    }
                }

                Spacer()

                // Arrow
                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.secondary)
            }
        }
    }

    private var formattedDuration: String {
        let seconds = Int(swing.duration)
        return "\(seconds)s"
    }
}

// MARK: - Score Badge
struct ScoreBadge: View {
    let score: Int?

    var body: some View {
        ZStack {
            Circle()
                .fill(backgroundColor)
                .frame(width: 56, height: 56)

            if let score = score {
                Text("\(score)")
                    .font(AppTypography.scoreSmall)
                    .foregroundColor(.white)
            } else {
                Image(systemName: "play.fill")
                    .font(.system(size: 18))
                    .foregroundColor(.white)
            }
        }
    }

    private var backgroundColor: Color {
        guard let score = score else { return .gray }
        return ScoreColorHelper.color(for: score)
    }
}

#Preview {
    HistoryView()
        .environmentObject(SwingStore())
}
