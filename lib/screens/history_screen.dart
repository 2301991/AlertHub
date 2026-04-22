import 'package:flutter/material.dart';
import '../data/app_state.dart';
import 'package:url_launcher/url_launcher.dart';

class HistoryScreen extends StatelessWidget {
  HistoryScreen({super.key});

  // Method to open map using location data
  Future<void> _openMap(double latitude, double longitude) async {
    final Uri url = Uri.parse('https://www.google.com/maps?q=$latitude,$longitude');
    if (await canLaunch(url.toString())) {
      await launchUrl(url);
    } else {
      throw 'Could not open the map.';
    }
  }

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
                // Display Location
                Text(
                  'Location: (${alert.latitude}, ${alert.longitude})',
                  style: TextStyle(fontSize: 12, color: Colors.grey),
                ),
                // Optional: Add a clickable map link
                TextButton(
                  onPressed: () {
                    // Open in Google Maps when user taps the location
                    _openMap(alert.latitude, alert.longitude);
                  },
                  child: const Text('View on Map'),
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