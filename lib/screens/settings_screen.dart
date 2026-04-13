import 'package:flutter/material.dart';
import '../theme/theme_controller.dart';
import '../theme/app_theme.dart';

class SettingsScreen extends StatefulWidget {
  final ThemeController themeController;

  const SettingsScreen({
    super.key,
    required this.themeController,
  });

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _locationConsent = true;
  bool _manualVerification = true;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const Text(
          'Privacy & Safety',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 16),

        // 🌗 Dark Mode Toggle
        Card(
          color: AppTheme.widgetGray(context),
          shape: AppTheme.outlinedCardShape(),
          elevation: 0,
          child: SwitchListTile(
            value: widget.themeController.isDark,
            title: const Text('Dark Mode'),
            subtitle: const Text('Switch between light and dark theme'),
            onChanged: widget.themeController.toggle,
          ),
        ),

        const SizedBox(height: 16),

        // 📍 Location Consent
        Card(
          color: AppTheme.widgetGray(context),
          shape: AppTheme.outlinedCardShape(),
          elevation: 0,
          child: SwitchListTile(
            value: _locationConsent,
            title: const Text('Location Sharing Consent'),
            subtitle: const Text(
              'Allows last-known GPS to be attached to alerts.',
            ),
            onChanged: (v) => setState(() => _locationConsent = v),
          ),
        ),

        const SizedBox(height: 16),

        // ✅ Manual Verification
        Card(
          color: AppTheme.widgetGray(context),
          shape: AppTheme.outlinedCardShape(),
          elevation: 0,
          child: SwitchListTile(
            value: _manualVerification,
            title: const Text('Manual Verification Before Sending'),
            subtitle: const Text(
              'Adds a confirmation step to reduce false alarms.',
            ),
            onChanged: (v) => setState(() => _manualVerification = v),
          ),
        ),

        const SizedBox(height: 24),

        Divider(
          color: Theme.of(context).dividerColor,
        ),

        const SizedBox(height: 16),

        // 🛠 Admin Section
        Card(
          color: AppTheme.widgetGray(context),
          shape: AppTheme.outlinedCardShape(),
          elevation: 0,
          child: ListTile(
            leading: const Icon(Icons.admin_panel_settings_outlined),
            title: const Text('Admin Dashboard'),
            subtitle: const Text(
              'Admins verify and escalate alerts on the web dashboard.',
            ),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              // Future: open web dashboard
            },
          ),
        ),
      ],
    );
  }
}