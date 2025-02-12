import 'package:flutter/material.dart';
import 'menu_screen.dart'; // Import your MenuScreen

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
                image: AssetImage('assets/images/table.jpg'), // Replace with your image path
                fit: BoxFit.cover,
              ),
            ),
          ),

          // Content Overlay
          Container(
            color: Colors.black.withOpacity(0.5), // Dim the background image
          ),

          // Centered Content
          const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Logo or App Name
                // const Text(
                //   "Welcome to The Little Cafe", // Replace with your app name
                //   style: TextStyle(
                //     fontSize: 28,
                //     fontWeight: FontWeight.bold,
                //     color: Colors.white,
                //   ),
                //   textAlign: TextAlign.center,
                // ),
                SizedBox(height: 20),

                // Tagline
                // const Text(
                //   "Delicious Meals, Delivered Fresh!",
                //   style: TextStyle(
                //     fontSize: 18,
                //     color: Colors.white70,
                //   ),
                //   textAlign: TextAlign.center,
                // ),
                SizedBox(height: 40),
              ],
            ),
          ),

          // "Order Now" Button at the Bottom
          Align(
            alignment: Alignment.bottomCenter,
            child: Padding(
              padding: const EdgeInsets.all(20.0), // Add padding for spacing
              child: ElevatedButton(
                onPressed: () {
                  // Navigate to the MenuScreen
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const MenuScreen(),
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.redAccent, // Button color
                  padding: const EdgeInsets.symmetric(
                    horizontal: 40,
                    vertical: 15,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                ),
                child: const Text(
                  "Order Now",
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
