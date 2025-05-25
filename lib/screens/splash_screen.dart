import 'dart:async';
import 'package:flutter/material.dart';
import 'package:front_end/screens/secreen2.dart';
//import 'screen2.dart'; // Import FinalSplashScreen (update to correct path if needed)

class SplashScreen extends StatefulWidget {
  final void Function(dynamic) onAddToCart;
  final VoidCallback onFinish;

  const SplashScreen({
    super.key,
    required this.onAddToCart,
    required this.onFinish,
  });

  @override
  _SplashScreenState createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    // Delay for 8 seconds before navigating
    Future.delayed(const Duration(seconds: 8), () {
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const FinalSplashScreen()),
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 248, 89, 15),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Centered logo with proper constraints
            Container(
              constraints: const BoxConstraints(
                maxWidth: 300,
                maxHeight: 300,
              ),
              child: Image.asset(
                'assets/images/sungura1.png',
                fit: BoxFit.contain,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}