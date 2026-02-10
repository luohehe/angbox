import SwiftUI

// MARK: - Coach View
struct CoachView: View {
    let swing: SwingData
    @StateObject private var coachManager = CoachManager.shared
    @Environment(\.dismiss) var dismiss
    @State private var showDrillSheet = false
    @State private var selectedImprovement: SwingImprovement?

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Coach Header
                CoachHeader()

                // Messages List
                ScrollViewReader { proxy in
                    ScrollView {
                        LazyVStack(spacing: AppSpacing.md) {
                            ForEach(coachManager.messages) { message in
                                CoachMessageBubble(message: message)
                                    .id(message.id)
                            }

                            if coachManager.isGenerating {
                                TypingIndicator()
                            }

                            // Feedback Card (if available)
                            if let feedback = coachManager.currentFeedback {
                                CoachFeedbackCard(
                                    feedback: feedback,
                                    onDrillTap: { improvement in
                                        selectedImprovement = improvement
                                        showDrillSheet = true
                                    }
                                )
                                .id("feedback")
                            }
                        }
                        .padding(AppSpacing.md)
                    }
                    .onChange(of: coachManager.messages.count) { _, _ in
                        withAnimation {
                            proxy.scrollTo(coachManager.messages.last?.id, anchor: .bottom)
                        }
                    }
                }

                // Quick Actions
                if coachManager.currentFeedback != nil {
                    QuickActionBar(onAction: handleQuickAction)
                }
            }
            .background(Color.backgroundPrimary)
            .navigationTitle("Coach PJ")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") { dismiss() }
                        .foregroundColor(.neverOBGreen)
                }
            }
            .sheet(isPresented: $showDrillSheet) {
                if let improvement = selectedImprovement {
                    DrillDetailSheet(improvement: improvement)
                }
            }
            .task {
                coachManager.startSession(for: swing)
                await coachManager.analyzeSwing(swing)
            }
        }
    }

    private func handleQuickAction(_ action: QuickAction) {
        Task {
            switch action {
            case .tip:
                if let focus = coachManager.currentFeedback?.focusArea {
                    await coachManager.requestTip(for: focus)
                }
            case .drill:
                if let improvement = coachManager.currentFeedback?.improvements.first {
                    await coachManager.requestDrill(for: improvement)
                }
            case .encourage:
                if let score = swing.analysis?.overallScore {
                    let message = await CoachService.shared.generateEncouragement(score: score)
                    coachManager.messages.append(message)
                }
            }
        }
    }
}

// MARK: - Coach Header
struct CoachHeader: View {
    var body: some View {
        HStack(spacing: AppSpacing.md) {
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
                    .frame(width: 50, height: 50)

                Text("PJ")
                    .font(.system(size: 20, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
            }

            VStack(alignment: .leading, spacing: 2) {
                Text("Coach PJ")
                    .font(AppTypography.headline)
                    .foregroundColor(.primary)

                HStack(spacing: 4) {
                    Circle()
                        .fill(Color.green)
                        .frame(width: 8, height: 8)
                    Text("Online")
                        .font(AppTypography.caption2)
                        .foregroundColor(.secondary)
                }
            }

            Spacer()

            // Coach Badge
            HStack(spacing: 4) {
                Image(systemName: "star.fill")
                    .font(.system(size: 12))
                Text("Pro Coach")
                    .font(AppTypography.caption2)
            }
            .foregroundColor(.neverOBGreen)
            .padding(.horizontal, AppSpacing.sm)
            .padding(.vertical, AppSpacing.xxs)
            .background(Color.neverOBGreen.opacity(0.1))
            .cornerRadius(AppCornerRadius.circular)
        }
        .padding(AppSpacing.md)
        .background(Color.cardBackground)
    }
}

// MARK: - Coach Message Bubble
struct CoachMessageBubble: View {
    let message: CoachMessage

    var body: some View {
        HStack(alignment: .top, spacing: AppSpacing.sm) {
            // Coach Avatar (small)
            ZStack {
                Circle()
                    .fill(Color.neverOBGreen)
                    .frame(width: 32, height: 32)

                Text("PJ")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundColor(.white)
            }

            VStack(alignment: .leading, spacing: AppSpacing.xxs) {
                // Message Type Badge
                HStack(spacing: 4) {
                    Image(systemName: iconForMessageType(message.type))
                        .font(.system(size: 10))
                    Text(labelForMessageType(message.type))
                        .font(AppTypography.caption2)
                }
                .foregroundColor(colorForMessageType(message.type))

                // Message Content
                Text(message.content)
                    .font(AppTypography.body)
                    .foregroundColor(.primary)
                    .fixedSize(horizontal: false, vertical: true)

                // Timestamp
                Text(message.timestamp, style: .time)
                    .font(AppTypography.caption2)
                    .foregroundColor(.secondary)
            }
            .padding(AppSpacing.sm)
            .background(Color.cardBackground)
            .cornerRadius(AppCornerRadius.medium)

            Spacer()
        }
    }

