import SwiftUI

struct FriendsView: View {
    @StateObject private var socialManager = SocialManager.shared
    @EnvironmentObject var userSession: UserSession
    @State private var searchText = ""
    @State private var searchResults: [User] = []
    @State private var isSearching = false
    @State private var showAddFriend = false

    var body: some View {
        VStack(spacing: 0) {
            // Pending Requests Section
            if !socialManager.pendingRequests.isEmpty {
                PendingRequestsSection(
                    requests: socialManager.pendingRequests,
                    onAccept: { request in
                        Task { await socialManager.acceptRequest(request) }
                    },
                    onDecline: { request in
                        Task { await socialManager.declineRequest(request) }
                    }
                )
            }

            // Friends List
            if socialManager.isLoading {
                Spacer()
                ProgressView("Loading friends...")
                Spacer()
            } else if socialManager.friends.isEmpty {
                EmptyFriendsView(onAddFriend: { showAddFriend = true })
            } else {
                FriendsList(
                    friends: socialManager.friends,
                    onRemove: { friendship in
                        Task { await socialManager.removeFriend(friendship) }
                    }
                )
            }
        }
        .background(Color.backgroundPrimary)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(action: { showAddFriend = true }) {
                    Image(systemName: "person.badge.plus")
                        .foregroundColor(.neverOBGreen)
                }
            }
        }
        .sheet(isPresented: $showAddFriend) {
            AddFriendSheet(
                searchText: $searchText,
                searchResults: $searchResults,
                isSearching: $isSearching,
                onSearch: performSearch,
                onSendRequest: sendFriendRequest
            )
        }
        .task {
            if let userId = userSession.currentUser?.id {
                await socialManager.loadFriends(for: userId)
            }
        }
    }

    private func performSearch() async {
        isSearching = true
        searchResults = await socialManager.searchUsers(query: searchText)
        isSearching = false
    }

    private func sendFriendRequest(to user: User) {
        guard let currentUser = userSession.currentUser else { return }
        Task {
            await socialManager.sendFriendRequest(to: user.id, from: currentUser)
        }
    }
}

// MARK: - Pending Requests Section
struct PendingRequestsSection: View {
    let requests: [FriendRequest]
    let onAccept: (FriendRequest) -> Void
    let onDecline: (FriendRequest) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: AppSpacing.sm) {
            SectionHeader("Pending Requests")

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: AppSpacing.sm) {
                    ForEach(requests) { request in
                        PendingRequestCard(
                            request: request,
                            onAccept: { onAccept(request) },
                            onDecline: { onDecline(request) }
                        )
                    }
                }
                .padding(.horizontal, AppSpacing.md)
            }
        }
        .padding(.vertical, AppSpacing.sm)
        .background(Color.neverOBGreen.opacity(0.05))
    }
}

// MARK: - Pending Request Card
struct PendingRequestCard: View {
    let request: FriendRequest
    let onAccept: () -> Void
    let onDecline: () -> Void

    var body: some View {
        VStack(spacing: AppSpacing.sm) {
            UserAvatar(user: request.fromUser, size: 56)

            Text(request.fromUser.displayName)
                .font(AppTypography.subheadline)
                .lineLimit(1)

            HStack(spacing: AppSpacing.xs) {
                Button(action: onAccept) {
                    Image(systemName: "checkmark")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(.white)
                        .padding(8)
                        .background(Color.neverOBGreen)
                        .clipShape(Circle())
                }

                Button(action: onDecline) {
                    Image(systemName: "xmark")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(.white)
                        .padding(8)
                        .background(Color.red)
                        .clipShape(Circle())
                }
            }
        }
        .padding(AppSpacing.sm)
        .frame(width: 100)
        .background(Color.cardBackground)
        .cornerRadius(AppCornerRadius.medium)
    }
}

// MARK: - Friends List
struct FriendsList: View {
    let friends: [Friendship]
    let onRemove: (Friendship) -> Void

    var body: some View {
        List {
            ForEach(friends) { friendship in
                if let friend = friendship.friend {
                    FriendRow(friend: friend)
                        .swipeActions(edge: .trailing) {
                            Button(role: .destructive) {
                                onRemove(friendship)
                            } label: {
                                Label("Remove", systemImage: "person.badge.minus")
                            }
                        }
                }
            }
        }
        .listStyle(.plain)
    }
}

// MARK: - Friend Row
struct FriendRow: View {
    let friend: User

