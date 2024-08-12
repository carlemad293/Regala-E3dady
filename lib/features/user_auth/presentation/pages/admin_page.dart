import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:vibration/vibration.dart';

import 'models/activity.dart';

class AdminUniversalPointsScreen extends StatefulWidget {
  @override
  _AdminUniversalPointsScreenState createState() =>
      _AdminUniversalPointsScreenState();
}

class _AdminUniversalPointsScreenState extends State<AdminUniversalPointsScreen> {
  List<Activity> _pendingRequests = [];
  TextEditingController _searchController = TextEditingController();
  String _searchText = "";
  String _sortOption = 'Name';
  List<String> _notificationMessages = [];
  List<String> _seenNotificationIds = [];

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      setState(() {
        _searchText = _searchController.text;
      });
    });

    FirebaseFirestore.instance.collection('requests').snapshots().listen((snapshot) {
      for (var change in snapshot.docChanges) {
        if (change.type == DocumentChangeType.added) {
          final data = change.doc.data() as Map<String, dynamic>;
          if (!(data['seen'] ?? false) && !_seenNotificationIds.contains(change.doc.id)) {
            final newRequest = Activity.fromJson({
              ...data,
              'id': change.doc.id,
            });
            setState(() {
              _notificationMessages.add("New request from ${newRequest.userName} for activity: ${newRequest.name}");
              _seenNotificationIds.add(change.doc.id);
              _triggerVibration();
            });
            FirebaseFirestore.instance.collection('requests').doc(change.doc.id).update({'seen': true});
          }
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Admin & Universal Points'),
        actions: [
          if (_notificationMessages.isNotEmpty)
            IconButton(
              icon: Icon(Icons.clear_all),
              onPressed: _clearNotifications,
              tooltip: 'Clear All Notifications',
            ),
        ],
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.white, Colors.grey[200]!],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            children: [
              if (_notificationMessages.isNotEmpty)
                Card(
                  color: Colors.blueAccent,
                  margin: EdgeInsets.symmetric(vertical: 10.0),
                  child: Column(
                    children: [
                      ..._notificationMessages.map((message) => ListTile(
                        leading: Icon(Icons.notification_important, color: Colors.white),
                        title: Text(
                          message,
                          style: TextStyle(color: Colors.white),
                        ),
                      )),
                      ListTile(
                        trailing: IconButton(
                          icon: Icon(Icons.clear, color: Colors.white),
                          onPressed: _clearNotifications,
                        ),
                      ),
                    ],
                  ),
                ),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _searchController,
                      decoration: InputDecoration(
                        labelText: 'Search',
                        prefixIcon: Icon(Icons.search),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10.0),
                        ),
                      ),
                    ),
                  ),
                  SizedBox(width: 10),
                  DropdownButton<String>(
                    value: _sortOption,
                    onChanged: (String? newValue) {
                      setState(() {
                        _sortOption = newValue!;
                      });
                    },
                    items: <String>['Name', 'Newest', 'Highest Points']
                        .map<DropdownMenuItem<String>>((String value) {
                      return DropdownMenuItem<String>(
                        value: value,
                        child: Text('Sort by $value'),
                      );
                    }).toList(),
                  ),
                ],
              ),
              SizedBox(height: 10),
              Expanded(
                child: StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance.collection('users').snapshots(),
                  builder: (context, snapshot) {
                    if (!snapshot.hasData) {
                      return Center(child: CircularProgressIndicator());
                    }

                    if (snapshot.hasError) {
                      return Center(child: Text('Error: ${snapshot.error}'));
                    }

                    final users = snapshot.data!.docs;

                    List<Map<String, dynamic>> userList = users.map((user) {
                      final userData = user.data() as Map<String, dynamic>;
                      return {
                        'id': user.id,
                        'name': userData['name'] ?? 'Unknown',
                        'points': userData['points'] ?? 0,
                        'blocked': userData['blocked'] ?? false,
                        'timestamp': userData['timestamp'] ?? Timestamp.now(),
                      };
                    }).toList();

                    // Apply Sorting before filtering
                    switch (_sortOption) {
                      case 'Newest':
                        userList.sort((a, b) => b['timestamp'].compareTo(a['timestamp']));
                        break;
                      case 'Highest Points':
                        userList.sort((a, b) => b['points'].compareTo(a['points']));
                        break;
                      case 'Name':
                      default:
                        userList.sort((a, b) => a['name'].compareTo(b['name']));
                        break;
                    }

                    // Apply Search Filter
                    if (_searchText.isNotEmpty) {
                      userList = userList.where((user) {
                        final name = user['name'].toLowerCase();
                        return name.contains(_searchText.toLowerCase());
                      }).toList();
                    }

                    return ListView.builder(
                      itemCount: userList.length,
                      itemBuilder: (context, index) {
                        final user = userList[index];
                        final name = user['name'];
                        final email = user['id'];
                        final points = user['points'];
                        final isBlocked = user['blocked'];

                        return Card(
                          elevation: 5,
                          margin: EdgeInsets.symmetric(vertical: 8.0, horizontal: 5.0),
                          child: ExpansionTile(
                            title: ListTile(
                              title: _highlightText(name, _searchText, isName: true),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    email,
                                    style: TextStyle(
                                      color: Colors.grey,
                                      fontSize: 14,
                                    ),
                                  ),
                                  Row(
                                    children: [
                                      Text(
                                        'Points: $points',
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          color: Colors.red,
                                          fontSize: 14,
                                        ),
                                      ),
                                      if (isBlocked) ...[
                                        SizedBox(width: 10),
                                        Icon(Icons.block, color: Colors.red),
                                      ],
                                    ],
                                  ),
                                ],
                              ),
                              trailing: IconButton(
                                icon: Icon(Icons.edit),
                                onPressed: () {
                                  _showEditDialog(context, email, name, points);
                                },
                              ),
                              onLongPress: () {
                                _showOptionsDialog(context, email, name, isBlocked);
                              },
                            ),
                            children: isBlocked
                                ? []
                                : [
                              StreamBuilder<QuerySnapshot>(
                                stream: FirebaseFirestore.instance
                                    .collection('requests')
                                    .where('userEmail', isEqualTo: email)
                                    .where('isApproved', isEqualTo: false)
                                    .snapshots(),
                                builder: (context, activitySnapshot) {
                                  if (!activitySnapshot.hasData) {
                                    return Center(
                                        child: CircularProgressIndicator());
                                  }

                                  if (activitySnapshot.hasError) {
                                    return Center(
                                        child: Text(
                                            'Error: ${activitySnapshot.error}'));
                                  }

                                  final activities = activitySnapshot.data!.docs
                                      .map((doc) => Activity.fromJson({
                                    ...doc.data()
                                    as Map<String, dynamic>,
                                    'id': doc.id,
                                  }))
                                      .toList();

                                  if (activities.isEmpty) {
                                    return Padding(
                                      padding: const EdgeInsets.all(8.0),
                                      child: Text('No pending requests'),
                                    );
                                  }

                                  return ListView.builder(
                                    shrinkWrap: true,
                                    physics: ClampingScrollPhysics(),
                                    itemCount: activities.length,
                                    itemBuilder: (context, index) {
                                      final activity = activities[index];
                                      return _buildActivityTile(activity);
                                    },
                                  );
                                },
                              ),
                            ],
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _triggerVibration() {
    if (Vibration.hasVibrator() != null) {
      Vibration.vibrate(duration: 500);
    }
  }

  void _clearNotifications() {
    setState(() {
      _notificationMessages.clear();
    });
  }

  void _deleteNotifications() async {
    final batch = FirebaseFirestore.instance.batch();
    for (var notificationId in _seenNotificationIds) {
      batch.delete(FirebaseFirestore.instance.collection('requests').doc(notificationId));
    }
    await batch.commit();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _notificationMessages.clear(); // Clear notifications when leaving the screen
    _deleteNotifications(); // Delete notifications when leaving the screen
    super.dispose();
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
      await FirebaseFirestore.instance.collection('requests').doc(activity.id).update({
        'isApproved': true,
      });

      await _updateUserPoints(activity);

      setState(() {
        _pendingRequests.remove(activity);
      });

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
      await FirebaseFirestore.instance.collection('requests').doc(activity.id).delete();

      setState(() {
        _pendingRequests.remove(activity);
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Activity denied: ${activity.name}')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to deny activity: $e')),
      );
    }
  }

  void _showEditDialog(BuildContext context, String email, String name, int points) {
    TextEditingController _pointsController =
    TextEditingController(text: points.toString());

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Edit Points for $name'),
          content: TextField(
            controller: _pointsController,
            decoration: InputDecoration(labelText: 'Points'),
            keyboardType: TextInputType.number,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Cancel'),
            ),
            TextButton(
              onPressed: () async {
                bool confirmed = await showDialog(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: Text('Confirm Update'),
                    content: Text(
                        'Are you sure you want to update the points for $name?'),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.of(context).pop(false),
                        child: Text('No'),
                      ),
                      TextButton(
                        onPressed: () => Navigator.of(context).pop(true),
                        child: Text('Yes'),
                      ),
                    ],
                  ),
                );

                if (confirmed) {
                  int newPoints =
                      int.tryParse(_pointsController.text) ?? points;
                  await FirebaseFirestore.instance
                      .collection('users')
                      .doc(email)
                      .update({'points': newPoints});
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Points updated successfully')),
                  );
                  Navigator.pop(context);
                }
              },
              child: Text('Update'),
            ),
          ],
        );
      },
    );
  }

  void _showOptionsDialog(BuildContext context, String email, String name, bool isBlocked) {
    TextEditingController _nameController = TextEditingController(text: name);

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Options for $name'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: _nameController,
                decoration: InputDecoration(labelText: 'Edit Name'),
              ),
              SizedBox(height: 10),
              ElevatedButton.icon(
                icon: Icon(Icons.block),
                label: Text(isBlocked ? 'Unblock User' : 'Block User'),
                style: ElevatedButton.styleFrom(),
                onPressed: () async {
                  await FirebaseFirestore.instance
                      .collection('users')
                      .doc(email)
                      .update({'blocked': !isBlocked});
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(isBlocked ? 'User unblocked' : 'User blocked')),
                  );
                },
              ),
              SizedBox(height: 10),
              ElevatedButton.icon(
                icon: Icon(Icons.delete),
                label: Text('Delete User'),
                style: ElevatedButton.styleFrom(
                  foregroundColor: Colors.white, backgroundColor: Colors.red,
                ),
                onPressed: () async {
                  await FirebaseFirestore.instance
                      .collection('users')
                      .doc(email)
                      .delete();
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('User deleted')),
                  );
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Cancel'),
            ),
            TextButton(
              onPressed: () async {
                await FirebaseFirestore.instance
                    .collection('users')
                    .doc(email)
                    .update({'name': _nameController.text});
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Name updated successfully')),
                );
              },
              child: Text('Save Name'),
            ),
          ],
        );
      },
    );
  }

  Widget _buildActivityTile(Activity activity) {
    final formattedDate =
    DateFormat('dd/MM/yyyy – hh:mm a').format(activity.timestamp);

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
        child: Row(
          children: [
            Icon(
              Icons.check,
              color: Colors.white,
            ),
            SizedBox(width: 8),
            Text(
              'Accept',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
      secondaryBackground: Container(
        color: Colors.red,
        alignment: Alignment.centerRight,
        padding: EdgeInsets.symmetric(horizontal: 20.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            Text(
              'Deny',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(width: 8),
            Icon(
              Icons.close,
              color: Colors.white,
            ),
          ],
        ),
      ),
      child: Card(
        elevation: 8,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        margin: EdgeInsets.symmetric(vertical: 10, horizontal: 5),
        child: ListTile(
          contentPadding: EdgeInsets.all(15),
          title: Text(
            '${activity.name} (${activity.points} points)',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
          ),
          subtitle: Text(
            'Submitted by: ${activity.userName}\nSubmitted at: $formattedDate',
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
      ),
    );
  }

  Widget _highlightText(String text, String query, {bool isName = false}) {
    if (query.isEmpty) {
      return Text(
        text,
        style: isName ? TextStyle(fontWeight: FontWeight.bold) : null,
      );
    }
    final matches = query.toLowerCase().allMatches(text.toLowerCase());
    if (matches.isEmpty) {
      return Text(
        text,
        style: isName ? TextStyle(fontWeight: FontWeight.bold) : null,
      );
    }
    final spans = <TextSpan>[];
    int start = 0;
    for (final match in matches) {
      if (match.start != start) {
        spans.add(TextSpan(text: text.substring(start, match.start)));
      }
      spans.add(TextSpan(
        text: text.substring(match.start, match.end),
        style: TextStyle(backgroundColor: Colors.yellow),
      ));
      start = match.end;
    }
    if (start != text.length) {
      spans.add(TextSpan(text: text.substring(start)));
    }
    return RichText(
      text: TextSpan(
        style: isName
            ? TextStyle(fontWeight: FontWeight.bold, color: Colors.black)
            : TextStyle(color: Colors.black),
        children: spans,
      ),
    );
  }
}
