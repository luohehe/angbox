import XCTest
@testable import GolfSwingAnalyzer

@MainActor
final class SwingStoreTests: XCTestCase {

    private var swingStore: SwingStore!
    private let testUserDefaultsKey = "saved_swings"

    override func setUp() {
        super.setUp()
        // Clear any existing data before each test
        UserDefaults.standard.removeObject(forKey: testUserDefaultsKey)
        swingStore = SwingStore()
    }

    override func tearDown() {
        // Clean up after each test
        UserDefaults.standard.removeObject(forKey: testUserDefaultsKey)
        swingStore = nil
        super.tearDown()
    }

    // MARK: - Initialization Tests

    func testInitialStateIsEmpty() {
        XCTAssertTrue(swingStore.swings.isEmpty)
        XCTAssertFalse(swingStore.isAnalyzing)
        XCTAssertEqual(swingStore.analysisProgress, 0)
    }

    // MARK: - Add Swing Tests

    func testAddSwing() {
        let swing = SwingData(duration: 5.0)

        swingStore.addSwing(swing)

        XCTAssertEqual(swingStore.swings.count, 1)
        XCTAssertEqual(swingStore.swings.first?.id, swing.id)
    }

    func testAddSwingInsertsAtBeginning() {
        let swing1 = SwingData(duration: 3.0)
        let swing2 = SwingData(duration: 4.0)
        let swing3 = SwingData(duration: 5.0)

        swingStore.addSwing(swing1)
        swingStore.addSwing(swing2)
        swingStore.addSwing(swing3)

        XCTAssertEqual(swingStore.swings.count, 3)
        XCTAssertEqual(swingStore.swings[0].id, swing3.id)
        XCTAssertEqual(swingStore.swings[1].id, swing2.id)
        XCTAssertEqual(swingStore.swings[2].id, swing1.id)
    }

    // MARK: - Update Swing Tests

    func testUpdateSwing() {
        var swing = SwingData(duration: 5.0)
        swingStore.addSwing(swing)

        // Create analysis to update swing with
        let analysis = createTestAnalysis(score: 85)
        swing.analysis = analysis

        swingStore.updateSwing(swing)

        XCTAssertEqual(swingStore.swings.first?.analysis?.overallScore, 85)
    }

    func testUpdateNonExistentSwingDoesNothing() {
        let swing1 = SwingData(duration: 3.0)
        let swing2 = SwingData(duration: 5.0)

        swingStore.addSwing(swing1)
        swingStore.updateSwing(swing2) // swing2 was never added

        XCTAssertEqual(swingStore.swings.count, 1)
        XCTAssertEqual(swingStore.swings.first?.id, swing1.id)
    }

    // MARK: - Delete Swing Tests

    func testDeleteSwing() {
        let swing1 = SwingData(duration: 3.0)
        let swing2 = SwingData(duration: 5.0)

        swingStore.addSwing(swing1)
        swingStore.addSwing(swing2)

        swingStore.deleteSwing(swing1)

        XCTAssertEqual(swingStore.swings.count, 1)
        XCTAssertEqual(swingStore.swings.first?.id, swing2.id)
    }

    func testDeleteSwingsAtOffsets() {
        let swing1 = SwingData(duration: 3.0)
        let swing2 = SwingData(duration: 4.0)
        let swing3 = SwingData(duration: 5.0)

        swingStore.addSwing(swing1)
        swingStore.addSwing(swing2)
        swingStore.addSwing(swing3)

        // Delete first and last (indices 0 and 2)
        swingStore.deleteSwings(at: IndexSet([0, 2]))

        XCTAssertEqual(swingStore.swings.count, 1)
        XCTAssertEqual(swingStore.swings.first?.id, swing2.id)
    }

    // MARK: - Statistics Tests

    func testTotalSwings() {
        XCTAssertEqual(swingStore.totalSwings, 0)

        swingStore.addSwing(SwingData(duration: 3.0))
        XCTAssertEqual(swingStore.totalSwings, 1)

        swingStore.addSwing(SwingData(duration: 4.0))
        XCTAssertEqual(swingStore.totalSwings, 2)

        swingStore.addSwing(SwingData(duration: 5.0))
        XCTAssertEqual(swingStore.totalSwings, 3)
    }

    func testAverageScoreWithNoSwings() {
        XCTAssertEqual(swingStore.averageScore, 0)
    }

