// file: models/activity.dart

class Activity {
  final String id;
  final String userEmail;
  final String name;
  final int points;
  final DateTime timestamp;
  bool isApproved;

  Activity({
    required this.id,
    required this.userEmail,
    required this.name,
    required this.points,
    required this.timestamp,
    this.isApproved = false,
  });

  factory Activity.fromJson(Map<String, dynamic> json) {
    return Activity(
      id: json['id'],
      userEmail: json['userEmail'],
      name: json['name'],
      points: json['points'],
      timestamp: DateTime.parse(json['timestamp']),
      isApproved: json['isApproved'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userEmail': userEmail,
      'name': name,
      'points': points,
      'timestamp': timestamp.toIso8601String(),
      'isApproved': isApproved,
    };
  }
}
