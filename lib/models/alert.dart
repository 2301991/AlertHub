class Alert {
  final String id;
  final DateTime time;
  String status; // sent / queued / responded
  String response; // waiting / responders notified / dispatched
  String eta; // approximate time of arrival
  bool hasNotification;

  Alert({
    required this.id,
    required this.time,
    required this.status,
    this.response = 'Waiting for response',
    this.eta = 'Not available yet',
    this.hasNotification = false,
  });
}