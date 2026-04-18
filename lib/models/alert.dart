class Alert {
  final String id;
  final DateTime time;
  String status; // sent / queued / responded / failed
  String response;
  String eta;
  bool hasNotification;
  final String? userId;
  final String? message;
  final String? latitude;
  final String? longitude;

  Alert({
    required this.id,
    required this.time,
    required this.status,
    this.response = 'Waiting for response',
    this.eta = 'Not available yet',
    this.hasNotification = false,
    this.userId,
    this.message,
    this.latitude,
    this.longitude,
  });

  factory Alert.fromJson(Map<String, dynamic> json) {
    final rawNotification = json['has_notification'] ?? json['hasNotification'] ?? 0;

    return Alert(
      id: (json['alert_id'] ?? json['id'] ?? '').toString(),
      time: DateTime.tryParse(
            (json['created_at'] ?? json['time'] ?? '').toString(),
          ) ??
          DateTime.now(),
      status: (json['status'] ?? 'sent').toString(),
      response: (json['response_message'] ?? json['response'] ?? 'Waiting for response')
          .toString(),
      eta: (json['eta'] ?? 'Not available yet').toString(),
      hasNotification: rawNotification == 1 ||
          rawNotification == '1' ||
          rawNotification == true,
      userId: json['user_id']?.toString(),
      message: json['message']?.toString(),
      latitude: json['latitude']?.toString(),
      longitude: json['longitude']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'alert_id': id,
      'user_id': userId,
      'status': status,
      'response_message': response,
      'eta': eta,
      'has_notification': hasNotification ? 1 : 0,
      'message': message,
      'latitude': latitude,
      'longitude': longitude,
      'created_at': time.toIso8601String(),
    };
  }
}
