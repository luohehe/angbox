import Foundation

// MARK: - User Model
struct User: Identifiable, Codable, Equatable {
    let id: String
    var username: String
    var displayName: String
    var email: String?
    var avatarURL: URL?
    var createdAt: Date
    var stats: UserStats

    init(
        id: String = UUID().uuidString,
        username: String,
        displayName: String,
        email: String? = nil,
        avatarURL: URL? = nil,
        createdAt: Date = Date(),
        stats: UserStats = UserStats()
    ) {
        self.id = id
        self.username = username
        self.displayName = displayName
        self.email = email
        self.avatarURL = avatarURL
        self.createdAt = createdAt
        self.stats = stats
    }

    static func == (lhs: User, rhs: User) -> Bool {
        lhs.id == rhs.id
    }
}

// MARK: - User Statistics
struct UserStats: Codable {
    var totalSwings: Int
    var averageScore: Double
    var bestScore: Int
    var totalPracticeTime: TimeInterval
    var currentStreak: Int
    var longestStreak: Int
    var clubStats: [ClubType: ClubStats]

    init(
        totalSwings: Int = 0,
        averageScore: Double = 0,
        bestScore: Int = 0,
        totalPracticeTime: TimeInterval = 0,
        currentStreak: Int = 0,
        longestStreak: Int = 0,
        clubStats: [ClubType: ClubStats] = [:]
    ) {
        self.totalSwings = totalSwings
        self.averageScore = averageScore
        self.bestScore = bestScore
        self.totalPracticeTime = totalPracticeTime
        self.currentStreak = currentStreak
        self.longestStreak = longestStreak
        self.clubStats = clubStats
    }

    // Global ranking score (weighted average)
    var rankingScore: Double {
        guard totalSwings > 0 else { return 0 }
        let swingBonus = min(Double(totalSwings) / 100.0, 1.0) * 10 // Max 10 points for 100+ swings
        return averageScore + swingBonus
    }
}

// MARK: - Club-specific Statistics
struct ClubStats: Codable {
    var swingCount: Int
    var averageScore: Double
    var bestScore: Int
    var lastUsed: Date

    init(
        swingCount: Int = 0,
        averageScore: Double = 0,
        bestScore: Int = 0,
        lastUsed: Date = Date()
    ) {
        self.swingCount = swingCount
        self.averageScore = averageScore
        self.bestScore = bestScore
        self.lastUsed = lastUsed
    }
}

// MARK: - Friend Model
struct Friendship: Identifiable, Codable {
    let id: String
    let userId: String
    let friendId: String
    let status: FriendshipStatus
    let createdAt: Date
    var friend: User?

    init(
        id: String = UUID().uuidString,
        userId: String,
        friendId: String,
        status: FriendshipStatus = .pending,
        createdAt: Date = Date(),
        friend: User? = nil
    ) {
        self.id = id
        self.userId = userId
        self.friendId = friendId
        self.status = status
        self.createdAt = createdAt
        self.friend = friend
    }
}

enum FriendshipStatus: String, Codable {
    case pending = "pending"
    case accepted = "accepted"
    case blocked = "blocked"
}

// MARK: - Friend Request
struct FriendRequest: Identifiable, Codable {
    let id: String
    let fromUser: User
    let toUserId: String
    let status: FriendshipStatus
    let createdAt: Date

    init(
        id: String = UUID().uuidString,
        fromUser: User,
        toUserId: String,
        status: FriendshipStatus = .pending,
        createdAt: Date = Date()
    ) {
        self.id = id
        self.fromUser = fromUser
        self.toUserId = toUserId
        self.status = status
        self.createdAt = createdAt
    }
}

// MARK: - Leaderboard Entry
struct LeaderboardEntry: Identifiable, Codable {
    let id: String
    let user: User
    let rank: Int
    let score: Double
    let swingCount: Int
    let updatedAt: Date

    var formattedScore: String {
        String(format: "%.1f", score)
    }

    var rankBadge: String {
        switch rank {
        case 1: return "🥇"
        case 2: return "🥈"
        case 3: return "🥉"
        default: return "#\(rank)"
        }
    }
}

// MARK: - Leaderboard Types
enum LeaderboardType: String, CaseIterable {
    case global = "Global"
    case friends = "Friends"
    case weekly = "Weekly"
    case monthly = "Monthly"

    var icon: String {
        switch self {
        case .global: return "globe"
        case .friends: return "person.2.fill"
        case .weekly: return "calendar"
        case .monthly: return "calendar.badge.clock"
        }
    }
}

// MARK: - Leaderboard Filter
enum LeaderboardFilter: String, CaseIterable {
    case overall = "Overall"
    case driver = "Driver"
    case irons = "Irons"
    case wedges = "Wedges"

    var clubTypes: [ClubType]? {
        switch self {
        case .overall: return nil
        case .driver: return [.driver]
        case .irons: return ClubCategory.iron.clubs
        case .wedges: return ClubCategory.wedge.clubs
        }
    }
}

// MARK: - Cloud Sync Status
struct SyncStatus: Codable {
    var lastSyncDate: Date?
    var pendingUploads: Int
    var pendingDownloads: Int
    var isSyncing: Bool

    init(
        lastSyncDate: Date? = nil,
        pendingUploads: Int = 0,
        pendingDownloads: Int = 0,
        isSyncing: Bool = false
    ) {
        self.lastSyncDate = lastSyncDate
        self.pendingUploads = pendingUploads
        self.pendingDownloads = pendingDownloads
        self.isSyncing = isSyncing
    }

    var needsSync: Bool {
        pendingUploads > 0 || pendingDownloads > 0
    }
}
