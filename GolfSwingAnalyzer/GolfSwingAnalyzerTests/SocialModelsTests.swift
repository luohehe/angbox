import XCTest
@testable import GolfSwingAnalyzer

final class SocialModelsTests: XCTestCase {

    // MARK: - User Tests

    func testUserInitialization() {
        let user = User(username: "testuser", displayName: "Test User")

        XCTAssertFalse(user.id.isEmpty)
        XCTAssertEqual(user.username, "testuser")
        XCTAssertEqual(user.displayName, "Test User")
        XCTAssertNil(user.email)
        XCTAssertNil(user.avatarURL)
        XCTAssertNotNil(user.createdAt)
    }

    func testUserWithAllProperties() {
        let avatarURL = URL(string: "https://example.com/avatar.png")
        let user = User(
            id: "custom-id",
            username: "golfer123",
            displayName: "Pro Golfer",
            email: "golfer@example.com",
            avatarURL: avatarURL,
            createdAt: Date(),
            stats: UserStats(totalSwings: 100, averageScore: 85.5, bestScore: 95)
        )

        XCTAssertEqual(user.id, "custom-id")
        XCTAssertEqual(user.username, "golfer123")
        XCTAssertEqual(user.displayName, "Pro Golfer")
        XCTAssertEqual(user.email, "golfer@example.com")
        XCTAssertEqual(user.avatarURL, avatarURL)
        XCTAssertEqual(user.stats.totalSwings, 100)
        XCTAssertEqual(user.stats.averageScore, 85.5)
        XCTAssertEqual(user.stats.bestScore, 95)
    }

    func testUserEquality() {
        let user1 = User(id: "same-id", username: "user1", displayName: "User 1")
        let user2 = User(id: "same-id", username: "user2", displayName: "User 2")
        let user3 = User(id: "different-id", username: "user1", displayName: "User 1")

        XCTAssertEqual(user1, user2) // Same ID means equal
        XCTAssertNotEqual(user1, user3) // Different ID means not equal
    }

    func testUserCodable() throws {
        let original = User(
            username: "testuser",
            displayName: "Test User",
            email: "test@example.com"
        )

        let encoder = JSONEncoder()
        let data = try encoder.encode(original)

        let decoder = JSONDecoder()
        let decoded = try decoder.decode(User.self, from: data)

        XCTAssertEqual(decoded.id, original.id)
        XCTAssertEqual(decoded.username, original.username)
        XCTAssertEqual(decoded.displayName, original.displayName)
        XCTAssertEqual(decoded.email, original.email)
    }

    // MARK: - UserStats Tests

    func testUserStatsDefaultValues() {
        let stats = UserStats()

        XCTAssertEqual(stats.totalSwings, 0)
        XCTAssertEqual(stats.averageScore, 0)
        XCTAssertEqual(stats.bestScore, 0)
        XCTAssertEqual(stats.totalPracticeTime, 0)
        XCTAssertEqual(stats.currentStreak, 0)
        XCTAssertEqual(stats.longestStreak, 0)
        XCTAssertTrue(stats.clubStats.isEmpty)
    }

    func testUserStatsRankingScoreWithNoSwings() {
        let stats = UserStats()
        XCTAssertEqual(stats.rankingScore, 0)
    }

    func testUserStatsRankingScoreCalculation() {
        // Ranking score = averageScore + min(totalSwings/100, 1.0) * 10
        let stats = UserStats(totalSwings: 50, averageScore: 80.0)
        // 80 + (50/100) * 10 = 80 + 5 = 85
        XCTAssertEqual(stats.rankingScore, 85.0)
    }

    func testUserStatsRankingScoreMaxBonus() {
        // Max bonus is 10 points for 100+ swings
        let stats = UserStats(totalSwings: 200, averageScore: 80.0)
        // 80 + 1.0 * 10 = 90 (capped at 10 bonus)
        XCTAssertEqual(stats.rankingScore, 90.0)
    }

    func testUserStatsCodable() throws {
        let original = UserStats(
            totalSwings: 50,
            averageScore: 75.5,
            bestScore: 92,
            currentStreak: 5
        )

        let encoder = JSONEncoder()
        let data = try encoder.encode(original)

        let decoder = JSONDecoder()
        let decoded = try decoder.decode(UserStats.self, from: data)

        XCTAssertEqual(decoded.totalSwings, original.totalSwings)
        XCTAssertEqual(decoded.averageScore, original.averageScore)
        XCTAssertEqual(decoded.bestScore, original.bestScore)
        XCTAssertEqual(decoded.currentStreak, original.currentStreak)
    }

