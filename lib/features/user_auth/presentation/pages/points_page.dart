import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'admin_page.dart';
import 'models/activity.dart';
import 'models/app_drawer.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Your App Name',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        colorScheme: ColorScheme.fromSwatch().copyWith(
          secondary: Colors.orangeAccent,
          background: Colors.white,
        ),
        textTheme: TextTheme(
          headlineSmall: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.black),
          titleMedium: TextStyle(fontSize: 20, color: Colors.blueGrey),
          bodyMedium: TextStyle(fontSize: 16, color: Colors.black87),
          bodyLarge: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.black),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            minimumSize: Size(200, 60),
            textStyle: TextStyle(fontSize: 20),
            padding: EdgeInsets.symmetric(vertical: 16, horizontal: 24),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(4.0),
            ),
          ),
        ),
        snackBarTheme: SnackBarThemeData(
          backgroundColor: Colors.white,
          contentTextStyle: TextStyle(color: Colors.black),
          behavior: SnackBarBehavior.floating,
        ),
      ),
      home: FutureBuilder<bool>(
        future: _checkIfAdmin(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          } else {
            bool isAdmin = snapshot.data ?? false;
            return PointScreen(isAdmin: isAdmin);
          }
        },
      ),
    );
  }

  Future<bool> _checkIfAdmin() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final adminDoc = await FirebaseFirestore.instance.collection('admins').doc(user.email).get();
      return adminDoc.exists;
    }
    return false;
  }
}

class PointScreen extends StatefulWidget {
  final bool isAdmin;

  PointScreen({required this.isAdmin});

  @override
  _PointScreenState createState() => _PointScreenState();
}

class _PointScreenState extends State<PointScreen> {
  final List<Activity> activities = [
    Activity(id: DateTime.now().millisecondsSinceEpoch.toString(), userEmail: '', name: 'قداس', points: 3, timestamp: DateTime.now(), userName: ''),
    Activity(id: DateTime.now().millisecondsSinceEpoch.toString(), userEmail: '', name: 'اعتراف', points: 5, timestamp: DateTime.now(), userName: ''),
    Activity(id: DateTime.now().millisecondsSinceEpoch.toString(), userEmail: '', name: 'اجتماع', points: 2, timestamp: DateTime.now(), userName: ''),
    Activity(id: DateTime.now().millisecondsSinceEpoch.toString(), userEmail: '', name: 'مزمور الكورة', points: 3, timestamp: DateTime.now(), userName: ''),
    Activity(id: DateTime.now().millisecondsSinceEpoch.toString(), userEmail: '', name: 'عشية', points: 2, timestamp: DateTime.now(), userName: ''),
    Activity(id: DateTime.now().millisecondsSinceEpoch.toString(), userEmail: '', name: 'صلاة باكر', points: 1, timestamp: DateTime.now(), userName: ''),
    Activity(id: DateTime.now().millisecondsSinceEpoch.toString(), userEmail: '', name: 'صلاة نوم', points: 1, timestamp: DateTime.now(), userName: ''),
    Activity(id: DateTime.now().millisecondsSinceEpoch.toString(), userEmail: '', name: 'إصحاح من الإنجيل', points: 1, timestamp: DateTime.now(), userName: ''),
    Activity(id: DateTime.now().millisecondsSinceEpoch.toString(), userEmail: '', name: 'مهرجان', points: 10, timestamp: DateTime.now(), userName: ''),
  ];

  Activity? selectedActivity;
  final TextEditingController _activityController = TextEditingController();
  final TextEditingController _pointsController = TextEditingController();
  bool _showCustomFields = false;
  String _userName = '';

  @override
  void initState() {
    super.initState();
    _loadUserName();
  }

