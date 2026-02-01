import Foundation
import SwiftUI

// MARK: - Social Service
/// Handles friend management and leaderboards
actor SocialService {
    static let shared = SocialService()

    // MARK: - Friend Management

    func searchUsers(query: String) async throws -> [User] {
        try await Task.sleep(nanoseconds: 300_000_000)

        // Mock search results
        guard !query.isEmpty else { return [] }

        return [
            User(id: "user1", username: "golfpro\(query)", displayName: "Golf Pro"),
            User(id: "user2", username: "swingmaster\(query)", displayName: "Swing Master"),
            User(id: "user3", username: "birdiehunter\(query)", displayName: "Birdie Hunter")
        ]
    }

    func sendFriendRequest(to userId: String, from currentUser: User) async throws -> FriendRequest {
        try await Task.sleep(nanoseconds: 200_000_000)

        return FriendRequest(
            fromUser: currentUser,
            toUserId: userId,
            status: .pending
        )
    }

    func acceptFriendRequest(_ request: FriendRequest) async throws -> Friendship {
        try await Task.sleep(nanoseconds: 200_000_000)

        return Friendship(
            userId: request.toUserId,
            friendId: request.fromUser.id,
            status: .accepted,
            friend: request.fromUser
        )
    }

    func declineFriendRequest(_ request: FriendRequest) async throws {
        try await Task.sleep(nanoseconds: 100_000_000)
    }

    func removeFriend(_ friendship: Friendship) async throws {
        try await Task.sleep(nanoseconds: 200_000_000)
    }

    func getFriends(for userId: String) async throws -> [Friendship] {
        try await Task.sleep(nanoseconds: 300_000_000)

        // Mock friends list
        return [
            Friendship(
                userId: userId,
                friendId: "friend1",
                status: .accepted,
                friend: User(
                    id: "friend1",
                    username: "tiger_fan",
                    displayName: "Tiger Fan",
                    stats: UserStats(totalSwings: 150, averageScore: 82, bestScore: 95)
                )
            ),
            Friendship(
                userId: userId,
                friendId: "friend2",
                status: .accepted,
                friend: User(
                    id: "friend2",
                    username: "weekend_golfer",
                    displayName: "Weekend Golfer",
                    stats: UserStats(totalSwings: 45, averageScore: 68, bestScore: 78)
                )
            ),
            Friendship(
                userId: userId,
                friendId: "friend3",
                status: .accepted,
                friend: User(
                    id: "friend3",
                    username: "scratch_player",
                    displayName: "Scratch Player",
                    stats: UserStats(totalSwings: 320, averageScore: 91, bestScore: 98)
                )
            )
        ]
    }

    func getPendingRequests(for userId: String) async throws -> [FriendRequest] {
        try await Task.sleep(nanoseconds: 200_000_000)
        return []
    }

    // MARK: - Leaderboards

    func getGlobalLeaderboard(filter: LeaderboardFilter = .overall, limit: Int = 100) async throws -> [LeaderboardEntry] {
        try await Task.sleep(nanoseconds: 400_000_000)

        // Mock global leaderboard
        let mockUsers: [(String, String, Double, Int)] = [
            ("champion_golfer", "Champion Golfer", 96.5, 450),
            ("swing_king", "Swing King", 94.2, 380),
            ("fairway_master", "Fairway Master", 92.8, 290),
            ("iron_man_golf", "Iron Man Golf", 91.5, 520),
            ("birdie_queen", "Birdie Queen", 90.3, 185),
            ("eagle_eye", "Eagle Eye", 89.7, 420),
            ("par_perfect", "Par Perfect", 88.9, 310),
            ("green_machine", "Green Machine", 87.5, 275),
            ("tee_time_pro", "Tee Time Pro", 86.2, 195),
            ("bogey_buster", "Bogey Buster", 85.0, 240)
        ]

        return mockUsers.enumerated().map { index, data in
            LeaderboardEntry(
                id: "global_\(index)",
                user: User(
                    id: "user_\(index)",
                    username: data.0,
                    displayName: data.1,
                    stats: UserStats(totalSwings: data.3, averageScore: data.2, bestScore: Int(data.2) + 3)
                ),
                rank: index + 1,
                score: data.2,
                swingCount: data.3,
                updatedAt: Date()
            )
        }
    }

    func getFriendsLeaderboard(for userId: String, friends: [Friendship]) async throws -> [LeaderboardEntry] {
        try await Task.sleep(nanoseconds: 200_000_000)

        // Sort friends by score and create leaderboard
        let sortedFriends = friends
            .compactMap { $0.friend }
            .sorted { $0.stats.rankingScore > $1.stats.rankingScore }

        return sortedFriends.enumerated().map { index, friend in
            LeaderboardEntry(
                id: "friend_\(friend.id)",
                user: friend,
                rank: index + 1,
                score: friend.stats.averageScore,
                swingCount: friend.stats.totalSwings,
                updatedAt: Date()
            )
        }
    }

    func getWeeklyLeaderboard(limit: Int = 50) async throws -> [LeaderboardEntry] {
        // Similar to global but filtered by this week's activity
        try await getGlobalLeaderboard(limit: limit)
    }

    func getMonthlyLeaderboard(limit: Int = 50) async throws -> [LeaderboardEntry] {
        // Similar to global but filtered by this month's activity
        try await getGlobalLeaderboard(limit: limit)
    }

    func getUserRank(userId: String, type: LeaderboardType) async throws -> Int? {
        try await Task.sleep(nanoseconds: 150_000_000)
        // Mock user rank
        return Int.random(in: 50...500)
    }
}

