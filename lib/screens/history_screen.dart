import 'package:flutter/material.dart';

import '../data/app_state.dart';
import '../models/alert.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  bool _loading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadFromServer();
  }

  Future<void> _loadFromServer() async {
    setState(() {
      _loading = true;
      _errorMessage = null;
    });

    try {
      await fetchAlertHistory();
    } catch (e) {
      _errorMessage = e.toString();
    }

    if (!mounted) {
      return;
    }

    setState(() {
      _loading = false;
    });
  }

  Color _statusColor(String status) {
    switch (status.toLowerCase()) {
      case 'sent':
        return Colors.green;
      case 'queued':
        return Colors.orange;
      case 'responded':
        return Colors.blue;
      case 'failed':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  Widget _buildList(List<Alert> history) {
    if (history.isEmpty) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: const [
          SizedBox(height: 120),
          Center(child: Text('No alerts yet')),
        ],
      );
    }

    return ListView.builder(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(16),
      itemCount: history.length,
      itemBuilder: (context, index) {
        final Alert alert = history[index];

        return Card(
          child: ListTile(
            leading: Icon(
              alert.hasNotification
                  ? Icons.notifications_active
                  : Icons.notifications_off,
              color: alert.hasNotification ? Colors.blue : Colors.grey,
            ),
            title: Text(
              'SOS ${alert.status.toUpperCase()}',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: _statusColor(alert.status),
              ),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 6),
                Text('Time: ${alert.time.toLocal().toString().split('.').first}'),
                Text('Response: ${alert.response}'),
                Text('ETA: ${alert.eta}'),
                Text('Message: ${alert.message ?? 'SOS triggered'}'),
                if ((alert.latitude ?? '').isNotEmpty &&
                    (alert.longitude ?? '').isNotEmpty)
                  Text('Location: ${alert.latitude}, ${alert.longitude}'),
                Text(
                  alert.hasNotification
                      ? 'Notification: Response available'
                      : 'Notification: No response yet',
                ),
              ],
            ),
            isThreeLine: true,
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: _loadFromServer,
      child: ValueListenableBuilder<int>(
        valueListenable: alertsRevisionNotifier,
        builder: (context, _, __) {
          if (_loading && alerts.isEmpty) {
            return ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              children: const [
                SizedBox(height: 120),
                Center(child: CircularProgressIndicator()),
              ],
            );
          }

          if (_errorMessage != null && alerts.isEmpty) {
            return ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              children: [
                const SizedBox(height: 120),
                Center(child: Text('Failed to load history: $_errorMessage')),
              ],
            );
          }

          return _buildList(alerts);
        },
      ),
    );
  }
}
