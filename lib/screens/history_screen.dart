import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../data/app_state.dart';
import '../models/alert.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  Future<void> _loadHistory() async {
    setState(() {
      _loading = true;
      _error   = null;
    });

    try {
      await loadRemoteHistory();
    } catch (_) {
      if (mounted) {
        setState(() => _error = 'Could not load history from server. Showing local data.');
      }
    }

    if (mounted) setState(() => _loading = false);
  }

  Future<void> _openMap(double lat, double lng) async {
    final uri = Uri.parse('https://www.google.com/maps?q=$lat,$lng');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<List<Alert>>(
      valueListenable: alertsNotifier,
      builder: (context, alertList, _) {
        if (_loading) {
          return const Center(child: CircularProgressIndicator());
        }

        return RefreshIndicator(
          onRefresh: _loadHistory,
          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              // ── Banner: offline / error ──────────────────────────────────
              SliverToBoxAdapter(
                child: ValueListenableBuilder<bool>(
                  valueListenable: networkNotifier,
                  builder: (context, online, _) {
                    if (online && _error == null) return const SizedBox.shrink();
                    return Container(
                      margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      decoration: BoxDecoration(
                        color: online
                            ? Colors.orange.shade50
                            : Colors.red.shade50,
                        border: Border.all(
                          color: online ? Colors.orange.shade300 : Colors.red.shade300,
                        ),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            online ? Icons.info_outline : Icons.wifi_off,
                            size: 18,
                            color: online ? Colors.orange : Colors.red,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              online
                                  ? (_error ?? '')
                                  : 'You are offline. Showing local data. Pull to sync when back online.',
                              style: TextStyle(
                                fontSize: 12,
                                color: online ? Colors.orange.shade800 : Colors.red.shade800,
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),

              // ── Queue summary ────────────────────────────────────────────
              SliverToBoxAdapter(
                child: ValueListenableBuilder<int>(
                  valueListenable: queueNotifier,
                  builder: (context, count, _) {
                    if (count == 0) return const SizedBox.shrink();
                    return Container(
                      margin: const EdgeInsets.fromLTRB(16, 10, 16, 0),
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      decoration: BoxDecoration(
                        color: Colors.amber.shade50,
                        border: Border.all(color: Colors.amber.shade400),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.schedule_send, size: 18, color: Colors.amber.shade800),
                          const SizedBox(width: 8),
                          Text(
                            '$count alert${count == 1 ? '' : 's'} pending sync. Will upload when online.',
                            style: TextStyle(fontSize: 12, color: Colors.amber.shade900),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),

              // ── Empty state ──────────────────────────────────────────────
              if (alertList.isEmpty)
                const SliverFillRemaining(
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.history, size: 52, color: Colors.grey),
                        SizedBox(height: 12),
                        Text(
                          'No alerts yet',
                          style: TextStyle(fontSize: 16, color: Colors.grey),
                        ),
                        SizedBox(height: 6),
                        Text(
                          'Pull down to refresh',
                          style: TextStyle(fontSize: 12, color: Colors.grey),
                        ),
                      ],
                    ),
                  ),
                ),

              // ── Alert list ───────────────────────────────────────────────
              if (alertList.isNotEmpty)
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        final alert = alertList[index];
                        return _AlertCard(
                          alert: alert,
                          onOpenMap: () => _openMap(alert.latitude, alert.longitude),
                        );
                      },
                      childCount: alertList.length,
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}

// ─── Individual alert card ────────────────────────────────────────────────────
class _AlertCard extends StatelessWidget {
  final Alert alert;
  final VoidCallback onOpenMap;

  const _AlertCard({required this.alert, required this.onOpenMap});

  @override
  Widget build(BuildContext context) {
    final isDistress  = alert.type == 'distress';
    final isQueued    = alert.status == 'queued';
    final isSent      = alert.status == 'sent';

    final typeColor   = isDistress ? Colors.deepOrange : Colors.blue.shade700;
    final typeLabel   = isDistress ? 'DISTRESS' : 'EMERGENCY';
    final typeIcon    = isDistress ? Icons.warning_amber_rounded : Icons.sos;

    final statusColor = isQueued
        ? Colors.amber.shade700
        : isSent
            ? Colors.green.shade700
            : Colors.grey;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(
          color: isQueued ? Colors.amber.shade300 : Colors.transparent,
          width: 1.5,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Header row ──────────────────────────────────────────────
            Row(
              children: [
                Icon(typeIcon, color: typeColor, size: 20),
                const SizedBox(width: 6),
                Text(
                  typeLabel,
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    color: typeColor,
                    fontSize: 13,
                  ),
                ),
                const Spacer(),
                // Status badge
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: statusColor.withOpacity(0.4)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (isQueued) ...[
                        SizedBox(
                          width: 10,
                          height: 10,
                          child: CircularProgressIndicator(
                            strokeWidth: 1.5,
                            color: statusColor,
                          ),
                        ),
                        const SizedBox(width: 4),
                      ],
                      Text(
                        alert.status.toUpperCase(),
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: statusColor,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 10),
            const Divider(height: 1),
            const SizedBox(height: 10),

            // ── Details ─────────────────────────────────────────────────
            _Row(Icons.access_time,   _formatTime(alert.time)),
            const SizedBox(height: 4),
            _Row(Icons.reply,         alert.response),
            const SizedBox(height: 4),
            _Row(Icons.timer_outlined, 'ETA: ${alert.eta}'),
            const SizedBox(height: 4),
            _Row(
              alert.hasNotification
                  ? Icons.notifications_active
                  : Icons.notifications_off,
              alert.hasNotification
                  ? 'Response notification received'
                  : 'Awaiting response',
              iconColor: alert.hasNotification ? Colors.blue : Colors.grey,
            ),

            // ── Location ────────────────────────────────────────────────
            if (alert.latitude != 0.0 || alert.longitude != 0.0) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(Icons.location_on_outlined, size: 14, color: Colors.grey),
                  const SizedBox(width: 4),
                  Text(
                    '${alert.latitude.toStringAsFixed(5)}, ${alert.longitude.toStringAsFixed(5)}',
                    style: const TextStyle(fontSize: 11, color: Colors.grey),
                  ),
                  const Spacer(),
                  GestureDetector(
                    onTap: onOpenMap,
                    child: const Text(
                      'View on Map →',
                      style: TextStyle(
                        fontSize: 11,
                        color: Color(0xFF2563EB),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ],

            // ── Queued notice ────────────────────────────────────────────
            if (isQueued) ...[
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.amber.shade50,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(Icons.schedule_send, size: 14, color: Colors.amber.shade800),
                    const SizedBox(width: 6),
                    Text(
                      'Saved locally. Will sync when back online.',
                      style: TextStyle(fontSize: 11, color: Colors.amber.shade900),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  String _formatTime(DateTime t) {
    final local = t.toLocal();
    final hour  = local.hour.toString().padLeft(2, '0');
    final min   = local.minute.toString().padLeft(2, '0');
    return '${local.year}-${_pad(local.month)}-${_pad(local.day)}  $hour:$min';
  }

  String _pad(int v) => v.toString().padLeft(2, '0');
}

class _Row extends StatelessWidget {
  final IconData icon;
  final String   text;
  final Color?   iconColor;

  const _Row(this.icon, this.text, {this.iconColor});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 14, color: iconColor ?? Colors.grey),
        const SizedBox(width: 6),
        Expanded(
          child: Text(text, style: const TextStyle(fontSize: 12)),
        ),
      ],
    );
  }
}
