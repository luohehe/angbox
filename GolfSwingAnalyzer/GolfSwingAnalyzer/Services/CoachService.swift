import Foundation

// MARK: - Coach Service
actor CoachService {
    static let shared = CoachService()

    private let coach = Coach.pj

    private init() {}

    // MARK: - Generate Feedback for Swing

    func generateFeedback(for swing: SwingData) async -> CoachFeedback {
        guard let analysis = swing.analysis else {
            return createDefaultFeedback(for: swing.id)
        }

        let improvements = generateImprovements(from: analysis, clubType: swing.clubType)
        let strengths = identifyStrengths(from: analysis)
        let focusArea = determineFocusArea(from: analysis)
        let overallComment = generateOverallComment(
            score: analysis.overallScore,
            clubType: swing.clubType,
            focusArea: focusArea
        )
        let nextTip = generateNextSessionTip(focusArea: focusArea)

        return CoachFeedback(
            swingId: swing.id,
            overallComment: overallComment,
            improvements: improvements,
            strengths: strengths,
            focusArea: focusArea,
            nextSessionTip: nextTip
        )
    }

    // MARK: - Generate Coaching Messages

    func generateGreeting() -> CoachMessage {
        CoachMessage(
            type: .greeting,
            content: "\(coach.personality.greeting) Let's work on improving your swing today!"
        )
    }

    func generateAnalysisMessage(for swing: SwingData) -> CoachMessage {
        guard let analysis = swing.analysis else {
            return CoachMessage(
                type: .analysis,
                content: "I couldn't analyze this swing. Try recording again with better lighting and camera angle.",
                swingId: swing.id
            )
        }

        let comment = generateDetailedAnalysis(analysis: analysis, clubType: swing.clubType)
        return CoachMessage(
            type: .analysis,
            content: comment,
            swingId: swing.id,
            priority: analysis.overallScore < 60 ? .high : .normal
        )
    }

    func generateQuestionMessage(for swing: SwingData) -> CoachMessage {
        guard let analysis = swing.analysis else {
            return CoachMessage(
                type: .question,
                content: "How did that swing feel to you?",
                swingId: swing.id
            )
        }

        let question = generateContextualQuestion(analysis: analysis)
        return CoachMessage(
            type: .question,
            content: question,
            swingId: swing.id
        )
    }

    func generateTipMessage(for category: ImprovementCategory) -> CoachMessage {
        let tip = getTipForCategory(category)
        return CoachMessage(
            type: .tip,
            content: tip
        )
    }

    func generateEncouragement(score: Int) -> CoachMessage {
        let encouragement: String
        if score >= 90 {
            encouragement = "Excellent swing! You're really getting the hang of this. Keep up the fantastic work!"
        } else if score >= 80 {
            encouragement = "Great job! That was a solid swing. A few small tweaks and you'll be even better."
        } else if score >= 70 {
            encouragement = "Good effort! I can see improvement. Let's focus on one thing at a time."
        } else if score >= 60 {
            encouragement = "You're on the right track! Golf is a journey. Let's work on the fundamentals."
        } else {
            encouragement = "Don't worry, every pro started somewhere. Let's break this down and build good habits."
        }

        return CoachMessage(
            type: .encouragement,
            content: encouragement
        )
    }

    func generateDrillMessage(for improvement: SwingImprovement) -> CoachMessage {
        guard let drill = improvement.drills.first else {
            return CoachMessage(
                type: .drill,
                content: "Practice your \(improvement.category.rawValue.lowercased()) with slow, deliberate swings."
            )
        }

        let drillDescription = """
        Try this drill: \(drill.name)

        \(drill.description)

        Duration: \(drill.duration)
        """

        return CoachMessage(
            type: .drill,
            content: drillDescription
        )
    }

    // MARK: - Private Helpers

    private func generateImprovements(from analysis: SwingAnalysis, clubType: ClubType) -> [SwingImprovement] {
        var improvements: [SwingImprovement] = []

        // Check each phase and add improvements for low scores
        let phases = analysis.phases

        if phases.addressScore < 75 {
            improvements.append(createPostureImprovement(score: phases.addressScore))
        }

        if phases.backswingScore < 75 {
            improvements.append(createBackswingImprovement(score: phases.backswingScore))
        }

        if phases.topScore < 75 {
            improvements.append(createTopImprovement(score: phases.topScore))
        }

        if phases.downswingScore < 75 {
            improvements.append(createDownswingImprovement(score: phases.downswingScore))
        }

        if phases.impactScore < 75 {
            improvements.append(createImpactImprovement(score: phases.impactScore))
        }

        if phases.followThroughScore < 75 {
            improvements.append(createFollowThroughImprovement(score: phases.followThroughScore))
        }

        // Check metrics
        if analysis.keyMetrics.tempo < 2.5 || analysis.keyMetrics.tempo > 3.5 {
            improvements.append(createTempoImprovement(tempo: analysis.keyMetrics.tempo))
        }

        if analysis.keyMetrics.balance != .excellent && analysis.keyMetrics.balance != .good {
            improvements.append(createBalanceImprovement(balance: analysis.keyMetrics.balance))
        }

        // Sort by priority
        return improvements.sorted { $0.priority > $1.priority }
    }

    private func identifyStrengths(from analysis: SwingAnalysis) -> [String] {
        var strengths: [String] = []
        let phases = analysis.phases

        if phases.addressScore >= 85 {
            strengths.append("Excellent setup position")
        }
        if phases.backswingScore >= 85 {
            strengths.append("Smooth backswing")
        }
        if phases.topScore >= 85 {
            strengths.append("Great position at the top")
        }
        if phases.downswingScore >= 85 {
            strengths.append("Powerful downswing")
        }
        if phases.impactScore >= 85 {
            strengths.append("Solid impact position")
        }
        if phases.followThroughScore >= 85 {
            strengths.append("Complete follow through")
        }

        let metrics = analysis.keyMetrics
        if metrics.swingPlane == .onPlane {
            strengths.append("On-plane swing path")
        }
        if metrics.balance == .excellent {
            strengths.append("Outstanding balance")
        }
        if metrics.tempo >= 2.8 && metrics.tempo <= 3.2 {
            strengths.append("Perfect tempo")
        }

        return strengths
    }

    private func determineFocusArea(from analysis: SwingAnalysis) -> ImprovementCategory {
        let phases = analysis.phases
        let scores: [(ImprovementCategory, Int)] = [
            (.posture, phases.addressScore),
            (.backswing, phases.backswingScore),
            (.rotation, phases.topScore),
            (.downswing, phases.downswingScore),
            (.impact, phases.impactScore),
            (.followThrough, phases.followThroughScore)
        ]

        // Return the category with the lowest score
        return scores.min { $0.1 < $1.1 }?.0 ?? .posture
    }

    private func generateOverallComment(score: Int, clubType: ClubType, focusArea: ImprovementCategory) -> String {
        let clubName = clubType.displayName

        if score >= 90 {
            return "That was an excellent \(clubName) swing! Your fundamentals are really solid. Let's fine-tune a few details to make it even better."
        } else if score >= 80 {
            return "Nice \(clubName) swing! You're showing good technique overall. I noticed we can work on your \(focusArea.rawValue.lowercased()) to take it to the next level."
        } else if score >= 70 {
            return "Good effort with the \(clubName)! I see potential here. Let's focus on improving your \(focusArea.rawValue.lowercased()) - that will make the biggest difference."
        } else if score >= 60 {
            return "That \(clubName) swing has some good elements. I want to help you work on your \(focusArea.rawValue.lowercased()). Small changes will lead to big improvements!"
        } else {
            return "Let's slow down and work on the basics with your \(clubName). I'm going to help you build a solid foundation, starting with your \(focusArea.rawValue.lowercased())."
        }
    }

    private func generateDetailedAnalysis(analysis: SwingAnalysis, clubType: ClubType) -> String {
        let phases = analysis.phases
        let metrics = analysis.keyMetrics

        var parts: [String] = []

        // Score summary
        parts.append("Your overall score is \(analysis.overallScore)/100 (\(analysis.scoreGrade)).")

        // Best phase
        let phaseScores = [
            ("address", phases.addressScore),
            ("backswing", phases.backswingScore),
            ("top position", phases.topScore),
            ("downswing", phases.downswingScore),
            ("impact", phases.impactScore),
            ("follow through", phases.followThroughScore)
        ]
        if let best = phaseScores.max(by: { $0.1 < $1.1 }) {
            parts.append("Your \(best.0) looks particularly good at \(best.1) points.")
        }

        // Tempo feedback
        if metrics.tempo < 2.5 {
            parts.append("Your tempo is a bit quick - try to slow down your backswing.")
        } else if metrics.tempo > 3.5 {
            parts.append("Your tempo could be a bit quicker for more power generation.")
        } else {
            parts.append("Your tempo is in a good range at \(String(format: "%.1f", metrics.tempo)):1.")
        }

        // Balance feedback
        switch metrics.balance {
        case .excellent:
            parts.append("Excellent balance throughout the swing!")
        case .good:
            parts.append("Good balance - keep working on staying centered.")
        case .fair:
            parts.append("Your balance needs attention - focus on staying grounded.")
        case .poor:
            parts.append("Balance is a priority - let's work on your foundation first.")
        }

        return parts.joined(separator: " ")
    }

    private func generateContextualQuestion(analysis: SwingAnalysis) -> String {
        let questions: [String]

        if analysis.overallScore >= 80 {
            questions = [
                "Did that feel comfortable? Consistency comes from repeating what feels natural.",
                "What were you focusing on during that swing?",
                "How did the ball flight look? Did it match what you intended?"
            ]
        } else if analysis.overallScore >= 60 {
            questions = [
                "Where in the swing did you feel least confident?",
                "Did you feel balanced at the finish position?",
                "Was there any tension in your grip or shoulders?"
            ]
        } else {
            questions = [
                "Let's slow down - what part of the swing feels most challenging?",
                "Are you comfortable with your grip and stance?",
                "Would you like to work on one specific phase of the swing?"
            ]
        }

        return questions.randomElement() ?? "How did that swing feel to you?"
    }

    private func generateNextSessionTip(focusArea: ImprovementCategory) -> String {
        switch focusArea {
        case .posture:
            return "Next time, spend 5 minutes on your setup before hitting balls. A good address position sets up everything else."
        case .grip:
            return "Practice your grip at home in front of a mirror. Feel the connection with the club."
        case .backswing:
            return "Try some half-swing drills to feel the proper backswing path."
        case .downswing:
            return "Focus on starting the downswing with your lower body. The arms will follow."
        case .impact:
            return "Practice impact position holds to build muscle memory for solid contact."
        case .followThrough:
            return "Make full swings focusing only on your finish position. Let everything else flow."
        case .tempo:
            return "Use a metronome app and practice swinging to a consistent rhythm."
        case .balance:
            return "Try hitting balls with your feet together to improve balance awareness."
        case .rotation:
            return "Work on hip and shoulder rotation drills to improve your coil."
        case .alignment:
            return "Use alignment sticks during practice to groove proper aim."
        }
    }

    private func getTipForCategory(_ category: ImprovementCategory) -> String {
        switch category {
        case .posture:
            return "Keep your spine angle consistent throughout the swing. Think of rotating around your spine like a door on its hinges."
        case .grip:
            return "Hold the club firmly but not too tight - imagine holding a tube of toothpaste without squeezing any out."
        case .backswing:
            return "Start your takeaway with your shoulders, not your hands. Keep the clubhead outside your hands in the early backswing."
        case .downswing:
            return "Initiate the downswing with your lower body. Feel like your hips lead and your arms follow."
        case .impact:
            return "Your hands should be ahead of the clubhead at impact. This creates that powerful, compressed ball flight."
        case .followThrough:
            return "Finish with your belt buckle facing the target and your weight on your front foot. Hold the finish!"
        case .tempo:
            return "Think 'low and slow' on the backswing. A 3:1 ratio (backswing to downswing) is ideal for most golfers."
        case .balance:
            return "You should be able to hold your finish position for 3 seconds. If you're falling, you're swinging too hard."
        case .rotation:
            return "Feel like you're turning your back to the target at the top. Full shoulder turn with minimal hip turn creates power."
        case .alignment:
            return "Your feet, hips, and shoulders should all be parallel to your target line. Use a club on the ground to check."
        }
    }

    // MARK: - Improvement Creators

    private func createPostureImprovement(score: Int) -> SwingImprovement {
        SwingImprovement(
            category: .posture,
            title: "Improve Your Setup",
            description: "Your address position needs attention. A solid setup is the foundation of a great swing.",
            priority: 5,
            drills: [
                PracticeDrill(
                    name: "Mirror Check Drill",
                    description: "Practice your setup in front of a mirror. Check your spine angle, knee flex, and arm hang.",
                    duration: "5 minutes",
                    difficulty: .beginner,
                    steps: [
                        "Stand in front of a full-length mirror",
                        "Take your address position without a club",
                        "Check: knees slightly flexed, spine tilted from hips",
                        "Arms should hang naturally below shoulders",
                        "Hold for 10 seconds, repeat 10 times"
                    ]
                )
            ]
        )
    }

    private func createBackswingImprovement(score: Int) -> SwingImprovement {
        SwingImprovement(
            category: .backswing,
            title: "Smooth Backswing Path",
            description: "Focus on a one-piece takeaway and keeping the club on plane during the backswing.",
            priority: 4,
            drills: [
                PracticeDrill(
                    name: "Slow Motion Backswing",
                    description: "Make backswings at 25% speed, stopping at key checkpoints.",
                    duration: "10 minutes",
                    difficulty: .beginner,
                    steps: [
                        "Take your normal address position",
                        "Move the club back using only your shoulders",
                        "Stop when hands reach hip height - check club position",
                        "Continue to top - check shoulder turn",
                        "Return slowly to address"
                    ]
                )
            ]
        )
    }

    private func createTopImprovement(score: Int) -> SwingImprovement {
        SwingImprovement(
            category: .rotation,
            title: "Better Position at the Top",
            description: "Work on achieving a full shoulder turn while maintaining your spine angle.",
            priority: 3,
            drills: [
                PracticeDrill(
                    name: "Back to Target Drill",
                    description: "Focus on turning your back fully to the target at the top of the swing.",
                    duration: "10 minutes",
                    difficulty: .intermediate,
                    steps: [
                        "Take address position",
                        "Make a backswing focusing on turning your back to the target",
                        "Feel your left shoulder (for righties) under your chin",
                        "Hold for 2 seconds",
                        "Return to address without hitting a ball"
                    ]
                )
            ]
        )
    }

    private func createDownswingImprovement(score: Int) -> SwingImprovement {
        SwingImprovement(
            category: .downswing,
            title: "Proper Downswing Sequence",
            description: "Initiate the downswing with your lower body for more power and consistency.",
            priority: 4,
            drills: [
                PracticeDrill(
                    name: "Step Drill",
                    description: "Learn to start the downswing with your lower body using this classic drill.",
                    duration: "15 minutes",
                    difficulty: .intermediate,
                    steps: [
                        "Address the ball with feet together",
                        "Make your backswing",
                        "As you start down, step your front foot toward the target",
                        "This forces your lower body to lead",
                        "Hit balls focusing on the step-then-swing feeling"
                    ]
                )
            ]
        )
    }

    private func createImpactImprovement(score: Int) -> SwingImprovement {
        SwingImprovement(
            category: .impact,
            title: "Solid Impact Position",
            description: "Achieve a powerful impact with hands ahead and weight forward.",
            priority: 5,
            drills: [
                PracticeDrill(
                    name: "Impact Bag Drill",
                    description: "Build the feel of a proper impact position with this feedback drill.",
                    duration: "10 minutes",
                    difficulty: .beginner,
                    steps: [
                        "Use an impact bag or old pillow",
                        "Take your address position with an iron",
                        "Make slow swings into the bag, stopping at impact",
                        "Check: weight on front foot, hands ahead of clubhead",
                        "Hold the position, feel the pressure"
                    ]
                )
            ]
        )
    }

    private func createFollowThroughImprovement(score: Int) -> SwingImprovement {
        SwingImprovement(
            category: .followThrough,
            title: "Complete Your Swing",
            description: "A full, balanced finish indicates a good swing. Focus on finishing high and balanced.",
            priority: 2,
            drills: [
                PracticeDrill(
                    name: "Finish and Hold",
                    description: "Every swing should end in a balanced, held finish position.",
                    duration: "10 minutes",
                    difficulty: .beginner,
                    steps: [
                        "Make full swings",
                        "Focus only on your finish position",
                        "Hold finish for 3 seconds every swing",
                        "Check: weight on front foot, belt facing target",
                        "If you can't hold it, swing easier"
                    ]
                )
            ]
        )
    }

    private func createTempoImprovement(tempo: Double) -> SwingImprovement {
        let isTooFast = tempo < 2.5

        return SwingImprovement(
            category: .tempo,
            title: isTooFast ? "Slow Down Your Tempo" : "Add Some Speed",
            description: isTooFast
                ? "Your swing is too quick. A smooth tempo leads to better contact and more consistency."
                : "Your swing could use a bit more energy. Don't be afraid to accelerate through the ball.",
            priority: 3,
            drills: [
                PracticeDrill(
                    name: "Count Drill",
                    description: "Use counting to establish a consistent tempo.",
                    duration: "15 minutes",
                    difficulty: .beginner,
                    steps: [
                        "Count '1' at address",
                        "Count '2' at the top of backswing",
                        "Count '3' at impact",
                        "The time from 1-2 should be longer than 2-3",
                        "Aim for a 3:1 ratio backswing to downswing"
                    ]
                )
            ]
        )
    }

    private func createBalanceImprovement(balance: BalanceQuality) -> SwingImprovement {
        SwingImprovement(
            category: .balance,
            title: "Improve Your Balance",
            description: "Good balance is essential for consistent contact. You should be able to hold your finish.",
            priority: 4,
            drills: [
                PracticeDrill(
                    name: "Feet Together Drill",
                    description: "Hit balls with your feet together to develop better balance.",
                    duration: "10 minutes",
                    difficulty: .intermediate,
                    steps: [
                        "Place your feet together, touching",
                        "Use a 7-iron and tee the ball up",
                        "Make smooth, 3/4 swings",
                        "Focus on maintaining balance throughout",
                        "If you fall over, swing easier"
                    ]
                )
            ]
        )
    }

    private func createDefaultFeedback(for swingId: UUID) -> CoachFeedback {
        CoachFeedback(
            swingId: swingId,
            overallComment: "I couldn't analyze this swing fully. Make sure you're in good lighting and the camera can see your full body throughout the swing.",
            improvements: [],
            strengths: [],
            focusArea: .posture,
            nextSessionTip: "Try recording again with better camera positioning. I want to help you improve!"
        )
    }
}

