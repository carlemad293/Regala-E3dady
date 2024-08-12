import 'package:cloud_firestore/cloud_firestore.dart';

class Activity {
  String id;
  String userEmail;
  String userName;  // Ensure userName is included
  String name;
  int points;
  DateTime timestamp;
  bool isApproved;

  Activity({
    required this.id,
    required this.userEmail,
    required this.userName,
    required this.name,
    required this.points,
    required this.timestamp,
    this.isApproved = false,
  });

  factory Activity.fromJson(Map<String, dynamic> json) {
    return Activity(
      id: json['id'] ?? '',  // Ensure ID is handled correctly
      userEmail: json['userEmail'] ?? '',
      userName: json['userName'] ?? 'Unknown User',
      name: json['name'] ?? '',
      points: json['points'] ?? 0,
      timestamp: (json['timestamp'] as Timestamp).toDate(),
      isApproved: json['isApproved'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userEmail': userEmail,
      'userName': userName,
      'name': name,
      'points': points,
      'timestamp': Timestamp.fromDate(timestamp),
      'isApproved': isApproved,
    };
  }
}
