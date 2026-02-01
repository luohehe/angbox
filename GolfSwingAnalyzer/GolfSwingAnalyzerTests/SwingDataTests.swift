import XCTest
@testable import GolfSwingAnalyzer

final class SwingDataTests: XCTestCase {

    // MARK: - SwingData Tests

    func testSwingDataInitialization() {
        let swing = SwingData()

        XCTAssertNotNil(swing.id)
        XCTAssertNotNil(swing.recordedAt)
        XCTAssertNil(swing.videoURL)
        XCTAssertEqual(swing.duration, 0)
        XCTAssertNil(swing.analysis)
    }

    func testSwingDataWithVideoURL() {
        let url = URL(fileURLWithPath: "/tmp/test_video.mov")
        let duration: TimeInterval = 5.5

        let swing = SwingData(videoURL: url, duration: duration)

        XCTAssertEqual(swing.videoURL, url)
        XCTAssertEqual(swing.duration, duration)
    }

    func testSwingDataCodable() throws {
        let originalSwing = SwingData(
            videoURL: URL(fileURLWithPath: "/tmp/test.mov"),
            duration: 3.5
        )

        let encoder = JSONEncoder()
        let data = try encoder.encode(originalSwing)

        let decoder = JSONDecoder()
        let decodedSwing = try decoder.decode(SwingData.self, from: data)

        XCTAssertEqual(decodedSwing.id, originalSwing.id)
        XCTAssertEqual(decodedSwing.videoURL, originalSwing.videoURL)
        XCTAssertEqual(decodedSwing.duration, originalSwing.duration)
    }

    // MARK: - SwingAnalysis Tests

    func testSwingAnalysisScoreGrade() {
        let phases = SwingPhases(
            addressScore: 80,
            backswingScore: 80,
            topScore: 80,
            downswingScore: 80,
            impactScore: 80,
            followThroughScore: 80
        )
        let metrics = createDefaultMetrics()

        let excellentAnalysis = SwingAnalysis(
            overallScore: 95,
            phases: phases,
            feedback: [],
            keyMetrics: metrics
        )
        XCTAssertEqual(excellentAnalysis.scoreGrade, "Excellent")

        let greatAnalysis = SwingAnalysis(
            overallScore: 85,
            phases: phases,
            feedback: [],
            keyMetrics: metrics
        )
        XCTAssertEqual(greatAnalysis.scoreGrade, "Great")

        let goodAnalysis = SwingAnalysis(
            overallScore: 75,
            phases: phases,
            feedback: [],
            keyMetrics: metrics
        )
        XCTAssertEqual(goodAnalysis.scoreGrade, "Good")

        let fairAnalysis = SwingAnalysis(
            overallScore: 65,
            phases: phases,
            feedback: [],
            keyMetrics: metrics
        )
        XCTAssertEqual(fairAnalysis.scoreGrade, "Fair")

        let needsWorkAnalysis = SwingAnalysis(
            overallScore: 50,
            phases: phases,
            feedback: [],
            keyMetrics: metrics
        )
        XCTAssertEqual(needsWorkAnalysis.scoreGrade, "Needs Work")
    }

    func testSwingAnalysisScoreColor() {
        let phases = createDefaultPhases()
        let metrics = createDefaultMetrics()

        let scores = [95, 85, 75, 65, 50]
        let expectedColors = ["green", "blue", "yellow", "orange", "red"]

        for (score, expectedColor) in zip(scores, expectedColors) {
            let analysis = SwingAnalysis(
                overallScore: score,
                phases: phases,
                feedback: [],
                keyMetrics: metrics
            )
            XCTAssertEqual(analysis.scoreColor, expectedColor, "Score \(score) should have color \(expectedColor)")
        }
    }

