import SwiftUI

struct LeaderboardView: View {
    @StateObject private var socialManager = SocialManager.shared
    @EnvironmentObject var userSession: UserSession
    @State private var selectedType: LeaderboardType = .global
    @State private var selectedFilter: LeaderboardFilter = .overall

    var body: some View {
        VStack(spacing: 0) {
            // Leaderboard Type Picker
            Picker("Leaderboard", selection: $selectedType) {
                ForEach(LeaderboardType.allCases, id: \.self) { type in
                    Label(type.rawValue, systemImage: type.icon).tag(type)
                }
            }
            .pickerStyle(.segmented)
            .padding(.horizontal, AppSpacing.md)
            .padding(.vertical, AppSpacing.sm)

            // Filter Pills
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: AppSpacing.xs) {
                    ForEach(LeaderboardFilter.allCases, id: \.self) { filter in
                        FilterPill(
                            title: filter.rawValue,
                            isSelected: selectedFilter == filter
                        ) {
                            selectedFilter = filter
                        }
                    }
                }
                .padding(.horizontal, AppSpacing.md)
            }
            .padding(.bottom, AppSpacing.sm)

            // User's Current Rank Card
            if let user = userSession.currentUser,
               let rank = socialManager.userGlobalRank,
               selectedType == .global {
                CurrentUserRankCard(user: user, rank: rank)
                    .padding(.horizontal, AppSpacing.md)
                    .padding(.bottom, AppSpacing.sm)
            }

            // Leaderboard List
            if socialManager.isLoading {
                Spacer()
                ProgressView("Loading leaderboard...")
                Spacer()
            } else {
                LeaderboardList(entries: currentLeaderboard)
            }
        }
        .background(Color.backgroundPrimary)
        .task {
            if let userId = userSession.currentUser?.id {
                await socialManager.loadLeaderboards(for: userId)
            }
        }
        .refreshable {
            if let userId = userSession.currentUser?.id {
                await socialManager.loadLeaderboards(for: userId)
            }
        }
    }

    private var currentLeaderboard: [LeaderboardEntry] {
        switch selectedType {
        case .global, .weekly, .monthly:
            return socialManager.globalLeaderboard
        case .friends:
            return socialManager.friendsLeaderboard
        }
    }
}

// MARK: - Filter Pill
struct FilterPill: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(AppTypography.caption1)
                .fontWeight(isSelected ? .semibold : .regular)
                .foregroundColor(isSelected ? .white : .primary)
                .padding(.horizontal, AppSpacing.sm)
                .padding(.vertical, AppSpacing.xs)
                .background(isSelected ? Color.neverOBGreen : Color.cardBackground)
                .cornerRadius(AppCornerRadius.circular)
        }
    }
}

// MARK: - Current User Rank Card
struct CurrentUserRankCard: View {
    let user: User
    let rank: Int

    var body: some View {
        HStack(spacing: AppSpacing.md) {
            // Rank
            Text("#\(rank)")
                .font(AppTypography.title2)
                .fontWeight(.bold)
                .foregroundColor(.neverOBGreen)
                .frame(width: 60)

            // Avatar
            UserAvatar(user: user, size: 44)

            // Info
            VStack(alignment: .leading, spacing: 2) {
                Text("Your Ranking")
                    .font(AppTypography.caption1)
                    .foregroundColor(.secondary)

                Text(user.displayName)
                    .font(AppTypography.headline)
            }

            Spacer()

            // Score
            VStack(alignment: .trailing, spacing: 2) {
                Text(String(format: "%.1f", user.stats.averageScore))
                    .font(AppTypography.title3)
                    .fontWeight(.bold)
                    .foregroundColor(.neverOBGreen)

                Text("\(user.stats.totalSwings) swings")
                    .font(AppTypography.caption2)
                    .foregroundColor(.secondary)
            }
        }
        .padding(AppSpacing.md)
        .background(Color.neverOBGreen.opacity(0.1))
        .cornerRadius(AppCornerRadius.large)
        .overlay(
            RoundedRectangle(cornerRadius: AppCornerRadius.large)
                .stroke(Color.neverOBGreen.opacity(0.3), lineWidth: 1)
        )
    }
}

