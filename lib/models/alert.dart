class Alert {
  final String id;
  final DateTime time;
  final String type;  // 'emergency' or 'distress'
  String status;
  String response;
  String eta;
  bool hasNotification;
  double latitude;
  double longitude;
  int? serverId; // Add serverId here

  Alert({
    required this.id,
    required this.time,
    required this.type,
    required this.status,
    this.response = 'Waiting for response',
    this.eta = 'Not available yet',
    this.hasNotification = false,
    required this.latitude,
    required this.longitude,
    this.serverId, // Add serverId here
  });

  Map<String, dynamic> toJson({required int userId}) {
    return {
      'user_id': userId,
      'type': type,
      'status': status,
      'response': response,
      'eta': eta,
      'has_notification': hasNotification ? 1 : 0,
      'latitude': latitude,
      'longitude': longitude,
    };
  }

  static Alert fromJson(Map<String, dynamic> json) {
    return Alert(
      id: json['alert_id'].toString(),
      time: DateTime.parse(json['created_at']),
      type: json['type'],
      status: json['status'],
      response: json['response'],
      eta: json['eta'],
      hasNotification: json['has_notification'] == 1,
      latitude: json['latitude'] ?? 0.0,
      longitude: json['longitude'] ?? 0.0,
      serverId: json['alert_id'],  // Assign serverId from backend response
    );
  }
}