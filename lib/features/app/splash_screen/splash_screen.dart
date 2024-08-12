import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SplashScreen extends StatefulWidget {
  final Widget? child;
  const SplashScreen({Key? key, this.child}) : super(key: key);

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with SingleTickerProviderStateMixin {
  String? imageUrl;
  bool isLoading = true;
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1000), // Duration for fade-in/out
      vsync: this,
    );
    _animation = CurvedAnimation(parent: _controller, curve: Curves.easeIn);

    _fetchImageUrl();
  }

  Future<void> _fetchImageUrl() async {
    await Firebase.initializeApp();
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? cachedUrl = prefs.getString('splash_image_url');
    String? cachedVersion = prefs.getString('splash_image_version');

    try {
      DocumentSnapshot<Map<String, dynamic>> doc = await FirebaseFirestore.instance
          .collection('resources')
          .doc('splash_screen')
          .get();
      if (doc.exists && doc.data()?['imageUrl'] != null) {
        String newUrl = doc.data()!['imageUrl'];
        String newVersion = doc.data()?['version'] ?? '';

        if (newUrl != cachedUrl || newVersion != cachedVersion) {
          setState(() {
            imageUrl = newUrl;
          });
          prefs.setString('splash_image_url', newUrl);
          prefs.setString('splash_image_version', newVersion);
        } else {
          setState(() {
            imageUrl = cachedUrl;
          });
        }
      } else {
        setState(() {
          imageUrl = null;
        });
      }
    } catch (e) {
      print('Error fetching image URL: $e');
    } finally {
      setState(() {
        isLoading = false;
      });
      _controller.forward(); // Start fade-in animation
      Future.delayed(const Duration(seconds: 5), () { // Duration to display the image and text
        _controller.reverse().then((_) {
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (context) => widget.child!),
                (route) => false,
          );
        });
      });
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: FadeTransition(
          opacity: _animation,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 235, // Set fixed width
                height: 340, // Set fixed height (greater than width)
                decoration: BoxDecoration(
                  border: Border.all(
                    color: Colors.black, // Border color
                    width: 4.0, // Border width
                  ),
                  borderRadius: BorderRadius.circular(25.0),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(20.0), // Adjust the value for desired roundness
                  child: imageUrl != null
                      ? CachedNetworkImage(
                    imageUrl: imageUrl!,
                    errorWidget: (context, url, error) => Image.asset('assets/img_1.png'),
                    fit: BoxFit.cover,
                    fadeInDuration: const Duration(milliseconds: 800), // Fade-in duration for image
                  )
                      : Image.asset(
                    'assets/img_1.png',
                    fit: BoxFit.cover,
                  ),
                ),
              ),
              const SizedBox(height: 20.0), // Space between image and text
              const Text(
                'خدمة اعدادي اولاد',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 24.0, // Adjust the font size as needed
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
