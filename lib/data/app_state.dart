import 'package:flutter/material.dart';
import '../models/alert.dart';

List<Alert> alerts = [];

ValueNotifier<bool> networkNotifier = ValueNotifier<bool>(true);
ValueNotifier<int> queueNotifier = ValueNotifier<int>(0);

bool get isOnline => networkNotifier.value;

void _updateQueueCount() {
  queueNotifier.value = alerts.where((a) => a.status == 'queued').length;
}

void setNetworkStatus(bool value) {
  final wasOffline = !networkNotifier.value && value;
  networkNotifier.value = value;

  if (wasOffline) {
    syncQueuedAlerts();
  }

  _updateQueueCount();
}

void addAlert(Alert alert) {
  alerts.add(alert);
  _updateQueueCount();
}

void syncQueuedAlerts() {
  for (final alert in alerts) {
    if (alert.status == 'queued') {
      alert.status = 'sent';
      alert.response = 'Responders notified after reconnect';
      alert.eta = 'Approx. 8-15 mins';
      alert.hasNotification = true;
    }
  }
  _updateQueueCount();
}