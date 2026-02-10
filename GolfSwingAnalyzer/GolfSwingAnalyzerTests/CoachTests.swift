import XCTest
@testable import GolfSwingAnalyzer

final class CoachTests: XCTestCase {

    // MARK: - Coach Model Tests

    func testCoachPJExists() {
        let coach = Coach.pj

        XCTAssertEqual(coach.id, "coach-pj")
        XCTAssertEqual(coach.name, "PJ")
        XCTAssertEqual(coach.title, "Virtual Golf Coach")
        XCTAssertFalse(coach.specialties.isEmpty)
    }

    func testCoachPersonality() {
        let coach = Coach.pj

        XCTAssertFalse(coach.personality.greeting.isEmpty)
        XCTAssertFalse(coach.personality.encouragement.isEmpty)
        XCTAssertEqual(coach.personality.style, .friendly)
    }

    // MARK: - CoachMessage Tests

    func testCoachMessageInitialization() {
        let message = CoachMessage(
            type: .greeting,
            content: "Hello!"
        )

        XCTAssertNotNil(message.id)
        XCTAssertNotNil(message.timestamp)
        XCTAssertEqual(message.type, .greeting)
        XCTAssertEqual(message.content, "Hello!")
        XCTAssertNil(message.swingId)
        XCTAssertEqual(message.priority, .normal)
    }

    func testCoachMessageWithSwingId() {
        let swingId = UUID()
        let message = CoachMessage(
            type: .analysis,
            content: "Great swing!",
            swingId: swingId,
            priority: .high
        )

        XCTAssertEqual(message.swingId, swingId)
        XCTAssertEqual(message.priority, .high)
    }

    func testCoachMessageTypes() {
        let types: [CoachMessage.MessageType] = [
            .greeting, .analysis, .tip, .question,
            .encouragement, .drill, .summary
        ]

        for type in types {
            let message = CoachMessage(type: type, content: "Test")
            XCTAssertEqual(message.type, type)
        }
    }

    func testCoachMessageCodable() throws {
        let original = CoachMessage(
            type: .tip,
            content: "Keep your head still",
            priority: .high
        )

        let encoder = JSONEncoder()
        let data = try encoder.encode(original)

        let decoder = JSONDecoder()
        let decoded = try decoder.decode(CoachMessage.self, from: data)

        XCTAssertEqual(decoded.id, original.id)
        XCTAssertEqual(decoded.type, original.type)
        XCTAssertEqual(decoded.content, original.content)
        XCTAssertEqual(decoded.priority, original.priority)
    }

    // MARK: - CoachingSession Tests

    func testCoachingSessionInitialization() {
        let session = CoachingSession()

        XCTAssertNotNil(session.id)
        XCTAssertNotNil(session.startedAt)
        XCTAssertTrue(session.messages.isEmpty)
        XCTAssertNil(session.swingId)
        XCTAssertTrue(session.isActive)
    }

    func testCoachingSessionWithSwingId() {
        let swingId = UUID()
        let session = CoachingSession(swingId: swingId)

        XCTAssertEqual(session.swingId, swingId)
    }

    func testCoachingSessionAddMessage() {
        var session = CoachingSession()
        let message = CoachMessage(type: .greeting, content: "Hello!")

        session.addMessage(message)

        XCTAssertEqual(session.messages.count, 1)
        XCTAssertEqual(session.messages.first?.content, "Hello!")
    }

    // MARK: - SwingImprovement Tests

    func testSwingImprovementInitialization() {
        let improvement = SwingImprovement(
            category: .posture,
            title: "Improve Your Setup",
            description: "Work on your address position",
            priority: 5
        )

        XCTAssertNotNil(improvement.id)
        XCTAssertEqual(improvement.category, .posture)
        XCTAssertEqual(improvement.title, "Improve Your Setup")
        XCTAssertEqual(improvement.priority, 5)
        XCTAssertTrue(improvement.drills.isEmpty)
    }

    func testSwingImprovementWithDrills() {
        let drill = PracticeDrill(
            name: "Mirror Check",
            description: "Practice in front of a mirror",
            duration: "5 minutes",
            difficulty: .beginner,
            steps: ["Step 1", "Step 2"]
        )

        let improvement = SwingImprovement(
            category: .posture,
            title: "Setup",
            description: "Test",
            priority: 3,
            drills: [drill]
        )

        XCTAssertEqual(improvement.drills.count, 1)
        XCTAssertEqual(improvement.drills.first?.name, "Mirror Check")
    }

