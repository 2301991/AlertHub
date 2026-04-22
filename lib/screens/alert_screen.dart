import 'package:flutter/material.dart';
import '../data/app_state.dart';

class AlertScreen extends StatelessWidget {
  AlertScreen({super.key});

  final bool manualVerificationEnabled = true;

  Future<void> _submitAlert(BuildContext context) async {
    await sendEmergencyAlert();

    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          isOnline
              ? 'Emergency alert sent and saved'
              : 'No signal. Alert queued and will sync once network returns',
        ),
      ),
    );
  }

  Future<void> _confirmAndSend(BuildContext context) async {
    if (!manualVerificationEnabled) {
      await _submitAlert(context);
      return;
    }

    final confirmed = await showModalBottomSheet<bool>(
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
        ],
      ),
    );
  }
}