import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:geolocator/geolocator.dart'; // Correct geolocator import

import '../models/alert.dart';

const String apiBaseUrl = 'https://webhoster3b.com/alerthub/api';

List<Alert> alerts = [];

ValueNotifier<bool> networkNotifier = ValueNotifier<bool>(true);
ValueNotifier<int> queueNotifier = ValueNotifier<int>(0);
ValueNotifier<bool> distressActiveNotifier = ValueNotifier<bool>(false);
ValueNotifier<DateTime?> lastDistressTimeNotifier = ValueNotifier<DateTime?>(null);
ValueNotifier<String> responderStatusNotifier = ValueNotifier<String>('No distress signal yet');

bool get isOnline => networkNotifier.value;

int? currentUserId;
String? currentUserName;
String? currentUserEmail;

Timer? _distressTimer;
bool _syncInProgress = false;

Position? currentLocation; // Variable to store current location

// Fetch the current location using geolocator
Future<void> getCurrentLocation() async {
  bool serviceEnabled;
  LocationPermission permission;

  // Check if location services are enabled
  serviceEnabled = await Geolocator.isLocationServiceEnabled();
  if (!serviceEnabled) {
    return Future.error('Location services are disabled.');
  }

  // Check for location permissions
  permission = await Geolocator.checkPermission();
  if (permission == LocationPermission.denied) {
    permission = await Geolocator.requestPermission();
    if (permission == LocationPermission.denied) {
      return Future.error('Location permissions are denied.');
    }
  }

  if (permission == LocationPermission.deniedForever) {
    return Future.error('Location permissions are permanently denied.');
  }

  // Get current location
  currentLocation = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
  print('Current Location: ${currentLocation!.latitude}, ${currentLocation!.longitude}');
}

void setLoggedInUser({
  required int userId,
  required String name,
  required String email,
}) {
  currentUserId = userId;
  currentUserName = name;
  currentUserEmail = email;
}

void clearLoggedInUser() {
  currentUserId = null;
  currentUserName = null;
  currentUserEmail = null;
  stopDistressLoop();
  alerts.clear();
  _updateQueueCount();
}

void _updateQueueCount() {
  queueNotifier.value = alerts.where((a) => a.status == 'queued').length;
}

void setNetworkStatus(bool value) {
  final wasOffline = !networkNotifier.value && value;
  networkNotifier.value = value;

  if (wasOffline) {
    unawaited(syncQueuedAlerts());
  }

  _updateQueueCount();
}

void addAlert(Alert alert) {
  alerts.add(alert);
  _updateQueueCount();
}

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
      alert.serverId = int.tryParse((data['alert_id'] ?? '').toString()); // Assign serverId
      return true;
    }
  } catch (_) {
    return false;
  }

  return false;
}

Future<void> sendEmergencyAlert() async {
  await getCurrentLocation(); // Ensure we have the current location

  final alert = Alert(
    id: DateTime.now().millisecondsSinceEpoch.toString(),
    time: DateTime.now(),
    type: 'emergency',
    status: isOnline ? 'sent' : 'queued',
    response: isOnline ? 'Responders notified' : 'Waiting for network sync',
    eta: isOnline ? 'Approx. 8-15 mins' : 'ETA unavailable while offline',
    hasNotification: isOnline,
    latitude: currentLocation?.latitude ?? 0.0,   // Use the current latitude
    longitude: currentLocation?.longitude ?? 0.0, // Use the current longitude
  );

  addAlert(alert);

  if (isOnline) {
    final ok = await saveAlertToApi(alert);
    if (!ok) {
      alert.status = 'queued';
      alert.response = 'API unavailable. Waiting for retry';
      alert.eta = 'ETA unavailable while offline';
      alert.hasNotification = false;
      _updateQueueCount();
    }
  }
}

Future<void> sendDistressSignal() async {
  await getCurrentLocation(); // Ensure we have the current location

  final alert = Alert(
    id: DateTime.now().millisecondsSinceEpoch.toString(),
    time: DateTime.now(),
    type: 'distress',
    status: isOnline ? 'sent' : 'queued',
    response: isOnline ? 'Distress signal received' : 'Waiting for network sync',
    eta: isOnline ? 'Responders tracking signal' : 'ETA unavailable while offline',
    hasNotification: isOnline,
    latitude: currentLocation?.latitude ?? 0.0,   // Use the current latitude
    longitude: currentLocation?.longitude ?? 0.0, // Use the current longitude
  );

  addAlert(alert);
  lastDistressTimeNotifier.value = alert.time;
  responderStatusNotifier.value = isOnline
      ? 'Repeated distress signal sent to responders'
      : 'Signal queued locally. Will sync when online';

  if (isOnline) {
    final ok = await saveAlertToApi(alert);
    if (!ok) {
      alert.status = 'queued';
      alert.response = 'API unavailable. Distress signal queued';
      alert.eta = 'ETA unavailable while offline';
      alert.hasNotification = false;
      responderStatusNotifier.value = 'API unavailable. Distress queued';
      _updateQueueCount();
    }
  }
}

void startDistressLoop() {
  if (distressActiveNotifier.value) return;

  distressActiveNotifier.value = true;
  responderStatusNotifier.value = isOnline
      ? 'Distress mode active. Sending repeated signals'
      : 'Distress mode active offline. Signals will queue';

  unawaited(sendDistressSignal());

  _distressTimer = Timer.periodic(const Duration(seconds: 12), (_) {
    unawaited(sendDistressSignal());
  });
}

void stopDistressLoop() {
  distressActiveNotifier.value = false;
  _distressTimer?.cancel();
  _distressTimer = null;
  responderStatusNotifier.value = 'Distress mode stopped';
}

Future<void> syncQueuedAlerts() async {
  if (_syncInProgress || currentUserId == null) return;
  _syncInProgress = true;

  try {
    for (final alert in alerts) {
      if (alert.status == 'queued') {
        final ok = await saveAlertToApi(alert);
        if (ok) {
          alert.status = 'sent';
          alert.response = alert.type == 'distress'
              ? 'Queued distress synced to responders'
              : 'Queued alert synced to responders';
          alert.eta = alert.type == 'distress'
              ? 'Responders tracking signal'
              : 'Approx. 8-15 mins';
          alert.hasNotification = true;
        }
      }
    }
  } finally {
    _syncInProgress = false;
    _updateQueueCount();
  }
}

Future<List<Alert>> fetchRemoteHistory() async {
  if (currentUserId == null) return <Alert>[];

  final uri = Uri.parse('$apiBaseUrl/get_alert_history.php?user_id=$currentUserId');
  final response = await http.get(uri);
  final data = jsonDecode(response.body);

  if (response.statusCode == 200 && data['status'] == 'success') {
    final List items = data['alerts'] as List? ?? [];
    return items.map((e) => Alert.fromJson(e as Map<String, dynamic>)).toList();
  }

  return <Alert>[];
}