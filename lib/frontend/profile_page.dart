// profile_page.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'theme.dart';
import 'theme_provider.dart';
import 'auth_screen.dart';
import '../backend/data_provider.dart';
import 'manage_categories_page.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  bool _reduceAnimations = false;
  bool _studyMode = false;
  String _selectedTheme = 'Professional';
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
        title: const Text('Profile & Settings'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildProfileHeader(context),
          const SizedBox(height: 32),
          _buildSection(
            context,
            'Personal Information',
            [
              _buildInfoTile('Name', 'Student User', Icons.person_outline),
              _buildInfoTile('Role', 'Student', Icons.school_outlined),
              _buildInfoTile('Semester', 'Spring 2026', Icons.calendar_today_outlined),
              _buildInfoTile('Institution', 'University Name', Icons.location_city_outlined),
            ],
          ),
          const SizedBox(height: 24),
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
              _buildDropdownTile(
                'Color Theme',
                _selectedTheme,
                ['Professional', 'Academic', 'Minimal'],
                (value) => setState(() => _selectedTheme = value!),
                Icons.palette_outlined,
              ),
              SwitchListTile(
                secondary: const Icon(Icons.animation),
                title: const Text('Reduce Animations'),
                subtitle: const Text('Minimize motion effects'),
                value: _reduceAnimations,
                onChanged: (value) => setState(() => _reduceAnimations = value),
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
                ['Home', 'Calendar', 'Timeline', 'Events'],
                (value) => setState(() => _defaultView = value!),
                Icons.view_compact_outlined,
              ),
              SwitchListTile(
                secondary: const Icon(Icons.school_outlined),
                title: const Text('Study Mode'),
                subtitle: const Text('Minimal interface during focus time'),
                value: _studyMode,
                onChanged: (value) => setState(() => _studyMode = value),
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
              _buildTile(
                'Export Data',
                'Backup your events',
                Icons.download_outlined,
                () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Export feature coming soon')),
                  );
                },
              ),
            ],
          ),
          const SizedBox(height: 24),
          _buildSection(
            context,
            'Notifications',
            [
              SwitchListTile(
                title: const Text('Event Reminders'),
                value: true,
                onChanged: (value) {},
              ),
              SwitchListTile(
                title: const Text('Deadline Alerts'),
                value: true,
                onChanged: (value) {},
              ),
              SwitchListTile(
                title: const Text('Voice Note Notifications'),
                value: false,
                onChanged: (value) {},
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
                'Help & Support',
                '',
                Icons.help_outline,
                () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Help & Support coming soon')),
                  );
                },
              ),
              _buildTile(
                'Privacy Policy',
                '',
                Icons.privacy_tip_outlined,
                () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Privacy Policy coming soon')),
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