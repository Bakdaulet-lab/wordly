import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../constants/app_colors.dart';
import '../../constants/app_text_styles.dart';
import '../../providers/auth_provider.dart';
import '../../providers/profile_provider.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  Future<void> _handleLogout() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Log Out'),
        content: const Text('Are you sure you want to log out?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.errorRed,
              foregroundColor: Colors.white,
            ),
            child: const Text('Log Out'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    final authProvider = context.read<AuthProvider>();
    await authProvider.signOut();
    if (mounted) {
      context.go('/login');
    }
  }

  void _showEditNameDialog() {
    final userId = context.read<AuthProvider>().user?.id;
    if (userId == null) return;

    final currentName = context.read<ProfileProvider>().displayName;
    final nameController = TextEditingController(text: currentName);

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Edit Display Name'),
        content: TextField(
          controller: nameController,
          autofocus: true,
          textCapitalization: TextCapitalization.words,
          decoration: const InputDecoration(
            labelText: 'Display Name',
            prefixIcon: Icon(Icons.person_outlined),
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              final newName = nameController.text.trim();
              if (newName.isEmpty) return;
              Navigator.of(dialogContext).pop();

              final profileProvider = context.read<ProfileProvider>();
              final success = await profileProvider.updateDisplayName(
                userId,
                newName,
              );

              if (!mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    success ? 'Name updated!' : 'Failed to update name.',
                  ),
                  backgroundColor:
                      success ? AppColors.successGreen : AppColors.errorRed,
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
            ),
            child: const Text('Save'),
          ),
        ],
      ),
    ).then((_) => nameController.dispose());
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Consumer<ProfileProvider>(
          builder: (context, profileProvider, child) {
            if (profileProvider.isLoading) {
              return const Center(
                child: Padding(
                  padding: EdgeInsets.all(48),
                  child: CircularProgressIndicator(color: AppColors.primary),
                ),
              );
            }

            if (profileProvider.errorMessage != null) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.error_outline,
                      size: 64,
                      color: AppColors.errorRed,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      profileProvider.errorMessage!,
                      style: AppTextStyles.bodyMedium.copyWith(
                        color: AppColors.errorRed,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              );
            }

            final profile = profileProvider.profile;
            final displayName = profileProvider.displayName;
            final email =
                context.read<AuthProvider>().user?.email ?? 'No email';
            final level = profileProvider.level;
            final totalXp = profileProvider.totalXp;
            final currentStreak = profileProvider.currentStreak;
            final longestStreak = profileProvider.longestStreak;
            final memberSince = profile?.createdAt;

            return Column(
              children: [
                const SizedBox(height: 16),

                // Avatar
                CircleAvatar(
                  radius: 48,
                  backgroundColor: AppColors.primary.withValues(alpha: 0.15),
                  child: Text(
                    displayName.isNotEmpty
                        ? displayName[0].toUpperCase()
                        : '?',
                    style: AppTextStyles.heading1.copyWith(
                      color: AppColors.primary,
                      fontSize: 36,
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Display name with edit button
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      displayName.isNotEmpty ? displayName : 'Learner',
                      style: AppTextStyles.heading2,
                    ),
                    const SizedBox(width: 4),
                    IconButton(
                      onPressed: _showEditNameDialog,
                      icon: const Icon(
                        Icons.edit_rounded,
                        size: 18,
                        color: AppColors.textHint,
                      ),
                      visualDensity: VisualDensity.compact,
                      tooltip: 'Edit name',
                    ),
                  ],
                ),
                const SizedBox(height: 4),

                // Email
                Text(
                  email,
                  style: AppTextStyles.bodyMedium,
                ),
                const SizedBox(height: 32),

                // Stats grid
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: AppColors.cardBackground,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.05),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: _buildStatItem(
                              icon: Icons.trending_up_rounded,
                              iconColor: AppColors.primary,
                              label: 'Level',
                              value: '$level',
                            ),
                          ),
                          Container(
                            width: 1,
                            height: 48,
                            color: AppColors.textHint.withValues(alpha: 0.2),
                          ),
                          Expanded(
                            child: _buildStatItem(
                              icon: Icons.star_rounded,
                              iconColor: AppColors.xpGold,
                              label: 'Total XP',
                              value: '$totalXp',
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      Divider(
                        color: AppColors.textHint.withValues(alpha: 0.2),
                        height: 1,
                      ),
                      const SizedBox(height: 20),
                      Row(
                        children: [
                          Expanded(
                            child: _buildStatItem(
                              icon: Icons.local_fire_department_rounded,
                              iconColor: AppColors.streakOrange,
                              label: 'Current Streak',
                              value:
                                  '$currentStreak day${currentStreak == 1 ? '' : 's'}',
                            ),
                          ),
                          Container(
                            width: 1,
                            height: 48,
                            color: AppColors.textHint.withValues(alpha: 0.2),
                          ),
                          Expanded(
                            child: _buildStatItem(
                              icon: Icons.emoji_events_rounded,
                              iconColor: AppColors.xpGold,
                              label: 'Longest Streak',
                              value:
                                  '$longestStreak day${longestStreak == 1 ? '' : 's'}',
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // Member since
                if (memberSince != null)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.cardBackground,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.05),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.calendar_today_rounded,
                          color: AppColors.primary,
                          size: 20,
                        ),
                        const SizedBox(width: 12),
                        Text(
                          'Member since',
                          style: AppTextStyles.bodyMedium,
                        ),
                        const Spacer(),
                        Text(
                          _formatDate(memberSince),
                          style: AppTextStyles.bodyLarge.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                const SizedBox(height: 32),

                // Log out button
                SizedBox(
                  width: double.infinity,
                  child: Consumer<AuthProvider>(
                    builder: (context, auth, child) {
                      return ElevatedButton(
                        onPressed: auth.isLoading ? null : _handleLogout,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.errorRed,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: auth.isLoading
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Icon(Icons.logout_rounded, size: 20),
                                  const SizedBox(width: 8),
                                  Text(
                                    'Log Out',
                                    style: AppTextStyles.button,
                                  ),
                                ],
                              ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 24),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildStatItem({
    required IconData icon,
    required Color iconColor,
    required String label,
    required String value,
  }) {
    return Column(
      children: [
        Icon(icon, color: iconColor, size: 28),
        const SizedBox(height: 8),
        Text(
          value,
          style: AppTextStyles.heading3,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: AppTextStyles.caption,
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  String _formatDate(DateTime date) {
    final months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    return '${months[date.month - 1]} ${date.day}, ${date.year}';
  }
}
