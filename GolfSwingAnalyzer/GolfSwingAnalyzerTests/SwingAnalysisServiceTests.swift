import XCTest
@testable import GolfSwingAnalyzer

final class SwingAnalysisServiceTests: XCTestCase {

    // MARK: - AnalysisConstants Tests

    func testAnalysisConstantsValues() {
        XCTAssertEqual(AnalysisConstants.minPoseConfidence, 0.3)
        XCTAssertEqual(AnalysisConstants.analysisFrameRate, 15)
        XCTAssertEqual(AnalysisConstants.shoulderLevelTolerance, 0.05)
        XCTAssertEqual(AnalysisConstants.hipLevelTolerance, 0.05)
        XCTAssertEqual(AnalysisConstants.hipOverAnkleTolerance, 0.1)
        XCTAssertEqual(AnalysisConstants.shoulderOverHipTolerance, 0.15)
        XCTAssertEqual(AnalysisConstants.minShoulderRotationGood, 20)
        XCTAssertEqual(AnalysisConstants.minShoulderRotationExcellent, 30)
        XCTAssertEqual(AnalysisConstants.hipRotationFollow, 0.05)
        XCTAssertEqual(AnalysisConstants.minFramesRequired, 10)
        XCTAssertEqual(AnalysisConstants.defaultPhaseScore, 70)
        XCTAssertEqual(AnalysisConstants.basePhaseScore, 75)
    }

    // MARK: - SwingAnalysisError Tests

    func testSwingAnalysisErrorDescriptions() {
        XCTAssertEqual(
            SwingAnalysisError.videoFileNotFound.errorDescription,
            "Video file not found"
        )
        XCTAssertEqual(
            SwingAnalysisError.invalidVideoDuration.errorDescription,
            "Invalid video duration"
        )
        XCTAssertEqual(
            SwingAnalysisError.insufficientPoseData.errorDescription,
            "Could not detect enough pose data"
        )
        XCTAssertEqual(
            SwingAnalysisError.analysisTimeout.errorDescription,
            "Analysis took too long"
        )
    }

    func testSwingAnalysisErrorConformsToLocalizedError() {
        let error: LocalizedError = SwingAnalysisError.videoFileNotFound
        XCTAssertNotNil(error.errorDescription)
    }

    // MARK: - Service Initialization Tests

    func testServiceInitialization() async {
        let service = SwingAnalysisService()
        XCTAssertNotNil(service)
    }

    // MARK: - Video Validation Tests

    func testAnalyzeSwingWithNonExistentFile() async {
        let service = SwingAnalysisService()
        let fakeURL = URL(fileURLWithPath: "/nonexistent/path/video.mov")

        do {
            _ = try await service.analyzeSwing(videoURL: fakeURL) { _ in }
            XCTFail("Should have thrown videoFileNotFound error")
        } catch let error as SwingAnalysisError {
            XCTAssertEqual(error, .videoFileNotFound)
        } catch {
            XCTFail("Unexpected error type: \(error)")
        }
    }

    // MARK: - ScoreColorHelper Tests

    func testScoreColorHelperOverallScores() {
        // Test excellent (90-100)
        XCTAssertEqual(ScoreColorHelper.color(for: 100), .green)
        XCTAssertEqual(ScoreColorHelper.color(for: 95), .green)
        XCTAssertEqual(ScoreColorHelper.color(for: 90), .green)

        // Test great (80-89)
        XCTAssertEqual(ScoreColorHelper.color(for: 89), .blue)
        XCTAssertEqual(ScoreColorHelper.color(for: 85), .blue)
        XCTAssertEqual(ScoreColorHelper.color(for: 80), .blue)

        // Test good (70-79)
        XCTAssertEqual(ScoreColorHelper.color(for: 79), .yellow)
        XCTAssertEqual(ScoreColorHelper.color(for: 75), .yellow)
        XCTAssertEqual(ScoreColorHelper.color(for: 70), .yellow)

        // Test fair (60-69)
        XCTAssertEqual(ScoreColorHelper.color(for: 69), .orange)
        XCTAssertEqual(ScoreColorHelper.color(for: 65), .orange)
        XCTAssertEqual(ScoreColorHelper.color(for: 60), .orange)

        // Test needs work (<60)
        XCTAssertEqual(ScoreColorHelper.color(for: 59), .red)
        XCTAssertEqual(ScoreColorHelper.color(for: 50), .red)
        XCTAssertEqual(ScoreColorHelper.color(for: 0), .red)
    }

    func testScoreColorHelperPhaseScores() {
        // Test excellent phase (85-100)
        XCTAssertEqual(ScoreColorHelper.phaseColor(for: 100), .green)
        XCTAssertEqual(ScoreColorHelper.phaseColor(for: 90), .green)
        XCTAssertEqual(ScoreColorHelper.phaseColor(for: 85), .green)

        // Test good phase (70-84)
        XCTAssertEqual(ScoreColorHelper.phaseColor(for: 84), .yellow)
        XCTAssertEqual(ScoreColorHelper.phaseColor(for: 75), .yellow)
        XCTAssertEqual(ScoreColorHelper.phaseColor(for: 70), .yellow)

        // Test needs work phase (<70)
        XCTAssertEqual(ScoreColorHelper.phaseColor(for: 69), .orange)
        XCTAssertEqual(ScoreColorHelper.phaseColor(for: 50), .orange)
        XCTAssertEqual(ScoreColorHelper.phaseColor(for: 0), .orange)
    }

