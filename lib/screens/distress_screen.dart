import 'package:flutter/material.dart';

class DistressScreen extends StatefulWidget {
  const DistressScreen({super.key});

  @override
  State<DistressScreen> createState() => _DistressScreenState();
}

class _DistressScreenState extends State<DistressScreen> {
  bool _active = false;

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
            'Activates flashlight, sound alarm, and triggers nearby notifications.',
          ),
          const SizedBox(height: 18),
          Card(
            child: SwitchListTile(
              value: _active,
              title: const Text('Enable Distress Mode'),
              subtitle: Text(_active ? 'Distress Active' : 'Distress Inactive'),
              onChanged: (v) {
                setState(() => _active = v);
              },
            ),
          ),
          const SizedBox(height: 12),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Text(
                _active
                    ? 'Prototype mode: Distress feature is active. Flashlight, alarm, and nearby responder notification are for next integration phase.'
                    : 'Turn on Distress Mode to simulate emergency activation.',
              ),
            ),
          ),
          const SizedBox(height: 12),
          ElevatedButton(
            onPressed: _active
                ? () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Prototype: Nearby responders would be notified here'),
                      ),
                    );
                  }
                : null,
            child: const Text('Notify Nearby Now'),
          ),
        ],
      ),
    );
  }
}