// MARK: - Leaderboard List
struct LeaderboardList: View {
    let entries: [LeaderboardEntry]

    var body: some View {
        ScrollView {
            LazyVStack(spacing: AppSpacing.xs) {
                ForEach(entries) { entry in
                    LeaderboardRow(entry: entry)
                }
            }
            .padding(.horizontal, AppSpacing.md)
            .padding(.bottom, AppSpacing.lg)
        }
    }
}

// MARK: - Leaderboard Row
struct LeaderboardRow: View {
    let entry: LeaderboardEntry

    var body: some View {
        HStack(spacing: AppSpacing.md) {
            // Rank
            RankBadge(rank: entry.rank)
                .frame(width: 44)

            // Avatar
            UserAvatar(user: entry.user, size: 40)

            // Name
            VStack(alignment: .leading, spacing: 2) {
                Text(entry.user.displayName)
                    .font(AppTypography.headline)
                    .lineLimit(1)

                Text("@\(entry.user.username)")
                    .font(AppTypography.caption2)
                    .foregroundColor(.secondary)
            }

            Spacer()

            // Score & Stats
            VStack(alignment: .trailing, spacing: 2) {
                Text(entry.formattedScore)
                    .font(AppTypography.headline)
                    .foregroundColor(scoreColor(for: entry.score))

                Text("\(entry.swingCount) swings")
                    .font(AppTypography.caption2)
                    .foregroundColor(.secondary)
            }
        }
        .padding(AppSpacing.sm)
        .background(entry.rank <= 3 ? rankBackground(entry.rank) : Color.cardBackground)
        .cornerRadius(AppCornerRadius.medium)
    }

    private func scoreColor(for score: Double) -> Color {
        switch score {
        case 90...: return .scoreExcellent
        case 80..<90: return .scoreGreat
        case 70..<80: return .scoreGood
        default: return .primary
        }
    }

    private func rankBackground(_ rank: Int) -> Color {
        switch rank {
        case 1: return Color.yellow.opacity(0.15)
        case 2: return Color.gray.opacity(0.15)
        case 3: return Color.orange.opacity(0.15)
        default: return Color.cardBackground
        }
    }
}

// MARK: - Rank Badge
struct RankBadge: View {
    let rank: Int

    var body: some View {
        Group {
            if rank <= 3 {
                Text(rankEmoji)
                    .font(.system(size: 24))
            } else {
                Text("#\(rank)")
                    .font(AppTypography.headline)
                    .foregroundColor(.secondary)
            }
        }
    }

    private var rankEmoji: String {
        switch rank {
        case 1: return "🥇"
        case 2: return "🥈"
        case 3: return "🥉"
        default: return "#\(rank)"
        }
    }
}

// MARK: - User Avatar
struct UserAvatar: View {
    let user: User
    let size: CGFloat

    var body: some View {
        Group {
            if let avatarURL = user.avatarURL {
                AsyncImage(url: avatarURL) { image in
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                } placeholder: {
                    avatarPlaceholder
                }
            } else {
                avatarPlaceholder
            }
        }
        .frame(width: size, height: size)
        .clipShape(Circle())
    }

    private var avatarPlaceholder: some View {
        ZStack {
            Circle()
                .fill(Color.neverOBGreen.opacity(0.2))

            Text(user.displayName.prefix(1).uppercased())
                .font(.system(size: size * 0.4, weight: .bold))
                .foregroundColor(.neverOBGreen)
        }
    }
}

#Preview {
    NavigationStack {
        LeaderboardView()
    }
    .environmentObject(UserSession.shared)
}
