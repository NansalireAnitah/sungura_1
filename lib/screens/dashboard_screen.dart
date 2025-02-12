import 'package:flutter/material.dart';
import 'add_food_screen.dart'; 
//import 'add_item.dart';

// Import the new screen (no need for duplicate imports)

class AdminDashboard extends StatelessWidget {
  const AdminDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Admin Dashboard"),
        backgroundColor: const Color(0xFFAA2A00),
      ),
      body: ListView(
        padding: const EdgeInsets.all(10),
        children: [
          // Orders Section
          _buildSectionTitle("Orders", Icons.shopping_cart),
          _buildOrderList(),

          // Notifications Section
          _buildSectionTitle("Notifications", Icons.notifications),
          _buildNotificationList(),

          // Add New Food Items Section
          _buildSectionTitle("Add New Food", Icons.add_circle),
          _buildAddFoodButton(context), // Pass context to the button
        ],
      ),
    );
  }

  // Function to build section titles
  Widget _buildSectionTitle(String title, IconData icon) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 15.0),
      child: Row(
        children: [
          Icon(icon, size: 30, color: const Color(0xFFAA2A00)),
          const SizedBox(width: 10),
          Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  // Function to build order list
  Widget _buildOrderList() {
    return Column(
      children: List.generate(5, (index) {
        return Card(
          margin: const EdgeInsets.symmetric(vertical: 5),
          child: ListTile(
            leading: const Icon(Icons.food_bank, color: Colors.green),
            title: Text("Order #$index"),
            subtitle: const Text("Customer: Shan\nItems: Burger, Pizza"),
            trailing: const Icon(Icons.arrow_forward),
            onTap: () {
              // Handle order details
            },
          ),
        );
      }),
    );
  }

  // Function to build notification list
  Widget _buildNotificationList() {
    return Column(
      children: List.generate(3, (index) {
        return Card(
          margin: const EdgeInsets.symmetric(vertical: 5),
          child: ListTile(
            leading: const Icon(Icons.notifications, color: Colors.blue),
            title: const Text("New Discount Available!"),
            subtitle: const Text("50% off on all pizzas."),
            trailing: const Icon(Icons.arrow_forward),
            onTap: () {
              // Handle notification details
            },
          ),
        );
      }),
    );
  }

  // Function to build the Add Food button
  Widget _buildAddFoodButton(BuildContext context) {
    return ElevatedButton.icon(
      onPressed: () {
        // Navigate to AddFoodItemScreen
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const AddFoodItemScreen()),
        );
      },
      icon: const Icon(Icons.add_circle_outline),
      label: const Text("Add New Food"),
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFFAA2A00),
        padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 30),
      ),
    );
  }
}
