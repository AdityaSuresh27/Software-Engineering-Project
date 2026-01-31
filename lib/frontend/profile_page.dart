import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'theme.dart';
import 'theme_provider.dart';
import 'auth_screen.dart';
import '../backend/data_provider.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  bool _reduceAnimations = false;
  bool _studyMode = false;
  String _selectedTheme = 'Focus';
  String _defaultView = 'Home';

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
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Sign Out', style: TextStyle(color: Colors.red)),
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
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile & Settings'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildProfileHeader(context),
          const SizedBox(height: 32),
          _buildSection(
            context,
            'Personal',
            [
              _buildInfoTile('Name', 'Student User', Icons.person_outline_rounded),
              _buildInfoTile('Role', 'Student', Icons.school_rounded),
              _buildInfoTile('Semester', 'Spring 2026', Icons.calendar_today_rounded),
              _buildInfoTile('Institution', 'University Name', Icons.location_city_rounded),
            ],
          ),
          const SizedBox(height: 24),
          _buildSection(
            context,
            'Display',
            [
              _buildSwitchTile(
                'Dark Mode',
                'Toggle dark theme',
                Icons.dark_mode_rounded,
                isDarkMode,
                (value) {
                  themeProvider.setThemeMode(value ? ThemeMode.dark : ThemeMode.light);
                },
              ),
              _buildDropdownTile(
                'Accent Theme',
                _selectedTheme,
                ['Focus', 'Clarity', 'Momentum', 'Midnight', 'Exam Mode'],
                (value) => setState(() => _selectedTheme = value!),
                Icons.palette_rounded,
              ),
              _buildSwitchTile(
                'Reduce Animations',
                'Minimize motion effects',
                Icons.animation,
                _reduceAnimations,
                (value) => setState(() => _reduceAnimations = value),
              ),
            ],
          ),
          const SizedBox(height: 24),
          _buildSection(
            context,
            'Workflow',
            [
              _buildDropdownTile(
                'Default View',
                _defaultView,
                ['Home', 'Calendar', 'Timeline', 'Tasks'],
                (value) => setState(() => _defaultView = value!),
                Icons.view_compact_rounded,
              ),
              _buildSwitchTile(
                'Study Mode UI',
                'Minimal interface during stress periods',
                Icons.spa_rounded,
                _studyMode,
                (value) => setState(() => _studyMode = value),
              ),
            ],
          ),
          const SizedBox(height: 24),
          _buildSection(
            context,
            'Notifications',
            [
              _buildNotificationTile('Deadlines', true),
              _buildNotificationTile('Class Reminders', true),
              _buildNotificationTile('New Notes', false),
              _buildNotificationTile('Voice Notes', true),
            ],
          ),
          const SizedBox(height: 24),
          _buildSection(
            context,
            'About',
            [
              _buildTile(
                'Version',
                '1.0.0',
                Icons.info_outline_rounded,
                null,
              ),
              _buildTile(
                'Help & Support',
                '',
                Icons.help_outline_rounded,
                () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Help & Support coming soon!')),
                  );
                },
              ),
              _buildTile(
                'Privacy Policy',
                '',
                Icons.privacy_tip_outlined,
                () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Privacy Policy coming soon!')),
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
              icon: const Icon(Icons.logout_rounded),
              label: const Text('Sign Out'),
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.red,
                side: const BorderSide(color: Colors.red),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
            ),
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildProfileHeader(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppTheme.accentFocus, AppTheme.accentClarity],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppTheme.accentFocus.withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: const Center(
              child: Text(
                'SU',
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.accentFocus,
                ),
              ),
            ),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Student User',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'student@university.edu',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Text(
                    'Student',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
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
            style: Theme.of(context).textTheme.titleLarge,
          ),
        ),
        Container(
          decoration: BoxDecoration(
            color: Theme.of(context).cardTheme.color,
            borderRadius: BorderRadius.circular(16),
          ),
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
      trailing: onTap != null ? const Icon(Icons.chevron_right_rounded) : null,
      onTap: onTap,
    );
  }

  Widget _buildSwitchTile(
    String title,
    String subtitle,
    IconData icon,
    bool value,
    ValueChanged<bool> onChanged,
  ) {
    return SwitchListTile(
      secondary: Icon(icon),
      title: Text(title),
      subtitle: Text(subtitle, style: Theme.of(context).textTheme.bodyMedium),
      value: value,
      onChanged: onChanged,
      activeColor: AppTheme.accentFocus,
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

  Widget _buildNotificationTile(String title, bool enabled) {
    return SwitchListTile(
      title: Text(title),
      value: enabled,
      onChanged: (value) {},
      activeColor: AppTheme.accentFocus,
    );
  }
}