    func testSwingAnalysisCodable() throws {
        let phases = createDefaultPhases()
        let metrics = createDefaultMetrics()
        let feedback = [
            SwingFeedback(
                category: .posture,
                severity: .positive,
                title: "Test",
                description: "Test description",
                suggestion: "Test suggestion"
            )
        ]

        let original = SwingAnalysis(
            overallScore: 85,
            phases: phases,
            feedback: feedback,
            keyMetrics: metrics
        )

        let encoder = JSONEncoder()
        let data = try encoder.encode(original)

        let decoder = JSONDecoder()
        let decoded = try decoder.decode(SwingAnalysis.self, from: data)

        XCTAssertEqual(decoded.overallScore, original.overallScore)
        XCTAssertEqual(decoded.phases.addressScore, original.phases.addressScore)
        XCTAssertEqual(decoded.feedback.count, original.feedback.count)
    }

    // MARK: - SwingPhases Tests

    func testSwingPhasesAllScores() {
        let phases = SwingPhases(
            addressScore: 90,
            backswingScore: 85,
            topScore: 80,
            downswingScore: 75,
            impactScore: 70,
            followThroughScore: 65
        )

        XCTAssertEqual(phases.addressScore, 90)
        XCTAssertEqual(phases.backswingScore, 85)
        XCTAssertEqual(phases.topScore, 80)
        XCTAssertEqual(phases.downswingScore, 75)
        XCTAssertEqual(phases.impactScore, 70)
        XCTAssertEqual(phases.followThroughScore, 65)
    }

    // MARK: - SwingMetrics Tests

    func testSwingMetricsValues() {
        let metrics = SwingMetrics(
            hipRotation: 45.0,
            shoulderRotation: 90.0,
            spineAngle: 30.0,
            tempo: 3.0,
            swingPlane: .onPlane,
            balance: .excellent
        )

        XCTAssertEqual(metrics.hipRotation, 45.0)
        XCTAssertEqual(metrics.shoulderRotation, 90.0)
        XCTAssertEqual(metrics.spineAngle, 30.0)
        XCTAssertEqual(metrics.tempo, 3.0)
        XCTAssertEqual(metrics.swingPlane, .onPlane)
        XCTAssertEqual(metrics.balance, .excellent)
    }

    // MARK: - SwingPlaneQuality Tests

    func testSwingPlaneQualityRawValues() {
        XCTAssertEqual(SwingPlaneQuality.onPlane.rawValue, "On Plane")
        XCTAssertEqual(SwingPlaneQuality.slightlyOver.rawValue, "Slightly Over")
        XCTAssertEqual(SwingPlaneQuality.slightlyUnder.rawValue, "Slightly Under")
        XCTAssertEqual(SwingPlaneQuality.over.rawValue, "Over the Top")
        XCTAssertEqual(SwingPlaneQuality.under.rawValue, "Too Flat")
    }

    // MARK: - BalanceQuality Tests

    func testBalanceQualityRawValues() {
        XCTAssertEqual(BalanceQuality.excellent.rawValue, "Excellent")
        XCTAssertEqual(BalanceQuality.good.rawValue, "Good")
        XCTAssertEqual(BalanceQuality.fair.rawValue, "Fair")
        XCTAssertEqual(BalanceQuality.poor.rawValue, "Poor")
    }

    // MARK: - SwingFeedback Tests

    func testSwingFeedbackInitialization() {
        let feedback = SwingFeedback(
            category: .backswing,
            severity: .warning,
            title: "Test Title",
            description: "Test Description",
            suggestion: "Test Suggestion"
        )

        XCTAssertNotNil(feedback.id)
        XCTAssertEqual(feedback.category, .backswing)
        XCTAssertEqual(feedback.severity, .warning)
        XCTAssertEqual(feedback.title, "Test Title")
        XCTAssertEqual(feedback.description, "Test Description")
        XCTAssertEqual(feedback.suggestion, "Test Suggestion")
    }

    // MARK: - FeedbackCategory Tests