    // MARK: - Edge Cases

    func testScoreColorHelperBoundaryValues() {
        // Test exact boundaries
        XCTAssertEqual(ScoreColorHelper.color(for: 90), .green)
        XCTAssertEqual(ScoreColorHelper.color(for: 80), .blue)
        XCTAssertEqual(ScoreColorHelper.color(for: 70), .yellow)
        XCTAssertEqual(ScoreColorHelper.color(for: 60), .orange)

        // Test one below boundaries
        XCTAssertEqual(ScoreColorHelper.color(for: 89), .blue)
        XCTAssertEqual(ScoreColorHelper.color(for: 79), .yellow)
        XCTAssertEqual(ScoreColorHelper.color(for: 69), .orange)
        XCTAssertEqual(ScoreColorHelper.color(for: 59), .red)
    }

    func testScoreColorHelperNegativeScore() {
        // Negative scores should still return red
        XCTAssertEqual(ScoreColorHelper.color(for: -1), .red)
        XCTAssertEqual(ScoreColorHelper.color(for: -100), .red)
    }

    func testScoreColorHelperAbove100() {
        // Scores above 100 should still return green
        XCTAssertEqual(ScoreColorHelper.color(for: 101), .green)
        XCTAssertEqual(ScoreColorHelper.color(for: 150), .green)
    }
}

// MARK: - Mock Service for Integration Tests

/// A mock version of SwingAnalysisService for testing without actual video files
actor MockSwingAnalysisService {
    var shouldFail = false
    var mockAnalysis: SwingAnalysis?

    func analyzeSwing(
        videoURL: URL,
        progressHandler: @escaping @MainActor @Sendable (Double) -> Void
    ) async throws -> SwingAnalysis {
        if shouldFail {
            throw SwingAnalysisError.insufficientPoseData
        }

        // Simulate progress
        for i in 1...10 {
            await progressHandler(Double(i) / 10.0)
            try await Task.sleep(nanoseconds: 10_000_000) // 10ms
        }

        if let analysis = mockAnalysis {
            return analysis
        }

        return createDefaultAnalysis()
    }

    private func createDefaultAnalysis() -> SwingAnalysis {
        let phases = SwingPhases(
            addressScore: 80,
            backswingScore: 75,
            topScore: 70,
            downswingScore: 85,
            impactScore: 80,
            followThroughScore: 75
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
            overallScore: 77,
            phases: phases,
            feedback: [],
            keyMetrics: metrics
        )
    }
}

// MARK: - Mock Service Tests

final class MockSwingAnalysisServiceTests: XCTestCase {

    func testMockServiceReturnsAnalysis() async throws {
        let mockService = MockSwingAnalysisService()
        let fakeURL = URL(fileURLWithPath: "/fake/video.mov")

        var progressValues: [Double] = []
        let analysis = try await mockService.analyzeSwing(videoURL: fakeURL) { progress in
            progressValues.append(progress)
        }

        XCTAssertEqual(analysis.overallScore, 77)
        XCTAssertEqual(progressValues.count, 10)
        XCTAssertEqual(progressValues.last, 1.0)
    }

    func testMockServiceCanFail() async {
        let mockService = MockSwingAnalysisService()
        await mockService.setShouldFail(true)

        let fakeURL = URL(fileURLWithPath: "/fake/video.mov")

        do {
            _ = try await mockService.analyzeSwing(videoURL: fakeURL) { _ in }
            XCTFail("Should have thrown error")
        } catch let error as SwingAnalysisError {
            XCTAssertEqual(error, .insufficientPoseData)
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }

    func testMockServiceCustomAnalysis() async throws {
        let mockService = MockSwingAnalysisService()

        let customPhases = SwingPhases(
            addressScore: 95,
            backswingScore: 90,
            topScore: 88,
            downswingScore: 92,
            impactScore: 94,
            followThroughScore: 91
        )

        let customMetrics = SwingMetrics(
            hipRotation: 50.0,
            shoulderRotation: 95.0,
            spineAngle: 28.0,
            tempo: 3.2,
            swingPlane: .onPlane,
            balance: .excellent
        )

        let customAnalysis = SwingAnalysis(
            overallScore: 92,
            phases: customPhases,
            feedback: [],
            keyMetrics: customMetrics
        )

        await mockService.setMockAnalysis(customAnalysis)

        let fakeURL = URL(fileURLWithPath: "/fake/video.mov")
        let result = try await mockService.analyzeSwing(videoURL: fakeURL) { _ in }

        XCTAssertEqual(result.overallScore, 92)
        XCTAssertEqual(result.phases.addressScore, 95)
    }
}

// Extension to set mock service properties
extension MockSwingAnalysisService {
    func setShouldFail(_ value: Bool) {
        shouldFail = value
    }

    func setMockAnalysis(_ analysis: SwingAnalysis?) {
        mockAnalysis = analysis
    }
}
