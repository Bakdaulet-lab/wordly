import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../constants/app_colors.dart';
import '../../constants/app_text_styles.dart';
import '../../constants/app_theme.dart';
import '../../providers/auth_provider.dart';
import '../../providers/leaderboard_provider.dart';
import '../../models/leaderboard_entry.dart';

class LeaderboardScreen extends StatefulWidget {
  const LeaderboardScreen({super.key});

  @override
  State<LeaderboardScreen> createState() => _LeaderboardScreenState();
}

class _LeaderboardScreenState extends State<LeaderboardScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(() {
      final tab = LeaderboardTab.values[_tabController.index];
      context.read<LeaderboardProvider>().setActiveTab(tab);
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadData();
    });
  }

  void _loadData() {
    final userId = context.read<AuthProvider>().user?.id;
    if (userId == null) return;
    context.read<LeaderboardProvider>().loadLeaderboard(userId);
    context.read<LeaderboardProvider>().loadFriends(userId);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background(context),
      appBar: AppBar(
        title: const Text('Leaderboard'),
        backgroundColor: AppTheme.surface(context),
        actions: [
          IconButton(
            icon: const Icon(Icons.person_add_rounded),
            tooltip: 'Add Friend',
            onPressed: () => _showAddFriendDialog(),
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppTheme.primary(context),
          unselectedLabelColor: AppTheme.textHint(context),
          indicatorColor: AppTheme.primary(context),
          tabs: const [
            Tab(text: 'Global', icon: Icon(Icons.public, size: 18)),
            Tab(text: 'Weekly', icon: Icon(Icons.date_range, size: 18)),
            Tab(text: 'Friends', icon: Icon(Icons.group, size: 18)),
          ],
        ),
      ),
      body: Consumer<LeaderboardProvider>(
        builder: (context, provider, _) {
          if (provider.isLoading) {
            return const Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            );
          }

          if (provider.errorMessage != null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline,
                      size: 48, color: AppColors.errorRed,),
                  const SizedBox(height: 12),
                  Text(provider.errorMessage!,
                      style: AppTextStyles.bodyMedium,),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: _loadData,
                    child: const Text('Retry'),
                  ),
                ],
              ),
            );
          }

          return TabBarView(
            controller: _tabController,
            children: [
              _buildLeaderboardList(
                  provider.globalEntries, provider.userRank,),
              _buildLeaderboardList(
                  provider.weeklyEntries, null,),
              _buildFriendsTab(provider),
            ],
          );
        },
      ),
    );
  }

  Widget _buildLeaderboardList(List<LeaderboardEntry> entries, int? userRank) {
    final userId = context.read<AuthProvider>().user?.id;

    if (entries.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.emoji_events_outlined,
                size: 64, color: AppTheme.textHint(context),),
            const SizedBox(height: 16),
            const Text('No entries yet', style: AppTextStyles.bodyLarge),
            const SizedBox(height: 8),
            const Text('Start learning to appear on the leaderboard!',
                style: AppTextStyles.bodyMedium,),
          ],
        ),
      );
    }

    return Column(
      children: [
        if (userRank != null)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            color: AppTheme.primary(context).withValues(alpha: 0.1),
            child: Row(
              children: [
                Icon(Icons.person, color: AppTheme.primary(context)),
                const SizedBox(width: 8),
                Text('Your Rank: #$userRank',
                    style: AppTextStyles.heading3.copyWith(
                      color: AppTheme.primary(context),
                    ),),
              ],
            ),
          ),
        Expanded(
          child: RefreshIndicator(
            onRefresh: () async => _loadData(),
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(vertical: 8),
              itemCount: entries.length,
              itemBuilder: (context, index) {
                final entry = entries[index];
                final isCurrentUser = entry.userId == userId;
                return _buildEntryTile(entry, isCurrentUser);
              },
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildEntryTile(LeaderboardEntry entry, bool isCurrentUser) {
    final rankWidget = _buildRankBadge(entry.rank);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: isCurrentUser
            ? AppTheme.primary(context).withValues(alpha: 0.08)
            : AppTheme.card(context),
        borderRadius: BorderRadius.circular(12),
        border: isCurrentUser
            ? Border.all(color: AppTheme.primary(context), width: 1.5)
            : Border.all(color: Colors.transparent),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 4,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: ListTile(
        leading: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(width: 36, child: Center(child: rankWidget)),
            const SizedBox(width: 8),
            CircleAvatar(
              radius: 20,
              backgroundColor: AppTheme.primary(context).withValues(alpha: 0.15),
              child: Text(
                entry.displayName.isNotEmpty
                    ? entry.displayName[0].toUpperCase()
                    : '?',
                style: TextStyle(
                  color: AppTheme.primary(context),
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        title: Text(
          entry.displayName.isNotEmpty ? entry.displayName : 'Anonymous',
          style: AppTextStyles.bodyLarge.copyWith(
            fontWeight: isCurrentUser ? FontWeight.bold : FontWeight.w500,
            color: AppTheme.textPrimary(context),
          ),
        ),
        subtitle: Text(
          'Level ${entry.level}',
          style: AppTextStyles.bodySmall.copyWith(
            color: AppTheme.textSecondary(context),
          ),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.star_rounded, color: AppColors.xpGold, size: 18),
            const SizedBox(width: 4),
            Text(
              '${entry.totalXp} XP',
              style: AppTextStyles.bodyLarge.copyWith(
                fontWeight: FontWeight.bold,
                color: AppColors.xpGold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRankBadge(int rank) {
    if (rank == 1) {
      return const Text('🥇', style: TextStyle(fontSize: 24));
    }
    if (rank == 2) {
      return const Text('🥈', style: TextStyle(fontSize: 24));
    }
    if (rank == 3) {
      return const Text('🥉', style: TextStyle(fontSize: 24));
    }
    return Text(
      '#$rank',
      style: AppTextStyles.bodyMedium.copyWith(
        fontWeight: FontWeight.w600,
        color: AppTheme.textSecondary(context),
      ),
    );
  }

  Widget _buildFriendsTab(LeaderboardProvider provider) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Pending requests
          if (provider.pendingRequests.isNotEmpty) ...[
            Text('Friend Requests (${provider.pendingRequests.length})',
                style: AppTextStyles.heading3.copyWith(
                  color: AppTheme.textPrimary(context),
                ),),
            const SizedBox(height: 8),
            ...provider.pendingRequests.map((req) => _buildRequestTile(req)),
            const SizedBox(height: 24),
          ],

          // Friends leaderboard
          Text('Friends Leaderboard', style: AppTextStyles.heading3.copyWith(
            color: AppTheme.textPrimary(context),
          ),),
          const SizedBox(height: 8),
          if (provider.friendsEntries.isEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppTheme.card(context),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  Icon(Icons.group_add_rounded,
                      size: 48, color: AppTheme.textHint(context),),
                  const SizedBox(height: 12),
                  Text('Add friends to compare progress!',
                      style: AppTextStyles.bodyMedium.copyWith(
                        color: AppTheme.textSecondary(context),
                      ),),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    onPressed: _showAddFriendDialog,
                    icon: const Icon(Icons.person_add),
                    label: const Text('Add Friend'),
                  ),
                ],
              ),
            )
          else
            ...provider.friendsEntries.map((entry) {
              final userId = context.read<AuthProvider>().user?.id;
              return _buildEntryTile(entry, entry.userId == userId);
            }),

          const SizedBox(height: 24),

          // Friends list
          Text('My Friends (${provider.friends.length})',
              style: AppTextStyles.heading3.copyWith(
                color: AppTheme.textPrimary(context),
              ),),
          const SizedBox(height: 8),
          if (provider.friends.isEmpty)
            Text('No friends yet',
                style: AppTextStyles.bodyMedium.copyWith(
                  color: AppTheme.textSecondary(context),
                ),)
          else
            ...provider.friends.map((f) => _buildFriendTile(f)),
        ],
      ),
    );
  }

  Widget _buildRequestTile(dynamic request) {
    final userId = context.read<AuthProvider>().user?.id ?? '';
    final friendName = request.friendDisplayName ?? 'Unknown';

    return Card(
      color: AppTheme.card(context),
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: AppColors.streakOrange.withValues(alpha: 0.15),
          child: Text(
            friendName.isNotEmpty ? friendName[0].toUpperCase() : '?',
            style: const TextStyle(
                color: AppColors.streakOrange, fontWeight: FontWeight.bold,),
          ),
        ),
        title: Text(friendName, style: TextStyle(
          color: AppTheme.textPrimary(context),
        ),),
        subtitle: Text('Wants to be friends', style: TextStyle(
          color: AppTheme.textSecondary(context),
        ),),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon:
                  const Icon(Icons.check_circle, color: AppColors.successGreen),
              onPressed: () {
                context.read<LeaderboardProvider>().acceptFriendRequest(
                      userId: userId,
                      friendId: request.userId,
                    );
              },
            ),
            IconButton(
              icon: const Icon(Icons.cancel, color: AppColors.errorRed),
              onPressed: () {
                context.read<LeaderboardProvider>().rejectFriendRequest(
                      userId: userId,
                      fromUserId: request.userId,
                    );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFriendTile(dynamic friend) {
    final userId = context.read<AuthProvider>().user?.id ?? '';
    final name = friend.friendDisplayName ?? 'Unknown';
    final level = friend.friendLevel ?? 1;
    final xp = friend.friendTotalXp ?? 0;

    return Card(
      color: AppTheme.card(context),
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: AppTheme.primary(context).withValues(alpha: 0.15),
          child: Text(
            name.isNotEmpty ? name[0].toUpperCase() : '?',
            style: TextStyle(
                color: AppTheme.primary(context), fontWeight: FontWeight.bold,),
          ),
        ),
        title: Text(name, style: TextStyle(
          color: AppTheme.textPrimary(context),
        ),),
        subtitle: Text('Level $level • $xp XP', style: TextStyle(
          color: AppTheme.textSecondary(context),
        ),),
        trailing: IconButton(
          icon: const Icon(Icons.person_remove, color: AppColors.errorRed),
          tooltip: 'Remove friend',
          onPressed: () async {
            final confirmed = await showDialog<bool>(
              context: context,
              builder: (ctx) => AlertDialog(
                title: const Text('Remove Friend'),
                content: Text('Remove $name from your friends?'),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(ctx, false),
                    child: const Text('Cancel'),
                  ),
                  ElevatedButton(
                    onPressed: () => Navigator.pop(ctx, true),
                    style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.errorRed,),
                    child: const Text('Remove'),
                  ),
                ],
              ),
            );
            if (confirmed == true && mounted) {
              context.read<LeaderboardProvider>().removeFriend(
                    userId: userId,
                    friendId: friend.friendId,
                  );
            }
          },
        ),
      ),
    );
  }

  void _showAddFriendDialog() {
    final userId = context.read<AuthProvider>().user?.id ?? '';
    final searchController = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppTheme.surface(context),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return DraggableScrollableSheet(
          expand: false,
          initialChildSize: 0.6,
          minChildSize: 0.3,
          maxChildSize: 0.9,
          builder: (context, scrollController) {
            return Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Add Friend', style: AppTextStyles.heading2.copyWith(
                    color: AppTheme.textPrimary(context),
                  ),),
                  const SizedBox(height: 16),
                  TextField(
                    controller: searchController,
                    decoration: InputDecoration(
                      hintText: 'Search by name...',
                      prefixIcon: const Icon(Icons.search),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onChanged: (query) {
                      ctx
                          .read<LeaderboardProvider>()
                          .searchUsers(query, userId);
                    },
                  ),
                  const SizedBox(height: 16),
                  Expanded(
                    child: Consumer<LeaderboardProvider>(
                      builder: (context, provider, _) {
                        final results = provider.searchResults;
                        if (results.isEmpty) {
                          return Center(
                            child: Text(
                              searchController.text.isEmpty
                                  ? 'Type a name to search'
                                  : 'No users found',
                              style: AppTextStyles.bodyMedium.copyWith(
                                color: AppTheme.textSecondary(context),
                              ),
                            ),
                          );
                        }
                        return ListView.builder(
                          controller: scrollController,
                          itemCount: results.length,
                          itemBuilder: (context, index) {
                            final user = results[index];
                            final name = user['display_name'] ?? 'Unknown';
                            return ListTile(
                              leading: CircleAvatar(
                                backgroundColor: AppTheme.primary(context)
                                    .withValues(alpha: 0.15),
                                child: Text(
                                  name.toString().isNotEmpty
                                      ? name.toString()[0].toUpperCase()
                                      : '?',
                                  style: TextStyle(
                                    color: AppTheme.primary(context),
                                  ),
                                ),
                              ),
                              title: Text(name.toString(), style: TextStyle(
                                color: AppTheme.textPrimary(context),
                              ),),
                              subtitle: Text(
                                  'Level ${user['level']} • ${user['total_xp']} XP',
                                  style: TextStyle(
                                    color: AppTheme.textSecondary(context),
                                  ),),
                              trailing: IconButton(
                                icon: const Icon(Icons.person_add,
                                    color: AppColors.primary,),
                                onPressed: () async {
                                  final success = await ctx
                                      .read<LeaderboardProvider>()
                                      .sendFriendRequest(
                                        userId: userId,
                                        friendId: user['id'] as String,
                                      );
                                  if (ctx.mounted) {
                                    ScaffoldMessenger.of(ctx).showSnackBar(
                                      SnackBar(
                                        content: Text(success
                                            ? 'Request sent!'
                                            : 'Failed to send request',),
                                        backgroundColor: success
                                            ? AppColors.successGreen
                                            : AppColors.errorRed,
                                      ),
                                    );
                                  }
                                },
                              ),
                            );
                          },
                        );
                      },
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    ).then((_) => searchController.dispose());
  }
}