    // MARK: - ClubStats Tests

    func testClubStatsDefaultValues() {
        let stats = ClubStats()

        XCTAssertEqual(stats.swingCount, 0)
        XCTAssertEqual(stats.averageScore, 0)
        XCTAssertEqual(stats.bestScore, 0)
    }

    func testClubStatsWithValues() {
        let stats = ClubStats(
            swingCount: 25,
            averageScore: 82.5,
            bestScore: 95,
            lastUsed: Date()
        )

        XCTAssertEqual(stats.swingCount, 25)
        XCTAssertEqual(stats.averageScore, 82.5)
        XCTAssertEqual(stats.bestScore, 95)
    }

    // MARK: - Friendship Tests

    func testFriendshipInitialization() {
        let friendship = Friendship(userId: "user1", friendId: "user2")

        XCTAssertFalse(friendship.id.isEmpty)
        XCTAssertEqual(friendship.userId, "user1")
        XCTAssertEqual(friendship.friendId, "user2")
        XCTAssertEqual(friendship.status, .pending)
        XCTAssertNil(friendship.friend)
    }

    func testFriendshipWithStatus() {
        let friendship = Friendship(
            userId: "user1",
            friendId: "user2",
            status: .accepted
        )

        XCTAssertEqual(friendship.status, .accepted)
    }

    func testFriendshipCodable() throws {
        let original = Friendship(
            userId: "user1",
            friendId: "user2",
            status: .accepted
        )

        let encoder = JSONEncoder()
        let data = try encoder.encode(original)

        let decoder = JSONDecoder()
        let decoded = try decoder.decode(Friendship.self, from: data)

        XCTAssertEqual(decoded.id, original.id)
        XCTAssertEqual(decoded.userId, original.userId)
        XCTAssertEqual(decoded.friendId, original.friendId)
        XCTAssertEqual(decoded.status, original.status)
    }

    // MARK: - FriendshipStatus Tests

    func testFriendshipStatusRawValues() {
        XCTAssertEqual(FriendshipStatus.pending.rawValue, "pending")
        XCTAssertEqual(FriendshipStatus.accepted.rawValue, "accepted")
        XCTAssertEqual(FriendshipStatus.blocked.rawValue, "blocked")
    }

    // MARK: - FriendRequest Tests

    func testFriendRequestInitialization() {
        let fromUser = User(username: "sender", displayName: "Sender")
        let request = FriendRequest(fromUser: fromUser, toUserId: "receiver-id")

        XCTAssertFalse(request.id.isEmpty)
        XCTAssertEqual(request.fromUser.username, "sender")
        XCTAssertEqual(request.toUserId, "receiver-id")
        XCTAssertEqual(request.status, .pending)
    }

    // MARK: - LeaderboardEntry Tests

    func testLeaderboardEntryInitialization() {
        let user = User(username: "leader", displayName: "Top Player")
        let entry = LeaderboardEntry(
            id: "entry-1",
            user: user,
            rank: 1,
            score: 95.5,
            swingCount: 150,
            updatedAt: Date()
        )

        XCTAssertEqual(entry.id, "entry-1")
        XCTAssertEqual(entry.user.username, "leader")
        XCTAssertEqual(entry.rank, 1)
        XCTAssertEqual(entry.score, 95.5)
        XCTAssertEqual(entry.swingCount, 150)
    }

    func testLeaderboardEntryFormattedScore() {
        let user = User(username: "test", displayName: "Test")
        let entry = LeaderboardEntry(
            id: "entry-1",
            user: user,
            rank: 1,
            score: 87.567,
            swingCount: 100,
            updatedAt: Date()
        )

        XCTAssertEqual(entry.formattedScore, "87.6")
    }

    func testLeaderboardEntryRankBadges() {
        let user = User(username: "test", displayName: "Test")

        let first = LeaderboardEntry(id: "1", user: user, rank: 1, score: 95, swingCount: 100, updatedAt: Date())
        let second = LeaderboardEntry(id: "2", user: user, rank: 2, score: 90, swingCount: 100, updatedAt: Date())
        let third = LeaderboardEntry(id: "3", user: user, rank: 3, score: 85, swingCount: 100, updatedAt: Date())
        let fourth = LeaderboardEntry(id: "4", user: user, rank: 4, score: 80, swingCount: 100, updatedAt: Date())

        XCTAssertEqual(first.rankBadge, "🥇")
        XCTAssertEqual(second.rankBadge, "🥈")
        XCTAssertEqual(third.rankBadge, "🥉")
        XCTAssertEqual(fourth.rankBadge, "#4")
    }

