// profile_page.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'theme.dart';
import 'theme_provider.dart';
import 'auth_screen.dart';
import '../backend/data_provider.dart';
import 'manage_categories_page.dart';
import 'privacy_policy_page.dart';
import 'otp_screen.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {

  Future<void> _handleSignOut() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Sign Out'),
        content: const Text('Are you sure you want to sign out? All local data will be cleared.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(
              backgroundColor: AppTheme.errorRed,
            ),
            child: const Text('Sign Out'),
          ),
        ],
      ),
    );

    if (confirm == true && mounted) {
      final dataProvider = Provider.of<DataProvider>(context, listen: false);
      await dataProvider.signOut();
      
      if (mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const AuthScreen()),
          (route) => false,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDarkMode = themeProvider.themeMode == ThemeMode.dark;
    final dataProvider = Provider.of<DataProvider>(context);
    
    return Scaffold(
      appBar: AppBar(
  title: Row(
    children: [
      Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: AppTheme.primaryBlue.withOpacity(0.1),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(
          Icons.person_rounded,
          color: AppTheme.primaryBlue,
          size: 22,
        ),
      ),
      const SizedBox(width: 12),
      const Text(
        'Profile & Settings',
        style: TextStyle(
          fontSize: 22,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.3,
        ),
      ),
    ],
  ),
),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildProfileHeader(context),
          const SizedBox(height: 32),
          _buildSection(
            context,
            'Appearance',
            [
              SwitchListTile(
                secondary: Icon(isDarkMode ? Icons.dark_mode : Icons.light_mode),
                title: const Text('Dark Mode'),
                subtitle: const Text('Toggle dark theme'),
                value: isDarkMode,
                onChanged: (value) {
                  themeProvider.setThemeMode(value ? ThemeMode.dark : ThemeMode.light);
                },
              ),
            ],
          ),
          const SizedBox(height: 24),
          _buildSection(
            context,
            'Data & Categories',
            [
              _buildTile(
                'Manage Categories',
                '${dataProvider.categories.length} categories',
                Icons.folder_outlined,
                () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const ManageCategoriesPage(),
                    ),
                  );
                },
              ),
            ],
          ),
          const SizedBox(height: 24),
          _buildSection(
            context,
            'Security',
            [
              _buildMfaTile(context, dataProvider),
            ],
          ),
          const SizedBox(height: 24),
          _buildSection(
            context,
            'Notifications',
            [
              SwitchListTile(
                secondary: const Icon(Icons.alarm_outlined),
                title: const Text('Event Reminders'),
                subtitle: const Text('Notify at reminder times set on each event'),
                // Reads live from DataProvider so toggle state persists across restarts
                value: dataProvider.notifyReminders,
                onChanged: (value) => dataProvider.setNotifyReminders(value),
              ),
              SwitchListTile(
                secondary: const Icon(Icons.notifications_active_outlined),
                title: const Text('Event Start Alerts'),
                subtitle: const Text('Notify when an event is beginning'),
                value: dataProvider.notifyEventStart,
                onChanged: (value) => dataProvider.setNotifyEventStart(value),
              ),
            ],
          ),
          const SizedBox(height: 24),
          _buildSection(
            context,
            'About',
            [
              _buildInfoTile('Version', '2.0.0', Icons.info_outline),
              _buildTile(
                'Privacy Policy',
                'How we handle your data',
                Icons.privacy_tip_outlined,
                () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const PrivacyPolicyPage(),
                    ),
                  );
                },
              ),
            ],
          ),
          const SizedBox(height: 24),
          SizedBox(
            height: 56,
            child: OutlinedButton.icon(
              onPressed: _handleSignOut,
              icon: const Icon(Icons.logout),
              label: const Text('Sign Out'),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppTheme.errorRed,
                side: BorderSide(color: AppTheme.errorRed),
              ),
            ),
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildMfaTile(BuildContext context, DataProvider dataProvider) {
    final isMfaEnabled = dataProvider.mfaEnabled;

    // Extracted as a local function so both the ListTile onTap and any
    // future trigger points (e.g. a dedicated button) can reuse it.
    Future<void> handleToggle() async {
      // Always show a confirmation dialog before changing MFA state —
      // accidental toggles on a security setting are especially disruptive.
      final confirm = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: Text(isMfaEnabled ? 'Disable 2FA?' : 'Enable 2FA?'),
          content: Text(
            isMfaEnabled
                ? 'Disabling two-factor authentication will make your account less secure. Are you sure?'
                : 'Enabling two-factor authentication will require a 6-digit code every time you sign in. Continue?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              style: FilledButton.styleFrom(
                backgroundColor:
                    isMfaEnabled ? AppTheme.errorRed : AppTheme.successGreen,
              ),
              child: Text(isMfaEnabled ? 'Disable' : 'Enable'),
            ),
          ],
        ),
      );

      if (confirm == true && mounted) {
        await dataProvider.setMfaEnabled(!isMfaEnabled);
        if (mounted) {
          AppTheme.showTopNotification(
            context,
            isMfaEnabled
                ? '2FA has been disabled.'
                : '2FA enabled — you\'ll need a code on next sign in.',
            type: isMfaEnabled ? NotificationType.warning : NotificationType.success,
          );
        }
      }
    }

    return ListTile(
      // onTap on the whole tile is more reliable than GestureDetector on the
      // trailing widget — trailing widgets sit inside the ListTile's internal
      // layout and don't always receive gesture events as expected.
      onTap: handleToggle,
      leading: Icon(
        Icons.verified_user_outlined,
        color: isMfaEnabled ? AppTheme.successGreen : null,
      ),
      title: const Text(
        'Two-Factor Authentication',
        style: TextStyle(fontWeight: FontWeight.w600),
      ),
      subtitle: Text(
        isMfaEnabled
            ? 'Extra login step is ON — tap to disable'
            : 'Tap to add an extra layer of security',
        style: TextStyle(
          fontSize: 12,
          color: isMfaEnabled ? AppTheme.successGreen : null,
        ),
      ),
      trailing: IgnorePointer(
        // IgnorePointer prevents the toggle visual from intercepting taps
        // that should propagate up to the ListTile's onTap. The toggle is
        // purely decorative here — all interaction goes through the tile.
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          width: 56,
          height: 30,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(15),
            color: isMfaEnabled
                ? AppTheme.successGreen
                : Colors.grey.withOpacity(0.4),
          ),
          child: Stack(
            children: [
              AnimatedPositioned(
                duration: const Duration(milliseconds: 250),
                left: isMfaEnabled ? 28 : 2,
                top: 2,
                child: Container(
                  width: 26,
                  height: 26,
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProfileHeader(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Row(
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primaryContainer,
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text(
                  'SU',
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.w700,
                    color: Theme.of(context).colorScheme.onPrimaryContainer,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 20),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Student User',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'student@university.edu',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.secondaryContainer,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      'Student',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Theme.of(context).colorScheme.onSecondaryContainer,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSection(BuildContext context, String title, List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 12),
          child: Text(
            title,
            style: Theme.of(context).textTheme.titleMedium,
          ),
        ),
        Card(
          child: Column(
            children: children,
          ),
        ),
      ],
    );
  }

  Widget _buildInfoTile(String title, String value, IconData icon) {
    return ListTile(
      leading: Icon(icon),
      title: Text(title),
      trailing: Text(
        value,
        style: Theme.of(context).textTheme.bodyMedium,
      ),
    );
  }

  Widget _buildTile(String title, String subtitle, IconData icon, VoidCallback? onTap) {
    return ListTile(
      leading: Icon(icon),
      title: Text(title),
      subtitle: subtitle.isNotEmpty ? Text(subtitle) : null,
      trailing: onTap != null ? const Icon(Icons.chevron_right) : null,
      onTap: onTap,
    );
  }

  Widget _buildDropdownTile(
    String title,
    String value,
    List<String> options,
    ValueChanged<String?> onChanged,
    IconData icon,
  ) {
    return ListTile(
      leading: Icon(icon),
      title: Text(title),
      trailing: DropdownButton<String>(
        value: value,
        underline: const SizedBox(),
        items: options.map((option) {
          return DropdownMenuItem(value: option, child: Text(option));
        }).toList(),
        onChanged: onChanged,
      ),
    );
  }
}