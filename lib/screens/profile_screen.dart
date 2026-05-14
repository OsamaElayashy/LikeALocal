import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_provider.dart';
import '../services/auth_service.dart';
import '../services/database_service.dart';
import '../models/user_model.dart';
import 'add_place_screen.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  Future<void> _logout(BuildContext context) async {
    // Show confirmation dialog first
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Log out'),
        content: const Text('Are you sure you want to log out?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Log out',
                style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    await AuthService().logout();
    if (context.mounted) {
      Provider.of<AppProvider>(context, listen: false).clearUser();
      Navigator.of(context)
          .pushNamedAndRemoveUntil('/login', (route) => false);
    }
  }

  Future<void> _togglePrivacy(
      BuildContext context, bool currentValue) async {
    final user =
        Provider.of<AppProvider>(context, listen: false).currentUser;
    if (user == null) return;

    await DatabaseService().updatePrivacyMode(user.id, !currentValue);

    // Reload user so UI updates
    if (context.mounted) {
      await Provider.of<AppProvider>(context, listen: false)
          .reloadUser();
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('Profile'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout_outlined,
                color: Colors.red),
            tooltip: 'Log out',
            onPressed: () => _logout(context),
          ),
        ],
      ),
      body: Consumer<AppProvider>(
        builder: (context, app, _) {
          final user = app.currentUser;
          if (user == null) {
            return const Center(child: CircularProgressIndicator());
          }
          final createdPlaces = app.places.where((p) => p.contributorId == user.id).toList();
          return ListView(
            padding: const EdgeInsets.all(20),
            children: [

              // Avatar + name
              Center(
                child: Column(children: [
                  CircleAvatar(
                    radius: 40,
                    backgroundColor: const Color(0xFFEFF6FF),
                    child: Text(
                      user.initials,
                      style: const TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF2563EB),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        user.name,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1A1A2E),
                        ),
                      ),
                      if (user.isSuperUser) ...[
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFEF9C3),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Text(
                            '⭐ Super User',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF92400E),
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(user.email,
                      style: const TextStyle(
                          color: Color(0xFF6B7280), fontSize: 13)),
                ]),
              ),

              const SizedBox(height: 28),

              // Stats row
              Row(children: [
                _statCard('Places', user.contributionCount.toString()),
                const SizedBox(width: 12),
                _statCard('Reviews', user.reviewCount.toString()),
                const SizedBox(width: 12),
                _statCard('Saved',
                    '${user.pinCount}/${UserModel.kFreePinLimit}'),
              ]),

              const SizedBox(height: 28),

              // Saved bookmarks shortcut
              Container(
                decoration: BoxDecoration(
                  color: Theme.of(context).cardColor,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFE5E7EB)),
                ),
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  leading: const Icon(Icons.bookmark_outline,
                      color: Color(0xFF2563EB)),
                  title: const Text(
                    'Saved places',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  subtitle: Text(
                    '${app.savedPlaces.length} bookmarked place${app.savedPlaces.length == 1 ? '' : 's'}',
                    style: const TextStyle(color: Color(0xFF6B7280)),
                  ),
                  trailing: const Icon(Icons.chevron_right,
                      color: Color(0xFF9CA3AF)),
                  onTap: () {
                    Navigator.of(context).pushNamed('/bookmarks');
                  },
                ),
              ),

              const SizedBox(height: 28),

              // User-owned places
              const Text(
                'Your places',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF6B7280),
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 12),
              if (createdPlaces.isEmpty)
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF9FAFB),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFE5E7EB)),
                  ),
                  child: const Text(
                    'You have not added any places yet. Tap Add to create one.',
                    style: TextStyle(color: Color(0xFF6B7280)),
                  ),
                )
              else
                ...createdPlaces.map((place) {
                  return Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Theme.of(context).cardColor,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFE5E7EB)),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                place.title,
                                style: const TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                place.city,
                                style: const TextStyle(
                                  color: Color(0xFF6B7280),
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.edit_outlined,
                              color: Color(0xFF2563EB)),
                          onPressed: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (ctx) => AddPlaceScreen(
                                  existingPlace: place,
                                ),
                              ),
                            );
                          },
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete_outline,
                              color: Colors.redAccent),
                          onPressed: () async {
                            final messenger = ScaffoldMessenger.of(context);
                            final appProvider = Provider.of<AppProvider>(context,
                                listen: false);
                            final confirmed = await showDialog<bool>(
                              context: context,
                              builder: (ctx) => AlertDialog(
                                title: const Text('Delete place'),
                                content: const Text(
                                    'Are you sure you want to delete this place?'),
                                actions: [
                                  TextButton(
                                    onPressed: () => Navigator.of(ctx).pop(false),
                                    child: const Text('Cancel'),
                                  ),
                                  TextButton(
                                    onPressed: () => Navigator.of(ctx).pop(true),
                                    child: const Text('Delete',
                                        style: TextStyle(color: Colors.red)),
                                  ),
                                ],
                              ),
                            );
                            if (confirmed != true) return;
                            await appProvider.deletePlace(place.id);
                            messenger.showSnackBar(
                              const SnackBar(content: Text('Place deleted')),
                            );
                          },
                        ),
                      ],
                    ),
                  );
                }),

              const SizedBox(height: 28),

              // Settings section
              const Text(
                'Settings',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF6B7280),
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 12),

              // Privacy toggle
              Container(
                decoration: BoxDecoration(
                  color: Theme.of(context).cardColor,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFE5E7EB)),
                ),
                child: SwitchListTile(
                  title: const Text(
                    'Private mode',
                    style: TextStyle(
                        fontSize: 15, fontWeight: FontWeight.w500),
                  ),
                  subtitle: const Text(
                    'Turn off to stop others from chatting with you',
                    style:
                        TextStyle(fontSize: 12, color: Color(0xFF6B7280)),
                  ),
                  value: user.chatPrivacyEnabled,
                  activeThumbColor: const Color(0xFF2563EB),
                  onChanged: (_) =>
                      _togglePrivacy(context, user.chatPrivacyEnabled),
                ),
              ),

              const SizedBox(height: 12),

              // Theme toggle
              Container(
                decoration: BoxDecoration(
                  color: Theme.of(context).cardColor,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFE5E7EB)),
                ),
                child: SwitchListTile(
                  title: const Text(
                    'Dark mode',
                    style: TextStyle(
                        fontSize: 15, fontWeight: FontWeight.w500),
                  ),
                  subtitle: const Text(
                    'Switch between light and dark themes',
                    style:
                        TextStyle(fontSize: 12, color: Color(0xFF6B7280)),
                  ),
                  value: app.isDarkMode,
                  activeThumbColor: const Color(0xFF2563EB),
                  onChanged: (_) => app.toggleTheme(),
                ),
              ),

              // Super user progress (if not yet)
              if (!user.isSuperUser)
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFFBEB),
                    borderRadius: BorderRadius.circular(12),
                    border:
                        Border.all(color: const Color(0xFFFDE68A)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        '⭐ Become a Super User',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF92400E),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Add ${(5 - user.contributionCount).clamp(0, 5)} more places or write ${(10 - user.reviewCount).clamp(0, 10)} more reviews',
                        style: const TextStyle(
                          fontSize: 12,
                          color: Color(0xFF92400E),
                        ),
                      ),
                    ],
                  ),
                ),

              const SizedBox(height: 28),

              // Logout button
              OutlinedButton.icon(
                onPressed: () => _logout(context),
                icon: const Icon(Icons.logout, color: Colors.red, size: 18),
                label: const Text('Log out',
                    style: TextStyle(color: Colors.red)),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Colors.red),
                  minimumSize: const Size(double.infinity, 48),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _statCard(String label, String value) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: const Color(0xFFF9FAFB),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: const Color(0xFFE5E7EB)),
        ),
        child: Column(children: [
          Text(value,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1A1A2E),
              )),
          const SizedBox(height: 2),
          Text(label,
              style: const TextStyle(
                  fontSize: 11, color: Color(0xFF6B7280))),
        ]),
      ),
    );
  }
}