import SwiftUI

struct HistoryView: View {
    @EnvironmentObject var swingStore: SwingStore
    @State private var selectedSwing: SwingData?
    @State private var showingDeleteAlert = false
    @State private var swingToDelete: SwingData?

    var body: some View {
        NavigationStack {
            Group {
                if swingStore.swings.isEmpty {
                    EmptyHistoryView()
                } else {
                    List {
                        StatsSummarySection(swingStore: swingStore)

                        Section("Recent Swings") {
                            ForEach(swingStore.swings) { swing in
                                SwingHistoryRow(swing: swing)
                                    .contentShape(Rectangle())
                                    .onTapGesture {
                                        selectedSwing = swing
                                    }
                                    .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                                        Button(role: .destructive) {
                                            swingToDelete = swing
                                            showingDeleteAlert = true
                                        } label: {
                                            Label("Delete", systemImage: "trash")
                                        }
                                    }
                            }
                        }
                    }
                }
            }
            .navigationTitle("History")
            .sheet(item: $selectedSwing) { swing in
                AnalysisView(swing: swing)
                    .environmentObject(swingStore)
            }
            .alert("Delete Swing?", isPresented: $showingDeleteAlert, presenting: swingToDelete) { swing in
                Button("Cancel", role: .cancel) {}
                Button("Delete", role: .destructive) {
                    swingStore.deleteSwing(swing)
                }
            } message: { swing in
                Text("This will permanently delete this swing recording and its analysis.")
            }
        }
    }
}

struct EmptyHistoryView: View {
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "clock.arrow.circlepath")
                .font(.system(size: 60))
                .foregroundColor(.gray)

            Text("No Swings Recorded")
                .font(.title2)
                .fontWeight(.semibold)

            Text("Record your first swing to start tracking your progress.")
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
        }
    }
}

struct StatsSummarySection: View {
    @ObservedObject var swingStore: SwingStore

    var body: some View {
        Section("Overview") {
            HStack(spacing: 20) {
                StatBox(
                    title: "Total",
                    value: "\(swingStore.totalSwings)",
                    subtitle: "swings",
                    color: .blue
                )

                StatBox(
                    title: "Average",
                    value: "\(swingStore.averageScore)",
                    subtitle: "score",
                    color: .green
                )

                if let improvement = swingStore.recentImprovement {
                    StatBox(
                        title: "Trend",
                        value: improvement >= 0 ? "+\(improvement)" : "\(improvement)",
                        subtitle: "points",
                        color: improvement >= 0 ? .green : .red
                    )
                } else {
                    StatBox(
                        title: "Trend",
                        value: "—",
                        subtitle: "points",
                        color: .gray
                    )
                }
            }
            .padding(.vertical, 8)
        }
    }
}

struct StatBox: View {
    let title: String
    let value: String
    let subtitle: String
    let color: Color

    var body: some View {
        VStack(spacing: 4) {
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)

            Text(value)
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(color)

            Text(subtitle)
                .font(.caption2)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .background(color.opacity(0.1))
        .cornerRadius(12)
    }
}

struct SwingHistoryRow: View {
    let swing: SwingData

    var body: some View {
        HStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(scoreBackgroundColor)
                    .frame(width: 50, height: 50)

                if let score = swing.analysis?.overallScore {
                    Text("\(score)")
                        .font(.headline)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                } else {
                    Image(systemName: "clock")
                        .foregroundColor(.white)
                }
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(formattedDate)
                    .font(.headline)

                HStack(spacing: 12) {
                    if let analysis = swing.analysis {
                        Label(analysis.scoreGrade, systemImage: "star.fill")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    } else {
                        Label("Not Analyzed", systemImage: "hourglass")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }

                    Label(formattedDuration, systemImage: "timer")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }

            Spacer()

            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding(.vertical, 4)
    }

    var scoreBackgroundColor: Color {
        guard let score = swing.analysis?.overallScore else {
            return .gray
        }

        switch score {
        case 90...100: return .green
        case 80..<90: return .blue
        case 70..<80: return .yellow
        case 60..<70: return .orange
        default: return .red
        }
    }

    var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: swing.recordedAt)
    }

    var formattedDuration: String {
        let seconds = Int(swing.duration)
        return "\(seconds)s"
    }
}

#Preview {
    HistoryView()
        .environmentObject(SwingStore())
}
