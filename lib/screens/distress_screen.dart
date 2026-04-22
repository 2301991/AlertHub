import 'package:flutter/material.dart';

import '../data/app_state.dart';

class DistressScreen extends StatefulWidget {
  const DistressScreen({super.key});

  @override
  State<DistressScreen> createState() => _DistressScreenState();
}

class _DistressScreenState extends State<DistressScreen> {
  bool _armed = false;

  @override
  void dispose() {
    super.dispose();
  }

  Future<void> _manualSignal() async {
    await sendDistressSignal();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          isOnline
              ? 'Distress signal sent and saved'
              : 'No signal. Distress queued and will sync when back online',
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'Distress Mode',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 12),
          const Text(
            'Long press to activate repeated distress signals.',
          ),
          const SizedBox(height: 18),
          Card(
            child: SwitchListTile(
              value: _armed,
              title: const Text('Enable Distress Mode'),
              subtitle: Text(_armed ? 'DISTRESS ACTIVE' : 'Distress Inactive'),
              onChanged: (v) {
                setState(() => _armed = v);
                if (!v) {
                  stopDistressLoop();
                }
              },
            ),
          ),
          const SizedBox(height: 12),
          ValueListenableBuilder<bool>(
            valueListenable: networkNotifier,
            builder: (_, online, __) => Text(
              online ? 'Network: Online' : 'Network: Offline',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: online ? Colors.green : Colors.orange,
              ),
            ),
          ),
          const SizedBox(height: 8),
          ValueListenableBuilder<DateTime?>(
            valueListenable: lastDistressTimeNotifier,
            builder: (_, lastTime, __) => Text(
              lastTime == null
                  ? 'Last signal: No signals yet'
                  : 'Last signal: ${lastTime.toLocal().toString().split('.').first}',
            ),
          ),
          const SizedBox(height: 8),
          ValueListenableBuilder<int>(
            valueListenable: queueNotifier,
            builder: (_, queuedCount, __) => Text(
              'Queued signals: $queuedCount',
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
          const SizedBox(height: 8),
          ValueListenableBuilder<String>(
            valueListenable: responderStatusNotifier,
            builder: (_, status, __) => Text('Responder simulation: $status'),
          ),
          const SizedBox(height: 12),
          GestureDetector(
            onLongPress: !_armed
                ? null
                : () {
                    startDistressLoop();
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('DISTRESS ACTIVATED')),
                    );
                  },
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 16),
              decoration: BoxDecoration(
                color: _armed ? Colors.red : Colors.grey,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Center(
                child: Text(
                  _armed ? 'HOLD TO ACTIVATE DISTRESS' : 'ENABLE DISTRESS FIRST',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          ElevatedButton(
            onPressed: _armed ? _manualSignal : null,
            child: const Text('Send Single Distress Signal Now'),
          ),
          const SizedBox(height: 8),
          OutlinedButton(
            onPressed: distressActiveNotifier.value ? stopDistressLoop : null,
            child: const Text('Stop Distress Loop'),
          ),
        ],
      ),
    );
  }
}
