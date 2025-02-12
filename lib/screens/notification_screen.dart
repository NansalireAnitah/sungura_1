import 'package:flutter/material.dart';

class NotificationScreen extends StatelessWidget {
  final List<String> notifications;

  const NotificationScreen({super.key, required this.notifications});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Notifications',
          style: TextStyle(color: Colors.white),  // Set the title color if needed
        ),
        centerTitle: true,
        backgroundColor: const Color(0xFF0050A5),  // Use the custom background color
      ),
      body: ListView.builder(
        itemCount: notifications.length,
        itemBuilder: (context, index) {
          return ListTile(
            title: Text(notifications[index]),
            leading: const Icon(Icons.notifications),
          );
        },
      ),
    );
  }
}