    private func iconForMessageType(_ type: CoachMessage.MessageType) -> String {
        switch type {
        case .greeting: return "hand.wave.fill"
        case .analysis: return "chart.bar.fill"
        case .tip: return "lightbulb.fill"
        case .question: return "questionmark.circle.fill"
        case .encouragement: return "star.fill"
        case .drill: return "figure.golf"
        case .summary: return "doc.text.fill"
        }
    }

    private func labelForMessageType(_ type: CoachMessage.MessageType) -> String {
        switch type {
        case .greeting: return "Greeting"
        case .analysis: return "Analysis"
        case .tip: return "Tip"
        case .question: return "Question"
        case .encouragement: return "Encouragement"
        case .drill: return "Drill"
        case .summary: return "Summary"
        }
    }

    private func colorForMessageType(_ type: CoachMessage.MessageType) -> Color {
        switch type {
        case .greeting: return .blue
        case .analysis: return .neverOBGreen
        case .tip: return .yellow
        case .question: return .purple
        case .encouragement: return .orange
        case .drill: return .green
        case .summary: return .gray
        }
    }
}

// MARK: - Typing Indicator
struct TypingIndicator: View {
    @State private var animating = false

    var body: some View {
        HStack(spacing: AppSpacing.sm) {
            ZStack {
                Circle()
                    .fill(Color.neverOBGreen)
                    .frame(width: 32, height: 32)

                Text("PJ")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundColor(.white)
            }

            HStack(spacing: 4) {
                ForEach(0..<3) { index in
                    Circle()
                        .fill(Color.secondary)
                        .frame(width: 8, height: 8)
                        .scaleEffect(animating ? 1.0 : 0.5)
                        .animation(
                            .easeInOut(duration: 0.6)
                                .repeatForever()
                                .delay(Double(index) * 0.2),
                            value: animating
                        )
                }
            }
            .padding(AppSpacing.sm)
            .background(Color.cardBackground)
            .cornerRadius(AppCornerRadius.medium)

            Spacer()
        }
        .onAppear { animating = true }
    }
}

// MARK: - Coach Feedback Card
struct CoachFeedbackCard: View {
    let feedback: CoachFeedback
    let onDrillTap: (SwingImprovement) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: AppSpacing.md) {
            // Header
            HStack {
                Image(systemName: "clipboard.fill")
                    .foregroundColor(.neverOBGreen)
                Text("Session Summary")
                    .font(AppTypography.headline)
            }

            Divider()

            // Strengths
            if !feedback.strengths.isEmpty {
                VStack(alignment: .leading, spacing: AppSpacing.xs) {
                    Label("Strengths", systemImage: "checkmark.circle.fill")
                        .font(AppTypography.subheadline)
                        .foregroundColor(.scoreExcellent)

                    ForEach(feedback.strengths, id: \.self) { strength in
                        HStack(spacing: AppSpacing.xs) {
                            Image(systemName: "star.fill")
                                .font(.system(size: 10))
                                .foregroundColor(.yellow)
                            Text(strength)
                                .font(AppTypography.body)
                        }
                    }
                }
            }

            // Areas to Improve
            if !feedback.improvements.isEmpty {
                VStack(alignment: .leading, spacing: AppSpacing.xs) {
                    Label("Focus Areas", systemImage: "target")
                        .font(AppTypography.subheadline)
                        .foregroundColor(.scoreFair)

                    ForEach(feedback.improvements.prefix(3)) { improvement in
                        ImprovementRow(improvement: improvement) {
                            onDrillTap(improvement)
                        }
                    }
                }
            }

            Divider()

            // Next Session Tip
            VStack(alignment: .leading, spacing: AppSpacing.xs) {
                Label("For Next Time", systemImage: "arrow.right.circle.fill")
                    .font(AppTypography.subheadline)
                    .foregroundColor(.neverOBGreen)

                Text(feedback.nextSessionTip)
                    .font(AppTypography.body)
                    .foregroundColor(.secondary)
            }
        }
        .padding(AppSpacing.md)
        .background(Color.cardBackground)
        .cornerRadius(AppCornerRadius.large)
    }
}

// MARK: - Improvement Row
struct ImprovementRow: View {
    let improvement: SwingImprovement
    let onDrillTap: () -> Void

    var body: some View {
        HStack {
            Image(systemName: improvement.category.icon)
                .font(.system(size: 16))
                .foregroundColor(.neverOBGreen)
                .frame(width: 24)

            VStack(alignment: .leading, spacing: 2) {
                Text(improvement.title)
                    .font(AppTypography.subheadline)
                    .foregroundColor(.primary)

                Text(improvement.category.rawValue)
                    .font(AppTypography.caption2)
                    .foregroundColor(.secondary)
            }

            Spacer()

            if !improvement.drills.isEmpty {
                Button(action: onDrillTap) {
                    Text("Drill")
                        .font(AppTypography.caption1)
                        .foregroundColor(.white)
                        .padding(.horizontal, AppSpacing.sm)
                        .padding(.vertical, AppSpacing.xxs)
                        .background(Color.neverOBGreen)
                        .cornerRadius(AppCornerRadius.small)
                }
            }
        }
        .padding(AppSpacing.sm)
        .background(Color.backgroundSecondary)
        .cornerRadius(AppCornerRadius.small)
    }
}

