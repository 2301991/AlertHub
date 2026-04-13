import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../data/app_state.dart';

class HomeScreen extends StatefulWidget {
  final void Function(int tabIndex) onNavigate;

  const HomeScreen({
    super.key,
    required this.onNavigate,
  });

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String locationStatus = 'Enabled';
  String networkStatus = 'Online';
  String consentStatus = 'Allowed';

  String advisoryTitle = 'Community Notice';
  String advisoryBody = 'Safety advisories (weather warning, barangay announcements, etc.).';

  String lastAlertText = 'No alerts yet';
  String queuedText = '0 waiting to send';

  Future<void> _refresh() async {
    await Future.delayed(const Duration(milliseconds: 300));

    if (!mounted) return;
    setState(() {
      networkStatus = isOnline ? 'Online' : 'Offline';
      queuedText = '${queueNotifier.value} waiting to send';

      if (alerts.isNotEmpty) {
        final lastAlert = alerts.last;
        lastAlertText =
            '${lastAlert.status.toUpperCase()} • ${lastAlert.time.toLocal().toString().split(".").first}';
      } else {
        lastAlertText = 'No alerts yet';
      }
    });
  }

  Future<void> _callNumber(String phoneNumber) async {
    final uri = Uri(scheme: 'tel', path: phoneNumber);
    if (!await canLaunchUrl(uri)) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Cannot place a call on this device.')),
      );
      return;
    }
    await launchUrl(uri);
  }

  @override
  Widget build(BuildContext context) {
    networkStatus = isOnline ? 'Online' : 'Offline';

    if (alerts.isNotEmpty) {
      final lastAlert = alerts.last;
      lastAlertText =
          '${lastAlert.status.toUpperCase()} • ${lastAlert.time.toLocal().toString().split(".").first}';
    } else {
      lastAlertText = 'No alerts yet';
    }

    queuedText = '${queueNotifier.value} waiting to send';

    return SafeArea(
      child: RefreshIndicator(
        onRefresh: _refresh,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            const Text(
              'Dashboard',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 12),

            const _SectionTitle(title: 'Status'),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: _StatusCard(
                    title: 'Location',
                    value: locationStatus,
                    icon: Icons.my_location,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _StatusCard(
                    title: 'Network',
                    value: networkStatus,
                    icon: Icons.wifi,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: ValueListenableBuilder<int>(
                    valueListenable: queueNotifier,
                    builder: (context, queuedCount, _) {
                      return _StatusCard(
                        title: 'Queued Alerts',
                        value: '$queuedCount',
                        icon: Icons.cloud_upload_outlined,
                      );
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _StatusCard(
                    title: 'Consent',
                    value: consentStatus,
                    icon: Icons.privacy_tip_outlined,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),

            ValueListenableBuilder<bool>(
              valueListenable: networkNotifier,
              builder: (context, online, _) {
                return Card(
                  child: SwitchListTile(
                    value: online,
                    title: const Text('Simulate Network'),
                    subtitle: Text(online ? 'Online' : 'Offline'),
                    onChanged: (v) {
                      setState(() {
                        setNetworkStatus(v);
                        networkStatus = isOnline ? 'Online' : 'Offline';
                      });

                      if (v) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Network restored. Queued alerts synced.'),
                          ),
                        );
                      }
                    },
                  ),
                );
              },
            ),

            const SizedBox(height: 18),

            const _SectionTitle(title: 'Quick Actions'),
            const SizedBox(height: 8),
            _ActionButton(
              icon: Icons.sos_outlined,
              title: 'Send Emergency Alert',
              subtitle: 'One-tap alert with last-known GPS',
              onTap: () => widget.onNavigate(1),
            ),
            const SizedBox(height: 10),
            _ActionButton(
              icon: Icons.flash_on_outlined,
              title: 'Activate Distress Mode',
              subtitle: 'Flashlight + alarm + nearby notifications',
              onTap: () => widget.onNavigate(2),
            ),
            const SizedBox(height: 10),
            _ActionButton(
              icon: Icons.history_outlined,
              title: 'View Alert History',
              subtitle: 'Queued, sent, and failed alerts',
              onTap: () => widget.onNavigate(3),
            ),

            const SizedBox(height: 18),

            const _SectionTitle(title: 'Safety Advisory'),
            const SizedBox(height: 8),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.campaign_outlined),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            advisoryTitle,
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          ),
                          const SizedBox(height: 6),
                          Text(advisoryBody),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 18),

            const _SectionTitle(title: 'Recent Activity'),
            const SizedBox(height: 8),
            Card(
              child: Column(
                children: [
                  ListTile(
                    leading: const Icon(Icons.check_circle_outline),
                    title: const Text('Last alert sent'),
                    subtitle: Text(lastAlertText),
                    onTap: () => widget.onNavigate(3),
                  ),
                  const Divider(height: 1),
                  ValueListenableBuilder<int>(
                    valueListenable: queueNotifier,
                    builder: (context, queuedCount, _) {
                      return ListTile(
                        leading: const Icon(Icons.schedule),
                        title: const Text('Queued alerts'),
                        subtitle: Text('$queuedCount waiting to send'),
                        onTap: () => widget.onNavigate(3),
                      );
                    },
                  ),
                ],
              ),
            ),

            const SizedBox(height: 18),

            const _SectionTitle(title: 'Emergency Contacts'),
            const SizedBox(height: 8),
            Card(
              child: Column(
                children: [
                  ListTile(
                    leading: const Icon(Icons.local_police_outlined),
                    title: const Text('Police / Hotline'),
                    subtitle: const Text('911'),
                    trailing: const Icon(Icons.call),
                    onTap: () => _callNumber('911'),
                  ),
                  const Divider(height: 1),
                  ListTile(
                    leading: const Icon(Icons.local_hospital_outlined),
                    title: const Text('Hospital / Ambulance'),
                    subtitle: const Text('911'),
                    trailing: const Icon(Icons.call),
                    onTap: () => _callNumber('911'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;
  const _SectionTitle({required this.title});

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
    );
  }
}

class _StatusCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;

  const _StatusCard({
    required this.title,
    required this.value,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            Icon(icon),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(fontSize: 12)),
                  const SizedBox(height: 6),
                  Text(
                    value,
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _ActionButton({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              Icon(icon, size: 28),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 4),
                    Text(subtitle),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right),
            ],
          ),
        ),
      ),
    );
  }
}