  Future<void> _loadUserName() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      try {
        final userDoc = await FirebaseFirestore.instance.collection('users').doc(user.email).get();
        if (userDoc.exists) {
          final userData = userDoc.data() as Map<String, dynamic>;
          setState(() {
            _userName = userData['userName'] ?? '';
          });
        }
      } catch (e) {
        print('Error loading user name: $e');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.monetization_on_outlined),
            SizedBox(width: 8),
            Text('Points'),
          ],
        ),
      ),
      drawer: user != null ? AppDrawer(user: user) : null,
      body: Stack(
        children: [
          Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 8.0),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12.0),
                        border: Border.all(color: Colors.grey),
                      ),
                      child: DropdownButton<Activity>(
                        hint: Text('Select Activity'),
                        value: selectedActivity,
                        onChanged: (Activity? newValue) {
                          setState(() {
                            selectedActivity = newValue;
                            _showCustomFields = false;
                          });
                        },
                        items: activities.map((Activity activity) {
                          return DropdownMenuItem<Activity>(
                            value: activity,
                            child: Text('${activity.name} (${activity.points} points)'),
                          );
                        }).toList(),
                        underline: SizedBox(),
                        borderRadius: BorderRadius.circular(12.0),
                      ),
                    ),
                    IconButton(
                      icon: Icon(_showCustomFields ? Icons.remove_circle_outline : Icons.add_circle_outline),
                      onPressed: () {
                        setState(() {
                          _showCustomFields = !_showCustomFields;
                          selectedActivity = null;
                        });
                      },
                    ),
                  ],
                ),
                if (_showCustomFields) ...[
                  SizedBox(height: 20),
                  Container(
                    width: 250,
                    child: TextField(
                      controller: _activityController,
                      decoration: InputDecoration(
                        labelText: 'Type your activity',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12.0),
                        ),
                      ),
                    ),
                  ),
                  SizedBox(height: 20),
                  Container(
                    width: 250,
                    child: TextField(
                      controller: _pointsController,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        labelText: 'Points',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12.0),
                        ),
                      ),
                    ),
                  ),
                ],
                SizedBox(height: 20),
                ElevatedButton(
                  onPressed: () async {
                    final points = int.tryParse(_pointsController.text) ?? 0;
                    if (selectedActivity != null || (_activityController.text.isNotEmpty && points > 0)) {
                      final user = FirebaseAuth.instance.currentUser;
                      if (user != null) {
                        final activity = Activity(
                          id: DateTime.now().millisecondsSinceEpoch.toString(),
                          userEmail: user.email ?? '',
                          name: selectedActivity != null ? selectedActivity!.name : _activityController.text,
                          points: selectedActivity != null ? selectedActivity!.points : points,
                          timestamp: DateTime.now(),
                          isApproved: false,
                          userName: _userName,
                        );

                        await sendRequestToAdmin(activity);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Submitted successfully', style: TextStyle(color: Colors.green)),
                            backgroundColor: Colors.white,
                          ),
                        );
                        HapticFeedback.vibrate();
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('User not logged in', style: TextStyle(color: Colors.red)),
                            backgroundColor: Colors.white,
                          ),
                        );
                      }
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Please choose an activity or type one with points', style: TextStyle(color: Colors.red)),
                          backgroundColor: Colors.white,
                        ),
                      );
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(4.0),
                    ),
                  ),
                  child: Text('Submit'),
                ),
              ],
            ),
          ),
          if (widget.isAdmin)
            Align(
              alignment: Alignment.bottomCenter,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: ElevatedButton(
                  onPressed: () {
                    _showPinEntryDialog();
                  },
                  style: ElevatedButton.styleFrom(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(4.0),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.admin_panel_settings),
                      SizedBox(width: 8),
                      Text('Admin Panel'),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Future<void> sendRequestToAdmin(Activity activity) async {
    final firestore = FirebaseFirestore.instance;
    final user = FirebaseAuth.instance.currentUser;

    if (user != null) {
      try {
        await firestore.collection('requests').add({
          'userEmail': user.email,
          'userName': activity.userName,
          'name': activity.name,
          'points': activity.points,
          'timestamp': activity.timestamp,
          'isApproved': activity.isApproved,
        });
        print('Request sent to admin: ${activity.name}, ${activity.points} points, ${activity.timestamp}');
      } catch ( e) {
        print('Error sending request: $e');
      }
    }
  }

  void _showPinEntryDialog() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AdminUniversalPointsScreen(),
      ),
    );
  }
}