// MARK: - Quick Action Bar
struct QuickActionBar: View {
    let onAction: (QuickAction) -> Void

    var body: some View {
        HStack(spacing: AppSpacing.sm) {
            QuickActionButton(
                icon: "lightbulb.fill",
                title: "Get Tip",
                color: .yellow
            ) {
                onAction(.tip)
            }

            QuickActionButton(
                icon: "figure.golf",
                title: "Drill",
                color: .neverOBGreen
            ) {
                onAction(.drill)
            }

            QuickActionButton(
                icon: "hand.thumbsup.fill",
                title: "Motivate",
                color: .orange
            ) {
                onAction(.encourage)
            }
        }
        .padding(AppSpacing.md)
        .background(Color.cardBackground)
    }
}

enum QuickAction {
    case tip
    case drill
    case encourage
}

struct QuickActionButton: View {
    let icon: String
    let title: String
    let color: Color
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.system(size: 20))
                    .foregroundColor(color)

                Text(title)
                    .font(AppTypography.caption2)
                    .foregroundColor(.primary)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, AppSpacing.sm)
            .background(color.opacity(0.1))
            .cornerRadius(AppCornerRadius.medium)
        }
    }
}

// MARK: - Drill Detail Sheet
struct DrillDetailSheet: View {
    let improvement: SwingImprovement
    @Environment(\.dismiss) var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: AppSpacing.lg) {
                    // Header
                    VStack(alignment: .leading, spacing: AppSpacing.xs) {
                        HStack {
                            Image(systemName: improvement.category.icon)
                                .font(.system(size: 24))
                                .foregroundColor(.neverOBGreen)

                            Text(improvement.category.rawValue)
                                .font(AppTypography.caption1)
                                .foregroundColor(.secondary)
                        }

                        Text(improvement.title)
                            .font(AppTypography.title2)

                        Text(improvement.description)
                            .font(AppTypography.body)
                            .foregroundColor(.secondary)
                    }

                    // Drills
                    ForEach(improvement.drills) { drill in
                        DrillCard(drill: drill)
                    }
                }
                .padding(AppSpacing.md)
            }
            .background(Color.backgroundPrimary)
            .navigationTitle("Practice Drill")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") { dismiss() }
                        .foregroundColor(.neverOBGreen)
                }
            }
        }
        .presentationDetents([.medium, .large])
    }
}

// MARK: - Drill Card
struct DrillCard: View {
    let drill: PracticeDrill

    var body: some View {
        VStack(alignment: .leading, spacing: AppSpacing.md) {
            // Drill Header
            HStack {
                Text(drill.name)
                    .font(AppTypography.headline)

                Spacer()

                // Difficulty Badge
                Text(drill.difficulty.rawValue)
                    .font(AppTypography.caption2)
                    .foregroundColor(.white)
                    .padding(.horizontal, AppSpacing.sm)
                    .padding(.vertical, AppSpacing.xxs)
                    .background(difficultyColor(drill.difficulty))
                    .cornerRadius(AppCornerRadius.small)
            }

            // Duration
            HStack {
                Image(systemName: "clock.fill")
                    .font(.system(size: 12))
                    .foregroundColor(.secondary)
                Text(drill.duration)
                    .font(AppTypography.caption1)
                    .foregroundColor(.secondary)
            }

            // Description
            Text(drill.description)
                .font(AppTypography.body)
                .foregroundColor(.secondary)

            // Steps
            VStack(alignment: .leading, spacing: AppSpacing.sm) {
                Text("Steps")
                    .font(AppTypography.subheadline)
                    .fontWeight(.semibold)

                ForEach(Array(drill.steps.enumerated()), id: \.offset) { index, step in
                    HStack(alignment: .top, spacing: AppSpacing.sm) {
                        Text("\(index + 1)")
                            .font(AppTypography.caption1)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                            .frame(width: 20, height: 20)
                            .background(Color.neverOBGreen)
                            .clipShape(Circle())

                        Text(step)
                            .font(AppTypography.body)
                            .foregroundColor(.primary)
                    }
                }
            }
        }
        .padding(AppSpacing.md)
        .background(Color.cardBackground)
        .cornerRadius(AppCornerRadius.large)
    }

    private func difficultyColor(_ difficulty: DrillDifficulty) -> Color {
        switch difficulty {
        case .beginner: return .green
        case .intermediate: return .orange
        case .advanced: return .red
        }
    }
}

// MARK: - Preview
#Preview {
    CoachView(swing: SwingData(
        clubType: .iron7,
        analysis: SwingAnalysis(
            overallScore: 75,
            phases: SwingPhases(
                addressScore: 80,
                backswingScore: 75,
                topScore: 70,
                downswingScore: 72,
                impactScore: 78,
                followThroughScore: 80
            ),
            feedback: [],
            keyMetrics: SwingMetrics(
                hipRotation: 45,
                shoulderRotation: 90,
                spineAngle: 30,
                tempo: 3.0,
                swingPlane: .onPlane,
                balance: .good
            )
        )
    ))
}
