import 'package:flutter/material.dart';

import '../data/app_state.dart';
import '../models/alert.dart';

class AlertScreen extends StatelessWidget {
  final VoidCallback? onAlertSaved;

  AlertScreen({super.key, this.onAlertSaved});

  final bool manualVerificationEnabled = true;

  Future<void> _submitAlert(BuildContext context) async {
    if (currentUserId == null || currentUserId!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No logged in user found. Please login again.'),
        ),
      );
      return;
    }

    final Alert alert = Alert(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      userId: currentUserId,
      time: DateTime.now(),
      status: isOnline ? 'sent' : 'queued',
      response: isOnline ? 'Responders notified' : 'Waiting for network sync',
      eta: isOnline ? 'Approx. 8-15 mins' : 'ETA unavailable while offline',
      hasNotification: isOnline,
      message: 'SOS triggered from AlertHub mobile app',
      latitude: null,
      longitude: null,
    );

    addAlert(alert);

    if (isOnline) {
      try {
        final Map<String, dynamic> result = await sendAlertToServer(alert);

        if (result['status'] != 'success') {
          alert.status = 'queued';
          alert.response = 'Server unavailable. Waiting for retry';
          alert.eta = 'ETA unavailable while offline';
          alert.hasNotification = false;
          addAlert(alert);
        }
      } catch (_) {
        alert.status = 'queued';
        alert.response = 'Upload failed. Waiting for retry';
        alert.eta = 'ETA unavailable while offline';
        alert.hasNotification = false;
        addAlert(alert);
      }
    }

    if (!context.mounted) {
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          alert.status == 'sent'
              ? 'SOS sent to API and recorded in history'
              : 'SOS saved in history and queued for API retry',
        ),
      ),
    );

    onAlertSaved?.call();
  }

  Future<void> _confirmAndSend(BuildContext context) async {
    if (!manualVerificationEnabled) {
      await _submitAlert(context);
      return;
    }

    final bool? confirmed = await showModalBottomSheet<bool>(
      context: context,
      showDragHandle: true,
      builder: (ctx) {
        return Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'Confirm Emergency Alert',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 10),
              const Text(
                'Are you sure you want to send an emergency alert? This will notify responders.',
              ),
              const SizedBox(height: 14),
              ElevatedButton.icon(
                onPressed: () => Navigator.pop(ctx, true),
                icon: const Icon(Icons.sos),
                label: const Padding(
                  padding: EdgeInsets.symmetric(vertical: 12),
                  child: Text('YES, SEND ALERT'),
                ),
              ),
              const SizedBox(height: 10),
              OutlinedButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('Cancel'),
              ),
              const SizedBox(height: 8),
            ],
          ),
        );
      },
    );

    if (confirmed == true) {
      await _submitAlert(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'Emergency Alert',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 8),
          Text(
            manualVerificationEnabled
                ? 'Manual verification is ON. You will confirm before sending.'
                : 'Manual verification is OFF. Alert will send immediately.',
          ),
          const SizedBox(height: 8),
          ValueListenableBuilder<bool>(
            valueListenable: networkNotifier,
            builder: (context, online, _) {
              return Text(
                online ? 'Current Network: Online' : 'Current Network: Offline',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: online ? Colors.green : Colors.orange,
                ),
              );
            },
          ),
          const SizedBox(height: 8),
          ValueListenableBuilder<int>(
            valueListenable: queueNotifier,
            builder: (context, queuedCount, _) {
              return Text(
                'Queued Alerts: $queuedCount',
                style: const TextStyle(fontWeight: FontWeight.w600),
              );
            },
          ),
          const Spacer(),
          ElevatedButton.icon(
            onPressed: () => _confirmAndSend(context),
            icon: const Icon(Icons.sos_outlined),
            label: const Padding(
              padding: EdgeInsets.symmetric(vertical: 14),
              child: Text('SEND EMERGENCY ALERT'),
            ),
          ),
          const SizedBox(height: 10),
          TextButton(
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Tip: Change verification option in Settings'),
                ),
              );
            },
            child: const Text('Change verification option in Settings'),
          ),
        ],
      ),
    );
  }
}
