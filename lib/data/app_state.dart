import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:geolocator/geolocator.dart';

import '../models/alert.dart';

const String apiBaseUrl = 'https://webhoster3b.com/alerthub/api';

// ─── Reactive state ───────────────────────────────────────────────────────────
ValueNotifier<List<Alert>> alertsNotifier = ValueNotifier<List<Alert>>([]);
List<Alert> get alerts => alertsNotifier.value;

ValueNotifier<bool>      networkNotifier          = ValueNotifier<bool>(true);
ValueNotifier<int>       queueNotifier            = ValueNotifier<int>(0);
ValueNotifier<bool>      distressActiveNotifier   = ValueNotifier<bool>(false);
ValueNotifier<DateTime?> lastDistressTimeNotifier = ValueNotifier<DateTime?>(null);
ValueNotifier<String>    responderStatusNotifier  = ValueNotifier<String>('No distress signal yet');

bool get isOnline => networkNotifier.value;

// ─── Current user ─────────────────────────────────────────────────────────────
int?    currentUserId;
String? currentUserName;
String? currentUserEmail;

// ─── Internal state ───────────────────────────────────────────────────────────
Timer?    _distressTimer;
bool      _syncInProgress = false;
Position? currentLocation;

// ─── Location ─────────────────────────────────────────────────────────────────
/// Tries to get the device location.
/// Wrapped in a broad try/catch so a missing AndroidManifest permission entry,
/// a denied permission, or any platform exception simply leaves
/// [currentLocation] as null — the app never crashes.
Future<void> getCurrentLocation() async {
  try {
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return;

    LocationPermission permission = await Geolocator.checkPermission();

    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) return;
    }

    if (permission == LocationPermission.deniedForever) return;

    currentLocation = await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );
  } catch (_) {
    // Covers PermissionDefinitionsNotFoundException and any other
    // platform exception. Alert still sends with 0.0 coordinates.
    currentLocation = null;
  }
}

// ─── User session ─────────────────────────────────────────────────────────────
void setLoggedInUser({
  required int    userId,
  required String name,
  required String email,
}) {
  currentUserId    = userId;
  currentUserName  = name;
  currentUserEmail = email;
}

void clearLoggedInUser() {
  currentUserId    = null;
  currentUserName  = null;
  currentUserEmail = null;
  stopDistressLoop();
  alertsNotifier.value = [];
  _updateQueueCount();
}

// ─── Alert list helpers ───────────────────────────────────────────────────────
void _updateQueueCount() {
  queueNotifier.value = alerts.where((a) => a.status == 'queued').length;
}

void _addAlert(Alert alert) {
  alertsNotifier.value = [alert, ...alerts];
  _updateQueueCount();
}

void _mergeRemoteAlerts(List<Alert> remote) {
  final localServerIds = alerts
      .where((a) => a.serverId != null)
      .map((a) => a.serverId!)
      .toSet();

  final newRemote =
      remote.where((r) => !localServerIds.contains(r.serverId)).toList();

  if (newRemote.isNotEmpty) {
    alertsNotifier.value = [...alerts, ...newRemote];
    _updateQueueCount();
  }
}

// ─── Network ──────────────────────────────────────────────────────────────────
void setNetworkStatus(bool value) {
  final cameOnline = !networkNotifier.value && value;
  networkNotifier.value = value;
  if (cameOnline) unawaited(syncQueuedAlerts());
  _updateQueueCount();
}

// ─── API: save one alert ──────────────────────────────────────────────────────
Future<bool> saveAlertToApi(Alert alert) async {
  if (currentUserId == null) return false;

  final uri = Uri.parse('$apiBaseUrl/save_alert.php');

  try {
    final response = await http.post(
      uri,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(alert.toJson(userId: currentUserId!)),
    );

    final data = jsonDecode(response.body);
    if (response.statusCode == 200 && data['status'] == 'success') {
      alert.serverId = int.tryParse((data['alert_id'] ?? '').toString());
      return true;
    }
  } catch (_) {
    // Network error — caller handles fallback.
  }

  return false;
}

