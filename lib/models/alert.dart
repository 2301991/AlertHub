class Alert {
  final String id;
  final DateTime time;
  final String type; // emergency / distress
  String status; // sent / queued / responded
  String response; // waiting / responders notified / dispatched
  String eta; // approximate time of arrival
  bool hasNotification;
  int? serverId;

  Alert({
    required this.id,
    required this.time,
    required this.type,
    required this.status,
    this.response = 'Waiting for response',
    this.eta = 'Not available yet',
    this.hasNotification = false,
    this.serverId,
  });

  Map<String, dynamic> toJson({required int userId}) {
    return {
      'user_id': userId,
      'client_id': id,
      'type': type,
      'status': status,
      'response': response,
      'eta': eta,
      'has_notification': hasNotification ? 1 : 0,
      'created_at': time.toIso8601String(),
    };
  }

  factory Alert.fromJson(Map<String, dynamic> json) {
    return Alert(
      id: (json['client_id'] ?? json['id'] ?? '').toString(),
      time: DateTime.tryParse((json['created_at'] ?? '').toString()) ?? DateTime.now(),
      type: (json['type'] ?? 'emergency').toString(),
      status: (json['status'] ?? 'queued').toString(),
      response: (json['response'] ?? 'Waiting for response').toString(),
      eta: (json['eta'] ?? 'Not available yet').toString(),
      hasNotification: (json['has_notification'].toString() == '1' || json['has_notification'] == true),
      serverId: int.tryParse((json['alert_id'] ?? '').toString()),
    );
  }
}
