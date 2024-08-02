import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'models/activity.dart';

class AdminPage extends StatefulWidget {
  final List<Activity> pendingRequests;

  AdminPage({required this.pendingRequests});

  @override
  _AdminPageState createState() => _AdminPageState();
}

class _AdminPageState extends State<AdminPage> {
  List<Activity> _pendingRequests = [];

  @override
  void initState() {
    super.initState();
    _pendingRequests = widget.pendingRequests;
    _pendingRequests.sort((a, b) => b.timestamp.compareTo(a.timestamp));
  }

  Future<void> _savePendingRequests() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final requestsJson = jsonEncode(_pendingRequests.map((item) => item.toJson()).toList());
      await prefs.setString('pendingRequests', requestsJson);
    } catch (e) {
      print('Failed to save pending requests: $e');
    }
  }

  Future<void> _updateUserPoints(Activity activity) async {
    try {
      final userDoc = FirebaseFirestore.instance.collection('users').doc(activity.userEmail);
      final doc = await userDoc.get();
      if (doc.exists) {
        final data = doc.data() as Map<String, dynamic>;
        final currentPoints = data['points'] as int? ?? 0;

        await userDoc.set({
          'points': currentPoints + activity.points,
        }, SetOptions(merge: true));
      }
    } catch (e) {
      print('Failed to update points: $e');
    }
  }

  Future<void> _confirmActivity(Activity activity) async {
    try {
      setState(() {
        _pendingRequests.remove(activity);
      });
      activity.isApproved = true;
      await _savePendingRequests();
      await _updateUserPoints(activity);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Points successfully added for activity: ${activity.name}')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to approve activity: $e')),
      );
    }
  }

  Future<void> _denyActivity(Activity activity) async {
    try {
      setState(() {
        _pendingRequests.remove(activity);
      });
      await _savePendingRequests();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Activity denied: ${activity.name}')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to deny activity: $e')),
      );
    }
  }

  Future<void> _approveAll() async {
    for (var activity in List.from(_pendingRequests)) {
      await _confirmActivity(activity);
    }
  }

  Future<void> _denyAll() async {
    for (var activity in List.from(_pendingRequests)) {
      await _denyActivity(activity);
    }
  }

  Widget _buildListTile(Activity activity) {
    final formattedDate = DateFormat('dd/MM/yyyy – hh:mm a').format(activity.timestamp);

    return Card(
      elevation: 8,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      margin: EdgeInsets.symmetric(vertical: 10, horizontal: 15),
      child: ListTile(
        contentPadding: EdgeInsets.all(15),
        title: Text(
          '${activity.name} (${activity.points} points)',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        subtitle: Text(
          'Submitted at: $formattedDate',
          style: TextStyle(color: Colors.grey[600], fontSize: 14),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: Icon(Icons.check, color: Colors.greenAccent),
              onPressed: () => _confirmActivity(activity),
            ),
            IconButton(
              icon: Icon(Icons.close, color: Colors.redAccent),
              onPressed: () => _denyActivity(activity),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Admin Page', style: TextStyle(fontFamily: 'RobotoMono')),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 10.0, horizontal: 20.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton.icon(
                  onPressed: _approveAll,
                  icon: Icon(Icons.check, color: Colors.greenAccent),
                  label: Text('Approve All'),
                  style: ElevatedButton.styleFrom(
                    foregroundColor: Colors.greenAccent, backgroundColor: Colors.white, // Foreground color
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12.0),
                    ),
                    padding: EdgeInsets.symmetric(horizontal: 20.0, vertical: 10.0),
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: _denyAll,
                  icon: Icon(Icons.close, color: Colors.redAccent),
                  label: Text('Deny All'),
                  style: ElevatedButton.styleFrom(
                    foregroundColor: Colors.redAccent, backgroundColor: Colors.white, // Foreground color
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12.0),
                    ),
                    padding: EdgeInsets.symmetric(horizontal: 20.0, vertical: 10.0),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: _pendingRequests.length,
              itemBuilder: (context, index) {
                final activity = _pendingRequests[index];

                return Dismissible(
                  key: Key(activity.id),
                  direction: DismissDirection.horizontal,
                  onDismissed: (direction) {
                    if (direction == DismissDirection.endToStart) {
                      _denyActivity(activity);
                    } else if (direction == DismissDirection.startToEnd) {
                      _confirmActivity(activity);
                    }
                  },
                  background: Container(
                    color: Colors.green,
                    alignment: Alignment.centerLeft,
                    padding: EdgeInsets.symmetric(horizontal: 20.0),
                    child: Icon(
                      Icons.check,
                      color: Colors.white,
                    ),
                  ),
                  secondaryBackground: Container(
                    color: Colors.red,
                    alignment: Alignment.centerRight,
                    padding: EdgeInsets.symmetric(horizontal: 20.0),
                    child: Icon(
                      Icons.close,
                      color: Colors.white,
                    ),
                  ),
                  child: _buildListTile(activity),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