    func testLeaderboardEntryCodable() throws {
        let user = User(username: "test", displayName: "Test")
        let original = LeaderboardEntry(
            id: "entry-1",
            user: user,
            rank: 5,
            score: 82.5,
            swingCount: 75,
            updatedAt: Date()
        )

        let encoder = JSONEncoder()
        let data = try encoder.encode(original)

        let decoder = JSONDecoder()
        let decoded = try decoder.decode(LeaderboardEntry.self, from: data)

        XCTAssertEqual(decoded.id, original.id)
        XCTAssertEqual(decoded.rank, original.rank)
        XCTAssertEqual(decoded.score, original.score)
        XCTAssertEqual(decoded.swingCount, original.swingCount)
    }

    // MARK: - LeaderboardType Tests

    func testLeaderboardTypeAllCases() {
        XCTAssertEqual(LeaderboardType.allCases.count, 4)
    }

    func testLeaderboardTypeRawValues() {
        XCTAssertEqual(LeaderboardType.global.rawValue, "Global")
        XCTAssertEqual(LeaderboardType.friends.rawValue, "Friends")
        XCTAssertEqual(LeaderboardType.weekly.rawValue, "Weekly")
        XCTAssertEqual(LeaderboardType.monthly.rawValue, "Monthly")
    }

    func testLeaderboardTypeIcons() {
        XCTAssertEqual(LeaderboardType.global.icon, "globe")
        XCTAssertEqual(LeaderboardType.friends.icon, "person.2.fill")
        XCTAssertEqual(LeaderboardType.weekly.icon, "calendar")
        XCTAssertEqual(LeaderboardType.monthly.icon, "calendar.badge.clock")
    }

    // MARK: - LeaderboardFilter Tests

    func testLeaderboardFilterAllCases() {
        XCTAssertEqual(LeaderboardFilter.allCases.count, 4)
    }

    func testLeaderboardFilterRawValues() {
        XCTAssertEqual(LeaderboardFilter.overall.rawValue, "Overall")
        XCTAssertEqual(LeaderboardFilter.driver.rawValue, "Driver")
        XCTAssertEqual(LeaderboardFilter.irons.rawValue, "Irons")
        XCTAssertEqual(LeaderboardFilter.wedges.rawValue, "Wedges")
    }

    func testLeaderboardFilterClubTypes() {
        // Overall returns nil (no filter)
        XCTAssertNil(LeaderboardFilter.overall.clubTypes)

        // Driver returns only driver
        XCTAssertEqual(LeaderboardFilter.driver.clubTypes, [.driver])

        // Irons returns all iron clubs
        let irons = LeaderboardFilter.irons.clubTypes
        XCTAssertNotNil(irons)
        XCTAssertEqual(irons?.count, 7)

        // Wedges returns all wedge clubs
        let wedges = LeaderboardFilter.wedges.clubTypes
        XCTAssertNotNil(wedges)
        XCTAssertEqual(wedges?.count, 4)
    }

    // MARK: - SyncStatus Tests

    func testSyncStatusDefaultValues() {
        let status = SyncStatus()

        XCTAssertNil(status.lastSyncDate)
        XCTAssertEqual(status.pendingUploads, 0)
        XCTAssertEqual(status.pendingDownloads, 0)
        XCTAssertFalse(status.isSyncing)
    }

    func testSyncStatusNeedsSync() {
        let noSyncNeeded = SyncStatus()
        XCTAssertFalse(noSyncNeeded.needsSync)

        let needsUpload = SyncStatus(pendingUploads: 5)
        XCTAssertTrue(needsUpload.needsSync)

        let needsDownload = SyncStatus(pendingDownloads: 3)
        XCTAssertTrue(needsDownload.needsSync)

        let needsBoth = SyncStatus(pendingUploads: 2, pendingDownloads: 1)
        XCTAssertTrue(needsBoth.needsSync)
    }

    func testSyncStatusCodable() throws {
        let original = SyncStatus(
            lastSyncDate: Date(),
            pendingUploads: 3,
            pendingDownloads: 1,
            isSyncing: true
        )

        let encoder = JSONEncoder()
        let data = try encoder.encode(original)

        let decoder = JSONDecoder()
        let decoded = try decoder.decode(SyncStatus.self, from: data)

        XCTAssertEqual(decoded.pendingUploads, original.pendingUploads)
        XCTAssertEqual(decoded.pendingDownloads, original.pendingDownloads)
        XCTAssertEqual(decoded.isSyncing, original.isSyncing)
    }
}
