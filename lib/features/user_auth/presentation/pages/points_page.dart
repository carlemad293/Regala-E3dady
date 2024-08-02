import 'dart:async';
import 'dart:convert';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'admin_page.dart';
import 'models/activity.dart';
import 'pin_entry_screen.dart';

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
            minimumSize: Size(150, 50),
            textStyle: TextStyle(fontSize: 20),
            padding: EdgeInsets.symmetric(vertical: 12, horizontal: 20),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8.0), // More rectangular
            ),
          ),
        ),
        snackBarTheme: SnackBarThemeData(
          backgroundColor: Colors.white,
          contentTextStyle: TextStyle(color: Colors.black),
          behavior: SnackBarBehavior.floating,
        ),
      ),
      home: PointScreen(),
    );
  }
}

class PointScreen extends StatefulWidget {
  @override
  _PointScreenState createState() => _PointScreenState();
}

class _PointScreenState extends State<PointScreen> {
  final List<Activity> activities = [
    Activity(id: DateTime.now().millisecondsSinceEpoch.toString(), userEmail: '', name: 'قداس', points: 3, timestamp: DateTime.now()),
    Activity(id: DateTime.now().millisecondsSinceEpoch.toString(), userEmail: '', name: 'اعتراف', points: 5, timestamp: DateTime.now()),
    Activity(id: DateTime.now().millisecondsSinceEpoch.toString(), userEmail: '', name: 'اجتماع', points: 2, timestamp: DateTime.now()),
    Activity(id: DateTime.now().millisecondsSinceEpoch.toString(), userEmail: '', name: 'مزمور الكورة', points: 3, timestamp: DateTime.now()),
    Activity(id: DateTime.now().millisecondsSinceEpoch.toString(), userEmail: '', name: 'عشية', points: 2, timestamp: DateTime.now()),
    Activity(id: DateTime.now().millisecondsSinceEpoch.toString(), userEmail: '', name: 'صلاة باكر', points: 1, timestamp: DateTime.now()),
    Activity(id: DateTime.now().millisecondsSinceEpoch.toString(), userEmail: '', name: 'صلاة نوم', points: 1, timestamp: DateTime.now()),
    Activity(id: DateTime.now().millisecondsSinceEpoch.toString(), userEmail: '', name: 'إصحاح من الأنجبل', points: 1, timestamp: DateTime.now()),
  ];

  List<Activity> pendingRequests = [];
  Activity? selectedActivity;
  final TextEditingController _activityController = TextEditingController();
  final TextEditingController _pointsController = TextEditingController();
  bool _showCustomFields = false;
  Timer? _buttonPressTimer;
  bool _isButtonPressed = false;

  bool _isBlocked = false;
  late DateTime _unblockTime;
  Timer? _countdownTimer;

  @override
  void initState() {
    super.initState();
    _loadPendingRequests();
    _checkBlockStatus();
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    super.dispose();
  }

  void _checkBlockStatus() async {
    final prefs = await SharedPreferences.getInstance();
    final blockTimeString = prefs.getString('blockTime');
    if (blockTimeString != null) {
      final blockTime = DateTime.parse(blockTimeString);
      if (blockTime.isAfter(DateTime.now())) {
        setState(() {
          _isBlocked = true;
          _unblockTime = blockTime;
        });
        _startCountdown();
      }
    }
  }

  void _startCountdown() {
    _countdownTimer = Timer.periodic(Duration(seconds: 1), (timer) {
      final remainingTime = _unblockTime.difference(DateTime.now());
      if (remainingTime.isNegative) {
        timer.cancel();
        setState(() {
          _isBlocked = false;
        });
        _clearBlockStatus();
      } else {
        setState(() {});
      }
    });
  }

  void _clearBlockStatus() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('blockTime');
  }

  @override
  Widget build(BuildContext context) {
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
                GestureDetector(
                  onPanUpdate: (details) {
                    // Detect long press with movement
                    if (details.localPosition.dx > 0 && details.localPosition.dy > 0) {
                      if (!_isButtonPressed) {
                        _isButtonPressed = true;
                        _buttonPressTimer = Timer(Duration(seconds: 2), () {
                          if (_isButtonPressed) {
                            _showPinEntryDialog();
                          }
                        });
                      }
                    }
                  },
                  onPanEnd: (_) {
                    _isButtonPressed = false;
                    _buttonPressTimer?.cancel();
                  },
                  child: Column(
                    children: [
                      ElevatedButton(
                        onPressed: _isBlocked ? null : () async {
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
                          minimumSize: Size(100, 35),
                          textStyle: TextStyle(fontSize: 16),
                          padding: EdgeInsets.symmetric(vertical: 10, horizontal: 18),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8.0), // More rectangular
                          ),
                        ),
                        child: Text('Submit'),
                      ),
                      if (_isBlocked)
                        Text(
                          'Blocked. Contact U. Mina Nazeh.',
                          style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> sendRequestToAdmin(Activity activity) async {
    setState(() {
      pendingRequests.add(activity);
    });

    final prefs = await SharedPreferences.getInstance();
    final pendingRequestsJson = jsonEncode(pendingRequests.map((a) => a.toJson()).toList());
    await prefs.setString('pendingRequests', pendingRequestsJson);

    print('Request sent to admin: ${activity.name}, ${activity.points} points, ${activity.timestamp}');
  }

  void _loadPendingRequests() async {
    final prefs = await SharedPreferences.getInstance();
    final pendingRequestsJson = prefs.getString('pendingRequests');
    if (pendingRequestsJson != null) {
      final List<dynamic> decodedJson = jsonDecode(pendingRequestsJson);
      setState(() {
        pendingRequests = decodedJson.map((a) => Activity.fromJson(a)).toList();
      });
    }
  }

  void _showPinEntryDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return PinEntryDialog(
          onPinEntered: (isCorrect) {
            if (isCorrect) {
              Navigator.of(context).pop();
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => AdminPage(pendingRequests: pendingRequests),
                ),
              ).then((_) => _loadPendingRequests());
            } else {
              Navigator.of(context).pop();
            }
          },
        );
      },
    );
  }
}
