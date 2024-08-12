import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:your_project_name/features/app/splash_screen/splash_screen.dart';
import 'package:your_project_name/features/user_auth/presentation/pages/login_page.dart';

// Background message handler function
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  print("Handling a background message: ${message.messageId}");
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase for web or mobile
  if (kIsWeb) {
    await Firebase.initializeApp(
      options: FirebaseOptions(
        apiKey: "AIzaSyDGKsJEnyO4GSLA2GDi-Hi2wbl68T0a0xo",
        appId: "1:697018854717:web:9d42721dc27e8966396954",
        messagingSenderId: "697018854717",
        projectId: "dma-app-a8112",
        storageBucket: "dma-app-a8112.appspot.com",
      ),
    );
  } else {
    await Firebase.initializeApp(options: FirebaseOptions(
      apiKey: 'AIzaSyDGKsJEnyO4GSLA2GDi-Hi2wbl68T0a0xo',
      appId: '1:697018854717:web:9d42721dc27e8966396954',
      messagingSenderId: '697018854717',
      projectId: 'dma-app-a8112',
      storageBucket: "dma-app-a8112.appspot.com",
    ));
  }

  // Setup background message handler
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
        debugShowCheckedModeBanner: false,
        title: "5dma app",
        home: SplashScreen(
          child: SignInScreen(),
        ));
  }
}