// MARK: - Social Manager (Observable)
@MainActor
class SocialManager: ObservableObject {
    static let shared = SocialManager()

    @Published var friends: [Friendship] = []
    @Published var pendingRequests: [FriendRequest] = []
    @Published var globalLeaderboard: [LeaderboardEntry] = []
    @Published var friendsLeaderboard: [LeaderboardEntry] = []
    @Published var userGlobalRank: Int?
    @Published var isLoading = false
    @Published var error: Error?

    private let socialService = SocialService.shared

    func loadFriends(for userId: String) async {
        isLoading = true
        do {
            friends = try await socialService.getFriends(for: userId)
            pendingRequests = try await socialService.getPendingRequests(for: userId)
        } catch {
            self.error = error
        }
        isLoading = false
    }

    func searchUsers(query: String) async -> [User] {
        do {
            return try await socialService.searchUsers(query: query)
        } catch {
            self.error = error
            return []
        }
    }

    func sendFriendRequest(to userId: String, from user: User) async {
        do {
            let request = try await socialService.sendFriendRequest(to: userId, from: user)
            // Handle UI update
        } catch {
            self.error = error
        }
    }

    func acceptRequest(_ request: FriendRequest) async {
        do {
            let friendship = try await socialService.acceptFriendRequest(request)
            friends.append(friendship)
            pendingRequests.removeAll { $0.id == request.id }
        } catch {
            self.error = error
        }
    }

    func declineRequest(_ request: FriendRequest) async {
        do {
            try await socialService.declineFriendRequest(request)
            pendingRequests.removeAll { $0.id == request.id }
        } catch {
            self.error = error
        }
    }

    func removeFriend(_ friendship: Friendship) async {
        do {
            try await socialService.removeFriend(friendship)
            friends.removeAll { $0.id == friendship.id }
        } catch {
            self.error = error
        }
    }

    func loadLeaderboards(for userId: String) async {
        isLoading = true
        do {
            async let global = socialService.getGlobalLeaderboard()
            async let friendsBoard = socialService.getFriendsLeaderboard(for: userId, friends: friends)
            async let rank = socialService.getUserRank(userId: userId, type: .global)

            globalLeaderboard = try await global
            friendsLeaderboard = try await friendsBoard
            userGlobalRank = try await rank
        } catch {
            self.error = error
        }
        isLoading = false
    }
}