// ─── Send emergency alert ─────────────────────────────────────────────────────
/// Returns the created [Alert] so the caller can show snackbar feedback using
/// its own BuildContext. We never reference BuildContext here.
Future<Alert> sendEmergencyAlert() async {
  await getCurrentLocation(); // safe — never throws

  final alert = Alert(
    id:              DateTime.now().millisecondsSinceEpoch.toString(),
    time:            DateTime.now(),
    type:            'emergency',
    status:          isOnline ? 'sent' : 'queued',
    response:        isOnline ? 'Responders notified' : 'Waiting for network sync',
    eta:             isOnline ? 'Approx. 8–15 mins' : 'ETA unavailable while offline',
    hasNotification: isOnline,
    latitude:        currentLocation?.latitude  ?? 0.0,
    longitude:       currentLocation?.longitude ?? 0.0,
  );

  _addAlert(alert);

  if (isOnline) {
    final success = await saveAlertToApi(alert);
    if (!success) {
      alert.status          = 'queued';
      alert.response        = 'Failed to send. Queued for sync';
      alert.eta             = 'ETA unavailable';
      alert.hasNotification = false;
      alertsNotifier.notifyListeners();
      _updateQueueCount();
    }
  }

  return alert;
}

// ─── Distress signal ──────────────────────────────────────────────────────────
Future<void> sendDistressSignal() async {
  await getCurrentLocation(); // safe — never throws

  final alert = Alert(
    id:              DateTime.now().millisecondsSinceEpoch.toString(),
    time:            DateTime.now(),
    type:            'distress',
    status:          isOnline ? 'sent' : 'queued',
    response:        isOnline ? 'Distress signal received' : 'Waiting for network sync',
    eta:             isOnline ? 'Responders tracking signal' : 'ETA unavailable while offline',
    hasNotification: isOnline,
    latitude:        currentLocation?.latitude  ?? 0.0,
    longitude:       currentLocation?.longitude ?? 0.0,
  );

  _addAlert(alert);
  lastDistressTimeNotifier.value = alert.time;
  responderStatusNotifier.value  = isOnline
      ? 'Repeated distress signal sent to responders'
      : 'Signal queued locally. Will sync when online';

  if (isOnline) {
    final ok = await saveAlertToApi(alert);
    if (!ok) {
      alert.status          = 'queued';
      alert.response        = 'API unavailable. Distress signal queued';
      alert.eta             = 'ETA unavailable while offline';
      alert.hasNotification = false;
      responderStatusNotifier.value = 'API unavailable. Distress queued';
      alertsNotifier.notifyListeners();
      _updateQueueCount();
    }
  }
}

void startDistressLoop() {
  if (distressActiveNotifier.value) return;

  distressActiveNotifier.value  = true;
  responderStatusNotifier.value = isOnline
      ? 'Distress mode active. Sending repeated signals'
      : 'Distress mode active offline. Signals will queue';

  unawaited(sendDistressSignal());

  _distressTimer = Timer.periodic(const Duration(seconds: 12), (_) {
    unawaited(sendDistressSignal());
  });
}

void stopDistressLoop() {
  distressActiveNotifier.value  = false;
  _distressTimer?.cancel();
  _distressTimer                = null;
  responderStatusNotifier.value = 'Distress mode stopped';
}

// ─── Sync queued alerts ───────────────────────────────────────────────────────
Future<void> syncQueuedAlerts() async {
  if (_syncInProgress || currentUserId == null) return;
  _syncInProgress = true;

  try {
    bool anyChanged = false;
    for (final alert in alerts) {
      if (alert.status == 'queued') {
        final ok = await saveAlertToApi(alert);
        if (ok) {
          alert.status          = 'sent';
          alert.response        = alert.type == 'distress'
              ? 'Queued distress synced to responders'
              : 'Queued alert synced to responders';
          alert.eta             = alert.type == 'distress'
              ? 'Responders tracking signal'
              : 'Approx. 8–15 mins';
          alert.hasNotification = true;
          anyChanged            = true;
        }
      }
    }
    if (anyChanged) alertsNotifier.notifyListeners();
  } finally {
    _syncInProgress = false;
    _updateQueueCount();
  }
}

// ─── Fetch history from DB ────────────────────────────────────────────────────
Future<void> loadRemoteHistory() async {
  if (currentUserId == null) return;

  final uri = Uri.parse(
    '$apiBaseUrl/get_alert_history.php?user_id=$currentUserId',
  );

  try {
    final response = await http.get(uri);
    final data     = jsonDecode(response.body);

    if (response.statusCode == 200 && data['status'] == 'success') {
      final List items = data['alerts'] as List? ?? [];
      final remote = items
          .map((e) => Alert.fromJson(e as Map<String, dynamic>))
          .toList();

      remote.sort((a, b) => b.time.compareTo(a.time));
      _mergeRemoteAlerts(remote);
    }
  } catch (_) {
    // Silently fail — local queue is still shown.
  }
}