    // MARK: - ImprovementCategory Tests

    func testImprovementCategoryAllCases() {
        XCTAssertEqual(ImprovementCategory.allCases.count, 10)
    }

    func testImprovementCategoryRawValues() {
        XCTAssertEqual(ImprovementCategory.posture.rawValue, "Posture")
        XCTAssertEqual(ImprovementCategory.grip.rawValue, "Grip")
        XCTAssertEqual(ImprovementCategory.backswing.rawValue, "Backswing")
        XCTAssertEqual(ImprovementCategory.downswing.rawValue, "Downswing")
        XCTAssertEqual(ImprovementCategory.impact.rawValue, "Impact")
        XCTAssertEqual(ImprovementCategory.followThrough.rawValue, "Follow Through")
        XCTAssertEqual(ImprovementCategory.tempo.rawValue, "Tempo")
        XCTAssertEqual(ImprovementCategory.balance.rawValue, "Balance")
        XCTAssertEqual(ImprovementCategory.rotation.rawValue, "Rotation")
        XCTAssertEqual(ImprovementCategory.alignment.rawValue, "Alignment")
    }

    func testImprovementCategoryIcons() {
        for category in ImprovementCategory.allCases {
            XCTAssertFalse(category.icon.isEmpty, "Icon for \(category) should not be empty")
        }
    }

    // MARK: - PracticeDrill Tests

    func testPracticeDrillInitialization() {
        let drill = PracticeDrill(
            name: "Slow Motion Swing",
            description: "Practice at half speed",
            duration: "10 minutes",
            difficulty: .intermediate,
            steps: ["Address", "Backswing", "Downswing", "Finish"]
        )

        XCTAssertNotNil(drill.id)
        XCTAssertEqual(drill.name, "Slow Motion Swing")
        XCTAssertEqual(drill.duration, "10 minutes")
        XCTAssertEqual(drill.difficulty, .intermediate)
        XCTAssertEqual(drill.steps.count, 4)
    }

    func testDrillDifficultyColors() {
        XCTAssertEqual(DrillDifficulty.beginner.color, "green")
        XCTAssertEqual(DrillDifficulty.intermediate.color, "yellow")
        XCTAssertEqual(DrillDifficulty.advanced.color, "red")
    }

    func testPracticeDrillCodable() throws {
        let original = PracticeDrill(
            name: "Test Drill",
            description: "Description",
            duration: "5 min",
            difficulty: .advanced,
            steps: ["Step 1"]
        )

        let encoder = JSONEncoder()
        let data = try encoder.encode(original)

        let decoder = JSONDecoder()
        let decoded = try decoder.decode(PracticeDrill.self, from: data)

        XCTAssertEqual(decoded.id, original.id)
        XCTAssertEqual(decoded.name, original.name)
        XCTAssertEqual(decoded.difficulty, original.difficulty)
    }

    // MARK: - CoachFeedback Tests

    func testCoachFeedbackInitialization() {
        let swingId = UUID()
        let feedback = CoachFeedback(
            swingId: swingId,
            overallComment: "Great swing!",
            improvements: [],
            strengths: ["Good tempo", "Solid impact"],
            focusArea: .tempo,
            nextSessionTip: "Practice more"
        )

        XCTAssertNotNil(feedback.id)
        XCTAssertEqual(feedback.swingId, swingId)
        XCTAssertEqual(feedback.overallComment, "Great swing!")
        XCTAssertEqual(feedback.strengths.count, 2)
        XCTAssertEqual(feedback.focusArea, .tempo)
    }

    func testCoachFeedbackCodable() throws {
        let swingId = UUID()
        let original = CoachFeedback(
            swingId: swingId,
            overallComment: "Test comment",
            improvements: [],
            strengths: ["Strength 1"],
            focusArea: .balance,
            nextSessionTip: "Keep practicing"
        )

        let encoder = JSONEncoder()
        let data = try encoder.encode(original)

        let decoder = JSONDecoder()
        let decoded = try decoder.decode(CoachFeedback.self, from: data)

        XCTAssertEqual(decoded.swingId, original.swingId)
        XCTAssertEqual(decoded.overallComment, original.overallComment)
        XCTAssertEqual(decoded.focusArea, original.focusArea)
    }

    // MARK: - CoachService Tests

