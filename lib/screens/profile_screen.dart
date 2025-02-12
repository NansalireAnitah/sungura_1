import 'package:flutter/material.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  File? _profileImage;
  String _userName = "James Martin"; // Default name
  String _contact = "123-456-7890"; // Default contact number
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _contactController = TextEditingController();

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(
        source: ImageSource.gallery); // Pick from gallery

    if (pickedFile != null) {
      setState(() {
        _profileImage = File(pickedFile.path);
      });
    }
  }

  Future<void> _updatePersonalInfo() async {
    _nameController.text = _userName; // Set the current name in the dialog
    _contactController.text = _contact; // Set the current contact in the dialog
    await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Update Personal Info'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Enter your name',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: _contactController,
                decoration: const InputDecoration(
                  labelText: 'Enter your contact number',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.phone,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Close the dialog
              },
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                setState(() {
                  _userName = _nameController.text; // Update the name
                  _contact = _contactController.text; // Update the contact
                });
                Navigator.of(context).pop(); // Close the dialog
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    );
  }

  // Methods for each section
  Widget _buildSection(String title, Widget content) {
    return Container(
      margin: const EdgeInsets.only(top: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
      ),
      child: ExpansionTile(
        title: Text(title,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        children: [content],
      ),
    );
  }

  // Content for Personal Info
  Widget _personalInfoContent() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ListTile(
            title:
                Text('Name: $_userName', style: const TextStyle(fontSize: 18)),
            trailing: IconButton(
              icon: const Icon(Icons.edit),
              onPressed: _updatePersonalInfo,
            ),
          ),
          const SizedBox(height: 10),
          ListTile(
            title: Text('Contact: $_contact',
                style: const TextStyle(fontSize: 18)),
            trailing: IconButton(
              icon: const Icon(Icons.edit),
              onPressed: _updatePersonalInfo,
            ),
          ),
        ],
      ),
    );
  }

  // Content for Addresses
  Widget _addressesContent() {
    return const Padding(
      padding: EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ListTile(title: Text('Home Address: 123 Main St, Springfield')),
          ListTile(title: Text('Work Address: 456 Office Ave, Cityville')),
        ],
      ),
    );
  }

  // Content for Favorites
  Widget _favoritesContent() {
    return const Padding(
      padding: EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ListTile(title: Text('Favorite Product 1')),
          ListTile(title: Text('Favorite Service 2')),
        ],
      ),
    );
  }

  // // Content for FAQs
  // Widget _faqsContent() {
  //   return const Padding(
  //     padding: EdgeInsets.all(16.0),
  //     child: Column(
  //       crossAxisAlignment: CrossAxisAlignment.start,
  //       children: [
  //         ListTile(
  //           title: Text('Q1: How do I reset my password?'),
  //           subtitle: Text('A1: Go to Settings > Change Password'),
  //         ),
  //         ListTile(
  //           title: Text('Q2: How can I contact support?'),
  //           subtitle: Text('A2: You can contact us via the Support section.'),
  //         ),
  //       ],
  //     ),
  //   );
  // }

  // Content for User Reviews
  // Widget _userReviewsContent() {
  //   return const Padding(
  //     padding: EdgeInsets.all(16.0),
  //     child: Column(
  //       crossAxisAlignment: CrossAxisAlignment.start,
  //       children: [
  //         ListTile(
  //           title: Text('Review by User 1'),
  //           subtitle: Text('Great product! Highly recommend.'),
  //         ),
  //         ListTile(
  //           title: Text('Review by User 2'),
  //           subtitle: Text('Not bad, but can improve quality.'),
  //         ),
  //       ],
  //     ),
  //   );
  // }

  // Content for Settings
  Widget _settingsContent() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: ElevatedButton(
        onPressed: () {
          // You can navigate to the Admin Login Screen here
          // Navigator.push(context, MaterialPageRoute(builder: (context) => const AdminLoginScreen()));
        },
        child: const Text('Go to Admin Login'),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Profile',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 20),
              // Profile Picture
              Center(
                child: GestureDetector(
                  onTap: _pickImage,
                  child: CircleAvatar(
                    radius: 50,
                    backgroundImage: _profileImage != null
                        ? FileImage(_profileImage!)
                        : const AssetImage('assets/default_avatar.png')
                            as ImageProvider,
                    child: _profileImage == null
                        ? const Icon(Icons.camera_alt,
                            size: 30,
                            color: Color(0xFFF02B3D)) // Changed color here
                        : null,
                  ),
                ),
              ),
              const SizedBox(height: 10),
              // Name
              GestureDetector(
                onTap: _updatePersonalInfo,
                child: Text(
                  _userName,
                  style: const TextStyle(
                      fontSize: 24, fontWeight: FontWeight.bold),
                ),
              ),
              const Text(
                '',
                style: TextStyle(color: Colors.grey, fontSize: 14),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),

              // Profile Options using ExpansionTile for dropdown-like behavior
              _buildSection(
                'Personal Info',
                _personalInfoContent(),
              ),
              _buildSection(
                'Favorites',
                _favoritesContent(),
              ),
              // _buildSection(
              //   'FAQs',
              //   _faqsContent(),
              // ),
              // _buildSection(
              //   'User Reviews',
              //   _userReviewsContent(),
              // ),
              _buildSection(
                'Settings',
                _settingsContent(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
