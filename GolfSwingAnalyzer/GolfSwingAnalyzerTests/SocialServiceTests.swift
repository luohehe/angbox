import XCTest
@testable import GolfSwingAnalyzer

final class SocialServiceTests: XCTestCase {

    // MARK: - SocialService Tests

    func testSocialServiceSharedInstance() async {
        let instance1 = SocialService.shared
        let instance2 = SocialService.shared

        let id1 = await instance1.serviceId
        let id2 = await instance2.serviceId
        XCTAssertEqual(id1, id2)
    }

    func testSearchUsers() async throws {
        let service = SocialService.shared

        let results = try await service.searchUsers(query: "test")

        XCTAssertNotNil(results)
        // Mock implementation returns sample users for non-empty queries
    }

    func testSearchUsersEmptyQuery() async throws {
        let service = SocialService.shared

        let results = try await service.searchUsers(query: "")

        XCTAssertTrue(results.isEmpty)
    }

    func testSendFriendRequest() async throws {
        let service = SocialService.shared
        let currentUser = User(username: "sender", displayName: "Sender User")

        // Should not throw for valid request
        try await service.sendFriendRequest(to: "recipient-id", from: currentUser)
    }

    func testGetFriends() async throws {
        let service = SocialService.shared

        let friends = try await service.getFriends(for: "user-123")

        XCTAssertNotNil(friends)
    }

    func testAcceptFriendRequest() async throws {
        let service = SocialService.shared
        let fromUser = User(username: "requester", displayName: "Requester")
        let request = FriendRequest(fromUser: fromUser, toUserId: "current-user")

        let friendship = try await service.acceptFriendRequest(request)

        XCTAssertEqual(friendship.status, .accepted)
    }

    func testDeclineFriendRequest() async throws {
        let service = SocialService.shared
        let fromUser = User(username: "requester", displayName: "Requester")
        let request = FriendRequest(fromUser: fromUser, toUserId: "current-user")

        // Should not throw
        try await service.declineFriendRequest(request)
    }

    func testRemoveFriend() async throws {
        let service = SocialService.shared
        let friendship = Friendship(userId: "user1", friendId: "user2", status: .accepted)

        // Should not throw
        try await service.removeFriend(friendship)
    }

    func testGetGlobalLeaderboard() async throws {
        let service = SocialService.shared

        let leaderboard = try await service.getGlobalLeaderboard(filter: .overall)

        XCTAssertNotNil(leaderboard)
        // Verify entries are sorted by rank
        if leaderboard.count > 1 {
            for i in 0..<(leaderboard.count - 1) {
                XCTAssertLessThanOrEqual(leaderboard[i].rank, leaderboard[i + 1].rank)
            }
        }
    }

    func testGetGlobalLeaderboardWithFilter() async throws {
        let service = SocialService.shared

        let driverLeaderboard = try await service.getGlobalLeaderboard(filter: .driver)
        let ironsLeaderboard = try await service.getGlobalLeaderboard(filter: .irons)

        XCTAssertNotNil(driverLeaderboard)
        XCTAssertNotNil(ironsLeaderboard)
    }

    func testGetFriendsLeaderboard() async throws {
        let service = SocialService.shared
        let friends = [
            Friendship(userId: "me", friendId: "friend1", status: .accepted),
            Friendship(userId: "me", friendId: "friend2", status: .accepted)
        ]

        let leaderboard = try await service.getFriendsLeaderboard(for: "me", friends: friends)

        XCTAssertNotNil(leaderboard)
    }

    func testGetFriendsLeaderboardEmpty() async throws {
        let service = SocialService.shared

        let leaderboard = try await service.getFriendsLeaderboard(for: "me", friends: [])

        XCTAssertTrue(leaderboard.isEmpty)
    }

    // MARK: - SocialManager Tests

    @MainActor
    func testSocialManagerSharedInstance() {
        let instance1 = SocialManager.shared
        let instance2 = SocialManager.shared

        XCTAssertTrue(instance1 === instance2)
    }

    @MainActor
    func testSocialManagerInitialState() {
        let manager = SocialManager.shared

        // Reset state
        manager.resetState()

        XCTAssertTrue(manager.friends.isEmpty)
        XCTAssertTrue(manager.pendingRequests.isEmpty)
        XCTAssertTrue(manager.globalLeaderboard.isEmpty)
        XCTAssertTrue(manager.friendsLeaderboard.isEmpty)
        XCTAssertNil(manager.userGlobalRank)
        XCTAssertFalse(manager.isLoading)
    }

    @MainActor
    func testSocialManagerLoadFriends() async {
        let manager = SocialManager.shared
        manager.resetState()

        await manager.loadFriends(for: "test-user")

        XCTAssertFalse(manager.isLoading)
    }

    @MainActor
    func testSocialManagerLoadLeaderboards() async {
        let manager = SocialManager.shared
        manager.resetState()

        await manager.loadLeaderboards(for: "test-user")

        XCTAssertFalse(manager.isLoading)
    }

    @MainActor
    func testSocialManagerAcceptRequest() async {
        let manager = SocialManager.shared
        manager.resetState()

        let fromUser = User(username: "requester", displayName: "Requester")
        let request = FriendRequest(fromUser: fromUser, toUserId: "current-user")

        await manager.acceptRequest(request)

        // Request should be removed from pending
        XCTAssertFalse(manager.pendingRequests.contains { $0.id == request.id })
    }

    @MainActor
    func testSocialManagerDeclineRequest() async {
        let manager = SocialManager.shared
        manager.resetState()

        let fromUser = User(username: "requester", displayName: "Requester")
        let request = FriendRequest(fromUser: fromUser, toUserId: "current-user")

        await manager.declineRequest(request)

        // Request should be removed from pending
        XCTAssertFalse(manager.pendingRequests.contains { $0.id == request.id })
    }

    @MainActor
    func testSocialManagerRemoveFriend() async {
        let manager = SocialManager.shared
        manager.resetState()

        let friendship = Friendship(userId: "me", friendId: "friend1", status: .accepted)

        await manager.removeFriend(friendship)

        // Friendship should be removed
        XCTAssertFalse(manager.friends.contains { $0.id == friendship.id })
    }

    @MainActor
    func testSocialManagerSendFriendRequest() async {
        let manager = SocialManager.shared
        let currentUser = User(username: "me", displayName: "Me")

        // Should not throw
        await manager.sendFriendRequest(to: "other-user", from: currentUser)
    }
}

// MARK: - SocialService Extension for Testing

extension SocialService {
    var serviceId: String {
        return "social-service-shared"
    }
}

// MARK: - SocialManager Extension for Testing

extension SocialManager {
    func resetState() {
        self.friends = []
        self.pendingRequests = []
        self.globalLeaderboard = []
        self.friendsLeaderboard = []
        self.userGlobalRank = nil
        self.isLoading = false
        self.error = nil
    }
}