    var body: some View {
        HStack(spacing: AppSpacing.md) {
            UserAvatar(user: friend, size: 50)

            VStack(alignment: .leading, spacing: 4) {
                Text(friend.displayName)
                    .font(AppTypography.headline)

                Text("@\(friend.username)")
                    .font(AppTypography.caption1)
                    .foregroundColor(.secondary)
            }

            Spacer()

            // Friend's Stats
            VStack(alignment: .trailing, spacing: 4) {
                HStack(spacing: 4) {
                    Image(systemName: "chart.bar.fill")
                        .font(.system(size: 12))
                        .foregroundColor(.neverOBGreen)
                    Text(String(format: "%.0f", friend.stats.averageScore))
                        .font(AppTypography.headline)
                        .foregroundColor(.neverOBGreen)
                }

                Text("\(friend.stats.totalSwings) swings")
                    .font(AppTypography.caption2)
                    .foregroundColor(.secondary)
            }
        }
        .padding(.vertical, AppSpacing.xs)
    }
}

// MARK: - Empty Friends View
struct EmptyFriendsView: View {
    let onAddFriend: () -> Void

    var body: some View {
        VStack(spacing: AppSpacing.lg) {
            Spacer()

            Image(systemName: "person.2.fill")
                .font(.system(size: 60))
                .foregroundColor(.neverOBGreen.opacity(0.5))

            Text("No Friends Yet")
                .font(AppTypography.title3)

            Text("Add friends to compare scores and compete on the leaderboard!")
                .font(AppTypography.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, AppSpacing.xl)

            Button(action: onAddFriend) {
                HStack {
                    Image(systemName: "person.badge.plus")
                    Text("Add Friends")
                }
            }
            .buttonStyle(PrimaryButtonStyle())
            .padding(.horizontal, AppSpacing.xxl)

            Spacer()
        }
    }
}

// MARK: - Add Friend Sheet
struct AddFriendSheet: View {
    @Environment(\.dismiss) var dismiss
    @Binding var searchText: String
    @Binding var searchResults: [User]
    @Binding var isSearching: Bool
    let onSearch: () async -> Void
    let onSendRequest: (User) -> Void

    @State private var sentRequests: Set<String> = []

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Search Bar
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(.secondary)

                    TextField("Search by username", text: $searchText)
                        .textFieldStyle(.plain)
                        .autocapitalization(.none)
                        .disableAutocorrection(true)
                        .onSubmit {
                            Task { await onSearch() }
                        }

                    if !searchText.isEmpty {
                        Button(action: { searchText = "" }) {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundColor(.secondary)
                        }
                    }
                }
                .padding(AppSpacing.sm)
                .background(Color.cardBackground)
                .cornerRadius(AppCornerRadius.medium)
                .padding(AppSpacing.md)

                Divider()

                // Results
                if isSearching {
                    Spacer()
                    ProgressView("Searching...")
                    Spacer()
                } else if searchResults.isEmpty && !searchText.isEmpty {
                    Spacer()
                    VStack(spacing: AppSpacing.sm) {
                        Image(systemName: "person.fill.questionmark")
                            .font(.system(size: 40))
                            .foregroundColor(.secondary)
                        Text("No users found")
                            .foregroundColor(.secondary)
                    }
                    Spacer()
                } else {
                    List(searchResults) { user in
                        SearchResultRow(
                            user: user,
                            requestSent: sentRequests.contains(user.id)
                        ) {
                            onSendRequest(user)
                            sentRequests.insert(user.id)
                        }
                    }
                    .listStyle(.plain)
                }
            }
            .navigationTitle("Add Friends")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }
}

// MARK: - Search Result Row
struct SearchResultRow: View {
    let user: User
    let requestSent: Bool
    let onSendRequest: () -> Void

    var body: some View {
        HStack(spacing: AppSpacing.md) {
            UserAvatar(user: user, size: 44)

            VStack(alignment: .leading, spacing: 2) {
                Text(user.displayName)
                    .font(AppTypography.headline)

                Text("@\(user.username)")
                    .font(AppTypography.caption1)
                    .foregroundColor(.secondary)
            }

            Spacer()

            if requestSent {
                Text("Sent")
                    .font(AppTypography.caption1)
                    .foregroundColor(.secondary)
                    .padding(.horizontal, AppSpacing.sm)
                    .padding(.vertical, AppSpacing.xxs)
                    .background(Color.cardBackground)
                    .cornerRadius(AppCornerRadius.small)
            } else {
                Button(action: onSendRequest) {
                    Image(systemName: "plus")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(.white)
                        .padding(8)
                        .background(Color.neverOBGreen)
                        .clipShape(Circle())
                }
            }
        }
        .padding(.vertical, AppSpacing.xxs)
    }
}

#Preview {
    NavigationStack {
        FriendsView()
    }
    .environmentObject(UserSession.shared)
}
