import 'package:flutter/material.dart';
import '../data/app_state.dart';

class HistoryScreen extends StatelessWidget {
  HistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    if (alerts.isEmpty) {
      return const Center(
        child: Text('No alerts yet'),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: alerts.length,
      itemBuilder: (context, index) {
        final alert = alerts[alerts.length - 1 - index];

        return Card(
          child: ListTile(
            leading: Icon(
              alert.hasNotification
                  ? Icons.notifications_active
                  : Icons.notifications_off,
              color: alert.hasNotification ? Colors.blue : Colors.grey,
            ),
            title: Text('Alert ${alert.status.toUpperCase()}'),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Time: ${alert.time.toLocal().toString().split(".").first}'),
                Text('Response: ${alert.response}'),
                Text('ETA: ${alert.eta}'),
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
}