    func testFeedbackCategoryRawValues() {
        XCTAssertEqual(FeedbackCategory.posture.rawValue, "Posture")
        XCTAssertEqual(FeedbackCategory.grip.rawValue, "Grip")
        XCTAssertEqual(FeedbackCategory.backswing.rawValue, "Backswing")
        XCTAssertEqual(FeedbackCategory.downswing.rawValue, "Downswing")
        XCTAssertEqual(FeedbackCategory.impact.rawValue, "Impact")
        XCTAssertEqual(FeedbackCategory.followThrough.rawValue, "Follow Through")
        XCTAssertEqual(FeedbackCategory.tempo.rawValue, "Tempo")
        XCTAssertEqual(FeedbackCategory.balance.rawValue, "Balance")
    }

    // MARK: - FeedbackSeverity Tests

    func testFeedbackSeverityRawValues() {
        XCTAssertEqual(FeedbackSeverity.positive.rawValue, "positive")
        XCTAssertEqual(FeedbackSeverity.suggestion.rawValue, "suggestion")
        XCTAssertEqual(FeedbackSeverity.warning.rawValue, "warning")
        XCTAssertEqual(FeedbackSeverity.critical.rawValue, "critical")
    }

    // MARK: - PoseKeypoint Tests

    func testPoseKeypointInitialization() {
        let keypoint = PoseKeypoint(
            name: "left_shoulder",
            position: CGPoint(x: 0.5, y: 0.5),
            confidence: 0.95
        )

        XCTAssertEqual(keypoint.name, "left_shoulder")
        XCTAssertEqual(keypoint.position.x, 0.5)
        XCTAssertEqual(keypoint.position.y, 0.5)
        XCTAssertEqual(keypoint.confidence, 0.95)
    }

    // MARK: - FramePose Tests

    func testFramePoseInitialization() {
        let keypoints = [
            PoseKeypoint(name: "nose", position: CGPoint(x: 0.5, y: 0.2), confidence: 0.9),
            PoseKeypoint(name: "neck", position: CGPoint(x: 0.5, y: 0.3), confidence: 0.85)
        ]

        let framePose = FramePose(timestamp: 1.5, keypoints: keypoints)

        XCTAssertEqual(framePose.timestamp, 1.5)
        XCTAssertEqual(framePose.keypoints.count, 2)
    }

    // MARK: - ClubType Tests

    func testClubTypeAllCases() {
        // Verify all 16 club types exist
        XCTAssertEqual(ClubType.allCases.count, 16)
    }

    func testClubTypeRawValues() {
        XCTAssertEqual(ClubType.driver.rawValue, "Driver")
        XCTAssertEqual(ClubType.wood3.rawValue, "3 Wood")
        XCTAssertEqual(ClubType.wood5.rawValue, "5 Wood")
        XCTAssertEqual(ClubType.hybrid.rawValue, "Hybrid")
        XCTAssertEqual(ClubType.iron7.rawValue, "7 Iron")
        XCTAssertEqual(ClubType.pitchingWedge.rawValue, "PW")
        XCTAssertEqual(ClubType.sandWedge.rawValue, "SW")
        XCTAssertEqual(ClubType.putter.rawValue, "Putter")
    }

    func testClubTypeCategories() {
        XCTAssertEqual(ClubType.driver.category, .driver)
        XCTAssertEqual(ClubType.wood3.category, .fairwayWood)
        XCTAssertEqual(ClubType.wood5.category, .fairwayWood)
        XCTAssertEqual(ClubType.hybrid.category, .hybrid)
        XCTAssertEqual(ClubType.iron3.category, .iron)
        XCTAssertEqual(ClubType.iron7.category, .iron)
        XCTAssertEqual(ClubType.pitchingWedge.category, .wedge)
        XCTAssertEqual(ClubType.sandWedge.category, .wedge)
        XCTAssertEqual(ClubType.putter.category, .putter)
    }

    func testClubTypeIcons() {
        // Each category should have an icon
        XCTAssertFalse(ClubType.driver.icon.isEmpty)
        XCTAssertFalse(ClubType.wood3.icon.isEmpty)
        XCTAssertFalse(ClubType.hybrid.icon.isEmpty)
        XCTAssertFalse(ClubType.iron7.icon.isEmpty)
        XCTAssertFalse(ClubType.sandWedge.icon.isEmpty)
        XCTAssertFalse(ClubType.putter.icon.isEmpty)
    }

