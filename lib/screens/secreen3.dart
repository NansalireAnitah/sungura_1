import 'package:flutter/material.dart';
import 'package:front_end/screens/home_screen.dart';

class InitialScreen extends StatelessWidget {
  const InitialScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Background Image
          Container(
            decoration: const BoxDecoration(
              image: DecorationImage(
                image: AssetImage('assets/images/burgger.jpg'), // Replace with your image path
                fit: BoxFit.cover,
              ),
            ),
          ),
          // Content Overlay
          Container(
            color: Colors.black.withOpacity(0.5), // Dim the background image
          ),
          // Centered "Order Now" Button
          Center(
            child: ElevatedButton(
              onPressed: () {
                // Navigate to the HomeScreen
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const HomeScreen(),
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color.fromARGB(255, 246, 244, 242),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 30,
                  vertical: 15,
                ), // Increase padding for a bigger button
                minimumSize: const Size(200, 60), // Set a minimum size for the button
              ),
              child: const Text(
                "Order Now",
                style: TextStyle(
                  fontSize: 20, // Increased font size
                  fontWeight: FontWeight.bold,
                  color: Color.fromARGB(255, 238, 21, 21),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}