import 'package:flutter/material.dart';

class SplashScreen extends StatefulWidget {
  final Widget? child;
  const SplashScreen({Key? key, this.child}) : super(key: key);

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(seconds: 3), () {
      Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => widget.child!),
              (route) => false);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              decoration: BoxDecoration(
                border: Border.all(
                  color: Colors.black, // Border color
                  width: 4.0, // Border width
                ),
                borderRadius: BorderRadius.circular(20.0),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(20.0), // Adjust the value for desired roundness
                child: Image.asset(
                  'assets/img_1.png', // Replace with your image asset path
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
    );
  }
}