    func testAverageScoreWithUnanalyzedSwings() {
        swingStore.addSwing(SwingData(duration: 3.0))
        swingStore.addSwing(SwingData(duration: 4.0))

        XCTAssertEqual(swingStore.averageScore, 0)
    }

    func testAverageScoreWithAnalyzedSwings() {
        var swing1 = SwingData(duration: 3.0)
        swing1.analysis = createTestAnalysis(score: 80)

        var swing2 = SwingData(duration: 4.0)
        swing2.analysis = createTestAnalysis(score: 90)

        swingStore.addSwing(swing1)
        swingStore.addSwing(swing2)

        XCTAssertEqual(swingStore.averageScore, 85)
    }

    func testAverageScoreWithMixedSwings() {
        var swing1 = SwingData(duration: 3.0)
        swing1.analysis = createTestAnalysis(score: 80)

        let swing2 = SwingData(duration: 4.0) // No analysis

        var swing3 = SwingData(duration: 5.0)
        swing3.analysis = createTestAnalysis(score: 100)

        swingStore.addSwing(swing1)
        swingStore.addSwing(swing2)
        swingStore.addSwing(swing3)

        // Only analyzed swings count: (80 + 100) / 2 = 90
        XCTAssertEqual(swingStore.averageScore, 90)
    }

    func testRecentImprovementWithInsufficientData() {
        // Need at least 3 recent and 3 older swings
        var swing1 = SwingData(duration: 3.0)
        swing1.analysis = createTestAnalysis(score: 80)

        swingStore.addSwing(swing1)

        XCTAssertNil(swingStore.recentImprovement)
    }

    func testRecentImprovementWithSufficientData() {
        // Add 5 older swings with lower scores
        for i in 0..<5 {
            var swing = SwingData(duration: Double(i))
            swing.analysis = createTestAnalysis(score: 70)
            swingStore.addSwing(swing)
        }

        // Add 5 recent swings with higher scores (these will be at the front)
        for i in 0..<5 {
            var swing = SwingData(duration: Double(i + 10))
            swing.analysis = createTestAnalysis(score: 80)
            swingStore.addSwing(swing)
        }

        // Recent avg: 80, Older avg: 70, Improvement: +10
        XCTAssertEqual(swingStore.recentImprovement, 10)
    }

    func testRecentImprovementNegative() {
        // Add 5 older swings with higher scores
        for i in 0..<5 {
            var swing = SwingData(duration: Double(i))
            swing.analysis = createTestAnalysis(score: 90)
            swingStore.addSwing(swing)
        }

        // Add 5 recent swings with lower scores
        for i in 0..<5 {
            var swing = SwingData(duration: Double(i + 10))
            swing.analysis = createTestAnalysis(score: 70)
            swingStore.addSwing(swing)
        }

        // Recent avg: 70, Older avg: 90, Improvement: -20
        XCTAssertEqual(swingStore.recentImprovement, -20)
    }

    // MARK: - Persistence Tests

    func testSwingsArePersisted() {
        let swing = SwingData(duration: 5.0)
        swingStore.addSwing(swing)

        // Create a new store instance (simulates app restart)
        let newStore = SwingStore()

        XCTAssertEqual(newStore.swings.count, 1)
        XCTAssertEqual(newStore.swings.first?.id, swing.id)
    }

    func testDeletedSwingsArePersistedAsDeleted() {
        let swing1 = SwingData(duration: 3.0)
        let swing2 = SwingData(duration: 5.0)

        swingStore.addSwing(swing1)
        swingStore.addSwing(swing2)
        swingStore.deleteSwing(swing1)

        // Create new store
        let newStore = SwingStore()

        XCTAssertEqual(newStore.swings.count, 1)
        XCTAssertEqual(newStore.swings.first?.id, swing2.id)
    }

    // MARK: - Helper Methods

    private func createTestAnalysis(score: Int) -> SwingAnalysis {
        let phases = SwingPhases(
            addressScore: score,
            backswingScore: score,
            topScore: score,
            downswingScore: score,
            impactScore: score,
            followThroughScore: score
        )

        let metrics = SwingMetrics(
            hipRotation: 45.0,
            shoulderRotation: 90.0,
            spineAngle: 30.0,
            tempo: 3.0,
            swingPlane: .onPlane,
            balance: .good
        )

        return SwingAnalysis(
            overallScore: score,
            phases: phases,
            feedback: [],
            keyMetrics: metrics
        )
    }
}
