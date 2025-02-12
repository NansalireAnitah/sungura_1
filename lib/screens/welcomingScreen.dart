import 'dart:async';
import 'package:flutter/material.dart';
import 'secreen2.dart'; // Import FinalSplashScreen

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  _SplashScreenState createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    // Delay for (20 seconds) before navigating
    Future.delayed(const Duration(seconds: 8), () {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const FinalSplashScreen()),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Background Image with Blur Effect
          Positioned.fill(
            child: Image.asset(
              'assets/images/lit1.jpg', // Replace with your background image path
              fit: BoxFit.cover,
            ),
          ),
          Positioned.fill(
            child: Container(
              color: Colors.white.withOpacity(0.6), // Adds a semi-transparent overlay
            ),
          ),

          // Logo 
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Logo
                Image.asset(
                  'assets/images/sungura.png', // Replace with your logo path
                  width: 400,
                  height: 400,
                ),
                const SizedBox(height: 20),
                // Welcome Text
                // const Text(
                //   "Welcome",
                //   style: TextStyle(
                //     fontSize: 40,
                //     fontWeight: FontWeight.bold,
                //     color: Color.fromARGB(255, 20, 100, 165)//RGB(255, 7, 117, 207)RGB(255, 12, 126, 219)RGB(255, 16, 117, 199)RGB(255, 21, 109, 180)RGB(255, 25, 88, 139)RGB(255, 107, 178, 236),
                //   ),
                // ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
