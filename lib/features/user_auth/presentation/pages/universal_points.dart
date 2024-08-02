import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // For HapticFeedback

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: FirebaseOptions(
      apiKey: "AIzaSyDGKsJEnyO4GSLA2GDi-Hi2wbl68T0a0xo",
      appId: "1:697018854717:web:9d42721dc27e8966396954",
      messagingSenderId: "697018854717",
      projectId: "dma-app-a8112",
      storageBucket: "dma-app-a8112.appspot.com",
    ),
  );
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Universal Points',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        colorScheme: ColorScheme.fromSwatch().copyWith(
          secondary: Colors.orangeAccent,
          background: Colors.white,
        ),
        textTheme: TextTheme(
          headlineSmall: TextStyle(
              fontSize: 24, fontWeight: FontWeight.bold, color: Colors.black),
          titleMedium: TextStyle(fontSize: 20, color: Colors.blueGrey),
          bodyMedium: TextStyle(fontSize: 18, color: Colors.black87),
        ),
        buttonTheme: ButtonThemeData(
          buttonColor: Colors.blueAccent,
          textTheme: ButtonTextTheme.primary,
        ),
        inputDecorationTheme: InputDecorationTheme(
          border: OutlineInputBorder(),
          focusedBorder: OutlineInputBorder(
            borderSide: BorderSide(color: Colors.blueAccent),
          ),
          labelStyle: TextStyle(color: Colors.blueAccent),
        ),
      ),
      home: UniversalPointsScreen(),
    );
  }
}

class UniversalPointsScreen extends StatefulWidget {
  @override
  _UniversalPointsScreenState createState() => _UniversalPointsScreenState();
}

class _UniversalPointsScreenState extends State<UniversalPointsScreen>
    with SingleTickerProviderStateMixin {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _pointsController = TextEditingController();
  final GlobalKey<AnimatedListState> _listKey = GlobalKey<AnimatedListState>();
  late AnimationController _animationController;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _updatePoints(BuildContext context, String email) async {
    final points = int.tryParse(_pointsController.text);

    if (points == null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Invalid points'),
      ));
      return;
    }

    final userDoc = FirebaseFirestore.instance.collection('users').doc(email);

    try {
      await userDoc.update({'points': points});
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Points updated successfully'),
      ));
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Failed to update points: $e'),
      ));
    }
  }

  void _showEditDialog(
      BuildContext context, String email, String name, int points) {
    _emailController.text = email;
    _pointsController.text = points.toString();

    showDialog(
      context: context,
      builder: (context) {
        _animationController.forward();
        return ScaleTransition(
          scale: CurvedAnimation(
              parent: _animationController, curve: Curves.easeInOut),
          child: AlertDialog(
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
                  // Show confirmation dialog
                  bool confirmed = await showDialog(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: Text('Confirm Update'),
                      content: Text('Are you sure you want to update the points for $name?'),
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
                    HapticFeedback.vibrate(); // Add slight vibration
                    _updatePoints(context, email);
                    Navigator.pop(context);
                  }
                },
                child: Text('Update'),
              ),
            ],
          ),
        );
      },
    ).then((_) {
      _animationController.reverse();
    });
  }

  Future<void> _reloadData() async {
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Universal Points'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: RefreshIndicator(
          onRefresh: _reloadData,
          child: Column(
            children: [
              StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance.collection('users').snapshots(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) {
                    return Center(child: CircularProgressIndicator());
                  }

                  final users = snapshot.data!.docs;

                  // Debugging: Print user data to console
                  print('Users fetched from Firestore: ${users.length}');
                  for (var user in users) {
                    print('User: ${user.id}, Data: ${user.data()}');
                  }

                  return Expanded(
                    child: AnimatedList(
                      key: _listKey,
                      initialItemCount: users.length,
                      itemBuilder: (context, index, animation) {
                        final user = users[index];
                        final userData = user.data() as Map<String, dynamic>;
                        final email = user.id;
                        final name = userData['name'] ?? 'Unknown';
                        final points = userData['points'] ?? 0;

                        return FadeTransition(
                          opacity: animation,
                          child: SlideTransition(
                            position: Tween<Offset>(
                              begin: Offset(1, 0),
                              end: Offset(0, 0),
                            ).animate(animation),
                            child: Card(
                              elevation: 5,
                              margin: EdgeInsets.symmetric(vertical: 8.0),
                              child: ListTile(
                                title: RichText(
                                  text: TextSpan(
                                    children: [
                                      TextSpan(
                                        text: '$name ',
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 16,
                                          color: Colors.black,
                                        ),
                                      ),
                                      TextSpan(
                                        text: '($email)',
                                        style: TextStyle(
                                          color: Colors.grey,
                                          fontSize: 14,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                subtitle: Text(
                                  'Points: $points',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.red,
                                    fontSize: 14,
                                  ),
                                ),
                                trailing: IconButton(
                                  icon: Icon(Icons.edit),
                                  onPressed: () {
                                    _showEditDialog(context, email, name, points);
                                  },
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
