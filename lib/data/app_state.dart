import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '../models/alert.dart';

List<Alert> alerts = [];

final ValueNotifier<bool> networkNotifier = ValueNotifier<bool>(true);
final ValueNotifier<int> queueNotifier = ValueNotifier<int>(0);
final ValueNotifier<int> alertsRevisionNotifier = ValueNotifier<int>(0);
final ValueNotifier<String?> currentUserIdNotifier = ValueNotifier<String?>(null);
final ValueNotifier<String?> currentUserNameNotifier = ValueNotifier<String?>(null);
final ValueNotifier<String?> currentUserEmailNotifier = ValueNotifier<String?>(null);

const String apiBaseUrl = 'https://webhoster3b.com/alerthub/api';

bool get isOnline => networkNotifier.value;
String? get currentUserId => currentUserIdNotifier.value;
String? get currentUserName => currentUserNameNotifier.value;
String? get currentUserEmail => currentUserEmailNotifier.value;

void _touchAlerts() {
  alertsRevisionNotifier.value++;
}

void _updateQueueCount() {
  queueNotifier.value = alerts.where((a) => a.status == 'queued').length;
}

void _sortAlertsNewestFirst() {
  alerts.sort((a, b) => b.time.compareTo(a.time));
}

void setLoggedInUser({
  required String userId,
  required String name,
  required String email,
}) {
  currentUserIdNotifier.value = userId;
  currentUserNameNotifier.value = name;
  currentUserEmailNotifier.value = email;
}

void clearLoggedInUser() {
  currentUserIdNotifier.value = null;
  currentUserNameNotifier.value = null;
  currentUserEmailNotifier.value = null;
  alerts = [];
  _updateQueueCount();
  _touchAlerts();
}

void setNetworkStatus(bool value) {
  final bool wasOffline = !networkNotifier.value && value;
  networkNotifier.value = value;

  if (wasOffline) {
    syncQueuedAlerts();
  }

  _updateQueueCount();
}

void addAlert(Alert alert) {
  final int existingIndex = alerts.indexWhere((a) => a.id == alert.id);
  if (existingIndex >= 0) {
    alerts[existingIndex] = alert;
  } else {
    alerts.add(alert);
  }

  _sortAlertsNewestFirst();
  _updateQueueCount();
  _touchAlerts();
}

void replaceAlerts(List<Alert> newAlerts) {
  alerts = List<Alert>.from(newAlerts);
  _sortAlertsNewestFirst();
  _updateQueueCount();
  _touchAlerts();
}

Future<Map<String, dynamic>> sendAlertToServer(Alert alert) async {
  final response = await http.post(
    Uri.parse('$apiBaseUrl/save_alert.php'),
    headers: {'Content-Type': 'application/json'},
    body: jsonEncode(alert.toJson()),
  );

  final Map<String, dynamic> data = jsonDecode(response.body) as Map<String, dynamic>;

  if (response.statusCode != 200) {
    throw Exception(data['message'] ?? 'Failed to send alert');
  }

  return data;
}

Future<List<Alert>> fetchAlertHistory() async {
  if (currentUserId == null || currentUserId!.isEmpty) {
    replaceAlerts([]);
    return alerts;
  }

  final response = await http.post(
    Uri.parse('$apiBaseUrl/get_alert_history.php'),
    headers: {'Content-Type': 'application/json'},
    body: jsonEncode({'user_id': currentUserId}),
  );

  final Map<String, dynamic> data = jsonDecode(response.body) as Map<String, dynamic>;

  if (response.statusCode != 200 || data['status'] != 'success') {
    throw Exception(data['message'] ?? 'Failed to load history');
  }

  final List<dynamic> rows = (data['alerts'] ?? []) as List<dynamic>;
  replaceAlerts(
    rows.map((row) => Alert.fromJson(row as Map<String, dynamic>)).toList(),
  );

  return alerts;
}

Future<void> syncQueuedAlerts() async {
  final List<Alert> queuedAlerts = alerts.where((a) => a.status == 'queued').toList();

  for (final alert in queuedAlerts) {
    try {
      final result = await sendAlertToServer(alert);

      if (result['status'] == 'success') {
        alert.status = 'sent';
        alert.response = 'Responders notified after reconnect';
        alert.eta = 'Approx. 8-15 mins';
        alert.hasNotification = true;
      }
    } catch (_) {
      // Leave it queued for the next retry.
    }
  }

  _sortAlertsNewestFirst();
  _updateQueueCount();
  _touchAlerts();
}