    func testClubTypeDisplayName() {
        XCTAssertEqual(ClubType.driver.displayName, "Driver")
        XCTAssertEqual(ClubType.iron7.displayName, "7 Iron")
        XCTAssertEqual(ClubType.pitchingWedge.displayName, "PW")
    }

    func testClubTypeCodable() throws {
        let clubType = ClubType.iron7

        let encoder = JSONEncoder()
        let data = try encoder.encode(clubType)

        let decoder = JSONDecoder()
        let decoded = try decoder.decode(ClubType.self, from: data)

        XCTAssertEqual(decoded, clubType)
    }

    func testClubTypeIdentifiable() {
        XCTAssertEqual(ClubType.driver.id, "Driver")
        XCTAssertEqual(ClubType.iron7.id, "7 Iron")
    }

    // MARK: - ClubCategory Tests

    func testClubCategoryAllCases() {
        XCTAssertEqual(ClubCategory.allCases.count, 6)
    }

    func testClubCategoryRawValues() {
        XCTAssertEqual(ClubCategory.driver.rawValue, "Driver")
        XCTAssertEqual(ClubCategory.fairwayWood.rawValue, "Fairway Wood")
        XCTAssertEqual(ClubCategory.hybrid.rawValue, "Hybrid")
        XCTAssertEqual(ClubCategory.iron.rawValue, "Iron")
        XCTAssertEqual(ClubCategory.wedge.rawValue, "Wedge")
        XCTAssertEqual(ClubCategory.putter.rawValue, "Putter")
    }

    func testClubCategoryClubs() {
        // Driver category should have 1 club
        XCTAssertEqual(ClubCategory.driver.clubs.count, 1)
        XCTAssertTrue(ClubCategory.driver.clubs.contains(.driver))

        // Fairway wood category should have 2 clubs
        XCTAssertEqual(ClubCategory.fairwayWood.clubs.count, 2)
        XCTAssertTrue(ClubCategory.fairwayWood.clubs.contains(.wood3))
        XCTAssertTrue(ClubCategory.fairwayWood.clubs.contains(.wood5))

        // Iron category should have 7 clubs (3-9)
        XCTAssertEqual(ClubCategory.iron.clubs.count, 7)

        // Wedge category should have 4 clubs
        XCTAssertEqual(ClubCategory.wedge.clubs.count, 4)
    }

    // MARK: - SwingData with ClubType Tests

    func testSwingDataDefaultClubType() {
        let swing = SwingData()
        XCTAssertEqual(swing.clubType, .iron7)
    }

    func testSwingDataWithClubType() {
        let swing = SwingData(clubType: .driver)
        XCTAssertEqual(swing.clubType, .driver)
    }

    func testSwingDataClubTypeCodable() throws {
        let originalSwing = SwingData(
            videoURL: URL(fileURLWithPath: "/tmp/test.mov"),
            duration: 3.5,
            clubType: .sandWedge
        )

        let encoder = JSONEncoder()
        let data = try encoder.encode(originalSwing)

        let decoder = JSONDecoder()
        let decodedSwing = try decoder.decode(SwingData.self, from: data)

        XCTAssertEqual(decodedSwing.clubType, .sandWedge)
    }

    func testSwingDataCloudSyncProperties() {
        let swing = SwingData(cloudSynced: true, userId: "user123")

        XCTAssertTrue(swing.cloudSynced)
        XCTAssertEqual(swing.userId, "user123")
    }

    // MARK: - Helper Methods

    private func createDefaultPhases() -> SwingPhases {
        SwingPhases(
            addressScore: 80,
            backswingScore: 80,
            topScore: 80,
            downswingScore: 80,
            impactScore: 80,
            followThroughScore: 80
        )
    }

    private func createDefaultMetrics() -> SwingMetrics {
        SwingMetrics(
            hipRotation: 45.0,
            shoulderRotation: 90.0,
            spineAngle: 30.0,
            tempo: 3.0,
            swingPlane: .onPlane,
            balance: .good
        )
    }
}
