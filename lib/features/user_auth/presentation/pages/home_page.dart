import 'dart:async';
import 'dart:convert';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:your_project_name/features/user_auth/presentation/pages/help_page.dart';
import 'package:your_project_name/features/user_auth/presentation/pages/points_page.dart';

import 'Mwa3ed_page.dart';
import 'account_page.dart'; // Ensure this is correct
import 'models/activity.dart';

class HomeScreen extends StatelessWidget {
  final User user;

  HomeScreen({required this.user});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Icon(Icons.home),
                SizedBox(width: 8),
                Text('Home Screen'),
              ],
            ),
            IconButton(
              icon: Icon(Icons.person_outline),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => AccountScreen(user: user)),
                );
              },
            ),
          ],
        ),
      ),
      body: Stack(
        children: [
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ElevatedButton(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.calendar_today),
                      SizedBox(width: 8),
                      Text('Calendar', style: TextStyle(fontSize: 20)),
                    ],
                  ),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => WebViewApp()),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    minimumSize: Size(150, 50),
                  ),
                ),
                SizedBox(height: 20),
                ElevatedButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => PointScreen()),
                    );
                  },
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.monetization_on),
                      SizedBox(width: 8),
                      Text('Points', style: TextStyle(fontSize: 20)),
                    ],
                  ),
                  style: ElevatedButton.styleFrom(
                    minimumSize: Size(150, 50),
                  ),
                ),
              ],
            ),
          ),
          Align(
            alignment: Alignment.bottomRight,
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: IconButton(
                icon: Icon(Icons.help_outline),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => HelpScreen()),
                  );
                },
              ),
            ),
          ),
          Align(
            alignment: Alignment.bottomLeft,
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: CopticDateWidget(),
            ),
          ),
        ],
      ),
    );
  }
}

class CopticDateWidget extends StatefulWidget {
  @override
  _CopticDateWidgetState createState() => _CopticDateWidgetState();
}

class _CopticDateWidgetState extends State<CopticDateWidget> {
  String _copticDate = '';
  String _gregorianDate = '';

  @override
  void initState() {
    super.initState();
    _updateDates();
    Timer.periodic(Duration(seconds: 1), (timer) {
      _updateDates();
    });
  }

  void _updateDates() {
    final now = DateTime.now();
    final copticDate = _convertToCopticDate(now);
    final gregorianDate = DateFormat('EEEE, MMMM d, yyyy').format(now);
    setState(() {
      _copticDate = copticDate;
      _gregorianDate = gregorianDate;
    });
  }

  String _convertToCopticDate(DateTime date) {
    final a = ((14 - date.month) / 12).floor();
    final m = date.month + 12 * a - 3;
    final y = date.year + (4800 - a) - 1;
    final jdn = date.day + ((153 * m + 2) / 5).floor() + 365 * y + (y / 4).floor() - (y / 100).floor() + (y / 400).floor() - 32045;
    final copticEpoch = 1824665;
    final copticJdn = jdn - copticEpoch;
    final copticYear = (copticJdn / 365.25).floor();
    final copticDayOfYear = copticJdn - (copticYear * 365.25).floor();
    final copticMonth = (copticDayOfYear / 30).floor() + 1;
    final copticDay = copticDayOfYear - (copticMonth - 1) * 30;

    final copticMonthNames = [
      'Toot', 'Baba', 'Hatoor', 'Kiahk', 'Tooba', 'Amshir', 'Baramhat', 'Baramouda', 'Bashans', 'Baouna', 'Abeeb', 'Mesra', 'Nasie'
    ];
    final copticMonthName = copticMonthNames[copticMonth - 1];

    return '${copticDay + 1} $copticMonthName ${copticYear + 1}';
  }

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.bottomLeft,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _gregorianDate,
            style: TextStyle(
              fontSize: 16,
            ),
          ),
          SizedBox(height: 8),
          Text(
            _copticDate,
            style: TextStyle(
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }
}

void sendRequestToAdmin(Activity activity) async {
  final url = Uri.parse('https://your-api-endpoint.com/request-points');
  final response = await http.post(
    url,
    headers: {
      'Content-Type': 'application/json',
    },
    body: jsonEncode(activity.toJson()),
  );

  if (response.statusCode == 200) {
    print('Request sent successfully');
  } else {
    print('Failed to send request');
  }
}
