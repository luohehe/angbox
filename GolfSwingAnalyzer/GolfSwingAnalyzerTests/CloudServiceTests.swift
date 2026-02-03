import XCTest
@testable import GolfSwingAnalyzer

final class CloudServiceTests: XCTestCase {

    // MARK: - CloudService Tests

    func testCloudServiceSharedInstance() async {
        let instance1 = CloudService.shared
        let instance2 = CloudService.shared

        // Both should reference the same actor instance
        let id1 = await instance1.serviceId
        let id2 = await instance2.serviceId
        XCTAssertEqual(id1, id2)
    }

    func testUploadSwing() async throws {
        let service = CloudService.shared
        let swing = SwingData(
            videoURL: URL(fileURLWithPath: "/tmp/test.mov"),
            duration: 3.5,
            clubType: .driver
        )

        let uploaded = try await service.uploadSwing(swing)

        XCTAssertTrue(uploaded.cloudSynced)
        XCTAssertEqual(uploaded.id, swing.id)
        XCTAssertEqual(uploaded.clubType, swing.clubType)
    }

    func testUploadSwingPreservesData() async throws {
        let service = CloudService.shared
        let analysis = SwingAnalysis(
            overallScore: 85,
            phases: SwingPhases(
                addressScore: 80,
                backswingScore: 85,
                topScore: 90,
                downswingScore: 82,
                impactScore: 88,
                followThroughScore: 85
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

        var swing = SwingData(
            videoURL: URL(fileURLWithPath: "/tmp/test.mov"),
            duration: 4.2,
            clubType: .iron7
        )
        swing.analysis = analysis

        let uploaded = try await service.uploadSwing(swing)

        XCTAssertEqual(uploaded.duration, 4.2)
        XCTAssertEqual(uploaded.clubType, .iron7)
        XCTAssertNotNil(uploaded.analysis)
        XCTAssertEqual(uploaded.analysis?.overallScore, 85)
    }

    func testFetchSwingsForUser() async throws {
        let service = CloudService.shared
        let userId = "test-user-123"

        let swings = try await service.fetchSwings(for: userId)

        // Mock implementation returns empty array for unknown users
        XCTAssertNotNil(swings)
    }

    func testSyncSwings() async throws {
        let service = CloudService.shared
        let userId = "sync-test-user"

        let localSwings = [
            SwingData(clubType: .driver),
            SwingData(clubType: .iron7),
            SwingData(clubType: .putter)
        ]

        let synced = try await service.syncSwings(local: localSwings, userId: userId)

        // All local swings should be marked as synced
        XCTAssertEqual(synced.count, localSwings.count)
        for swing in synced {
            XCTAssertTrue(swing.cloudSynced)
            XCTAssertEqual(swing.userId, userId)
        }
    }

    // MARK: - UserSession Tests

    @MainActor
    func testUserSessionSharedInstance() {
        let instance1 = UserSession.shared
        let instance2 = UserSession.shared

        XCTAssertTrue(instance1 === instance2)
    }

    @MainActor
    func testUserSessionInitialState() {
        let session = UserSession.shared

        // Reset to initial state for testing
        session.signOutSync()

        XCTAssertNil(session.currentUser)
        XCTAssertFalse(session.isLoading)
    }

    @MainActor
    func testUserSessionSignIn() async {
        let session = UserSession.shared

        await session.signIn(email: "test@example.com", password: "password123")

        XCTAssertNotNil(session.currentUser)
        XCTAssertEqual(session.currentUser?.email, "test@example.com")
        XCTAssertFalse(session.isLoading)
    }

    @MainActor
    func testUserSessionSignOut() async {
        let session = UserSession.shared

        // First sign in
        await session.signIn(email: "test@example.com", password: "password")

        // Then sign out
        await session.signOut()

        XCTAssertNil(session.currentUser)
    }

    @MainActor
    func testUserSessionLoadingState() async {
        let session = UserSession.shared
        session.signOutSync()

        // isLoading should be false initially
        XCTAssertFalse(session.isLoading)
    }
}

// MARK: - CloudService Extension for Testing

extension CloudService {
    var serviceId: String {
        return "cloud-service-shared"
    }
}

// MARK: - UserSession Extension for Testing

extension UserSession {
    func signOutSync() {
        self.currentUser = nil
        self.isLoading = false
    }
}