    func testCoachServiceGenerateGreeting() async {
        let service = CoachService.shared

        let greeting = await service.generateGreeting()

        XCTAssertEqual(greeting.type, .greeting)
        XCTAssertFalse(greeting.content.isEmpty)
        XCTAssertTrue(greeting.content.contains("PJ"))
    }

    func testCoachServiceGenerateEncouragementExcellent() async {
        let service = CoachService.shared

        let message = await service.generateEncouragement(score: 95)

        XCTAssertEqual(message.type, .encouragement)
        XCTAssertTrue(message.content.contains("Excellent") || message.content.contains("fantastic"))
    }

    func testCoachServiceGenerateEncouragementGood() async {
        let service = CoachService.shared

        let message = await service.generateEncouragement(score: 75)

        XCTAssertEqual(message.type, .encouragement)
        XCTAssertTrue(message.content.contains("Good") || message.content.contains("improvement"))
    }

    func testCoachServiceGenerateEncouragementNeedsWork() async {
        let service = CoachService.shared

        let message = await service.generateEncouragement(score: 50)

        XCTAssertEqual(message.type, .encouragement)
        XCTAssertFalse(message.content.isEmpty)
    }

    func testCoachServiceGenerateTip() async {
        let service = CoachService.shared

        for category in ImprovementCategory.allCases {
            let message = await service.generateTipMessage(for: category)

            XCTAssertEqual(message.type, .tip)
            XCTAssertFalse(message.content.isEmpty, "Tip for \(category) should not be empty")
        }
    }

    func testCoachServiceGenerateFeedback() async {
        let service = CoachService.shared

        let swing = createTestSwingWithAnalysis()
        let feedback = await service.generateFeedback(for: swing)

        XCTAssertEqual(feedback.swingId, swing.id)
        XCTAssertFalse(feedback.overallComment.isEmpty)
        XCTAssertFalse(feedback.nextSessionTip.isEmpty)
    }

    func testCoachServiceGenerateFeedbackWithoutAnalysis() async {
        let service = CoachService.shared

        let swing = SwingData(clubType: .driver)
        let feedback = await service.generateFeedback(for: swing)

        XCTAssertEqual(feedback.swingId, swing.id)
        XCTAssertTrue(feedback.improvements.isEmpty)
    }

    func testCoachServiceGenerateAnalysisMessage() async {
        let service = CoachService.shared

        let swing = createTestSwingWithAnalysis()
        let message = await service.generateAnalysisMessage(for: swing)

        XCTAssertEqual(message.type, .analysis)
        XCTAssertEqual(message.swingId, swing.id)
        XCTAssertFalse(message.content.isEmpty)
    }

    func testCoachServiceGenerateQuestionMessage() async {
        let service = CoachService.shared

        let swing = createTestSwingWithAnalysis()
        let message = await service.generateQuestionMessage(for: swing)

        XCTAssertEqual(message.type, .question)
        XCTAssertTrue(message.content.contains("?"))
    }

    // MARK: - CoachManager Tests

    @MainActor
    func testCoachManagerSharedInstance() {
        let instance1 = CoachManager.shared
        let instance2 = CoachManager.shared

        XCTAssertTrue(instance1 === instance2)
    }

    @MainActor
    func testCoachManagerStartSession() {
        let manager = CoachManager.shared

        manager.startSession()

        XCTAssertNotNil(manager.currentSession)
        XCTAssertTrue(manager.currentSession?.isActive ?? false)
    }

    @MainActor
    func testCoachManagerStartSessionWithSwing() {
        let manager = CoachManager.shared
        let swing = SwingData(clubType: .iron7)

        manager.startSession(for: swing)

        XCTAssertEqual(manager.currentSession?.swingId, swing.id)
    }

    @MainActor
    func testCoachManagerEndSession() {
        let manager = CoachManager.shared

        manager.startSession()
        manager.endSession()

        XCTAssertNil(manager.currentSession)
    }

    // MARK: - Helper Methods

    private func createTestSwingWithAnalysis() -> SwingData {
        var swing = SwingData(clubType: .iron7)
        swing.analysis = SwingAnalysis(
            overallScore: 75,
            phases: SwingPhases(
                addressScore: 80,
                backswingScore: 72,
                topScore: 70,
                downswingScore: 75,
                impactScore: 78,
                followThroughScore: 82
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
        return swing
    }
}