// MARK: - Coach Manager (Observable)
@MainActor
class CoachManager: ObservableObject {
    static let shared = CoachManager()

    @Published var currentSession: CoachingSession?
    @Published var messages: [CoachMessage] = []
    @Published var currentFeedback: CoachFeedback?
    @Published var isGenerating = false

    private let service = CoachService.shared

    private init() {}

    func startSession(for swing: SwingData? = nil) {
        currentSession = CoachingSession(swingId: swing?.id)
        messages = []

        // Add greeting
        Task {
            let greeting = await service.generateGreeting()
            messages.append(greeting)
        }
    }

    func analyzeSwing(_ swing: SwingData) async {
        isGenerating = true

        // Generate and add analysis message
        let analysisMessage = await service.generateAnalysisMessage(for: swing)
        messages.append(analysisMessage)

        // Generate encouragement
        if let score = swing.analysis?.overallScore {
            let encouragement = await service.generateEncouragement(score: score)
            messages.append(encouragement)
        }

        // Generate question
        let question = await service.generateQuestionMessage(for: swing)
        messages.append(question)

        // Generate full feedback
        currentFeedback = await service.generateFeedback(for: swing)

        isGenerating = false
    }

    func requestTip(for category: ImprovementCategory) async {
        let tip = await service.generateTipMessage(for: category)
        messages.append(tip)
    }

    func requestDrill(for improvement: SwingImprovement) async {
        let drill = await service.generateDrillMessage(for: improvement)
        messages.append(drill)
    }

    func endSession() {
        currentSession?.isActive = false
        currentSession = nil
    }
}
