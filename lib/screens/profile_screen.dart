import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:front_end/screens/login_screen.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'package:front_end/screens/Signup.dart';
import 'package:provider/provider.dart';
import 'package:front_end/providers/cart_provider.dart';
import 'package:front_end/providers/auth_provider.dart';
import 'package:image_picker_web/image_picker_web.dart';
import 'package:universal_html/html.dart' as html;

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  Future<void> _logout(BuildContext context) async {
    try {
      final authProvider = Provider.of<MyAuthProvider>(context, listen: false);
      final cartProvider = Provider.of<CartProvider>(context, listen: false);

      await authProvider.logout();
      await FirebaseAuth.instance.signOut();
      cartProvider.clearCart();

      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (context) => const LoginScreen()),
        (Route<dynamic> route) => false,
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Logout failed: ${e.toString()}')),
      );
    }
  }

  Future<void> _updateProfileImage(BuildContext context) async {
    try {
      String? imageUrl;

      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(child: CircularProgressIndicator()),
      );

      if (kIsWeb) {
        final html.File? pickedFile = await ImagePickerWeb.getImageAsFile();
        if (pickedFile != null) {
          imageUrl = await _uploadImageToImgBBWeb(pickedFile);
        }
      } else {
        final pickedFile =
            await ImagePicker().pickImage(source: ImageSource.gallery);
        if (pickedFile != null) {
          imageUrl = await _uploadImageToImgBBMobile(File(pickedFile.path));
        }
      }

      if (imageUrl != null) {
        final authProvider = Provider.of<MyAuthProvider>(context, listen: false);
        final firebaseUser = FirebaseAuth.instance.currentUser;

        if (firebaseUser != null) {
          await authProvider.updateUserProfile(
            firebaseUser.uid,
            {'profileImageUrl': imageUrl},
          );
          await firebaseUser.updatePhotoURL(imageUrl);

          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Profile image updated successfully')),
          );
        }
      }

      Navigator.of(context).pop();
    } catch (e) {
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to update image: ${e.toString()}')),
      );
    }
  }

  Future<String> _uploadImageToImgBBMobile(File imageFile) async {
    const apiKey = 'a76d491b3f50093fddaf42dcfaedc1c6';
    final uri = Uri.parse('https://api.imgbb.com/1/upload?key=$apiKey');
    final request = http.MultipartRequest('POST', uri)
      ..files.add(await http.MultipartFile.fromPath('image', imageFile.path));

    final response = await request.send();
    final responseData = await response.stream.bytesToString();
    final jsonData = json.decode(responseData);

    if (response.statusCode != 200) {
      throw Exception('Failed to upload image');
    }

    return jsonData['data']['url'];
  }

  Future<String> _uploadImageToImgBBWeb(html.File imageFile) async {
    const apiKey = 'a76d491b3f50093fddaf42dcfaedc1c6';
    final uri = Uri.parse('https://api.imgbb.com/1/upload?key=$apiKey');

    final reader = html.FileReader();
    reader.readAsArrayBuffer(imageFile);
    await reader.onLoad.first;

    final bytes = reader.result as List<int>;
    final base64Image = base64Encode(bytes);

    final response = await http.post(
      uri,
      body: {
        'image': base64Image,
      },
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to upload image');
    }
    final jsonData = json.decode(response.body);
    return jsonData['data']['url'];
  }

  ImageProvider _getProfileImage(String? firebaseUrl, String? userDataUrl) {
    if (userDataUrl != null && userDataUrl.isNotEmpty) {
      return NetworkImage(userDataUrl);
    } else if (firebaseUrl != null) {
      return NetworkImage(firebaseUrl);
    }
    return const AssetImage('images/profile.png');
  }

  @override
  Widget build(BuildContext context) {
    final firebaseUser = FirebaseAuth.instance.currentUser;
    final authProvider = Provider.of<MyAuthProvider>(context);
    final userData = authProvider.user;

    final userName = userData?.name ?? firebaseUser?.displayName ?? 'Guest';
    final userEmail = firebaseUser?.email ?? '';
    final userPhotoUrl = firebaseUser?.photoURL;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text("Profile"),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 20),
          child: Column(
            children: [
              const SizedBox(height: 20),
              GestureDetector(
                onTap: () => _updateProfileImage(context),
                child: Center(
                  child: Stack(
                    children: [
                      CircleAvatar(
                        radius: 50,
                        backgroundImage: _getProfileImage(
                          userPhotoUrl,
                          userData?.profileImageUrl,
                        ),
                      ),
                      Positioned(
                        bottom: 0,
                        right: 0,
                        child: Container(
                          decoration: const BoxDecoration(
                            color: Colors.black,
                            shape: BoxShape.circle,
                          ),
                          padding: const EdgeInsets.all(5),
                          child: const Icon(Icons.camera_alt,
                              color: Colors.white, size: 20),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 10),
              Text(
                userName,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              if (userEmail.isNotEmpty) ...[
                const SizedBox(height: 4),
                Text(
                  userEmail,
                  style: TextStyle(color: Colors.grey[600]),
                ),
              ],
              const SizedBox(height: 20),
              // Only Personal Data shows dropdown arrow
              _buildProfileOption(
  icon: Icons.person,
  title: "Personal Data",
  hasDropdown: true,
  onTap: () {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const SignUpScreen()),
    );
  },
),
              _buildProfileOption(
                icon: Icons.history,
                title: "Order History",
                hasDropdown: false,
                onTap: () {},
              ),
              _buildProfileOption(
                icon: Icons.discount,
                title: "Discounts",
                hasDropdown: false,
                onTap: () {},
              ),
              _buildProfileOption(
                icon: Icons.settings,
                title: "Settings",
                hasDropdown: false,
                onTap: () {},
              ),
              const SizedBox(height: 20),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.logout),
                    label: const Text('Logout'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 15),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    onPressed: () => _logout(context),
                  ),
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProfileOption({
    required IconData icon,
    required String title,
    required bool hasDropdown,
    required VoidCallback onTap,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 5),
      child: Card(
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
        child: ListTile(
          leading: Icon(icon, color: Colors.black),
          title: Text(title),
          trailing: hasDropdown 
              ? const Icon(Icons.chevron_right) 
              : null,
          onTap: onTap,
        ),
      ),
    );
  }
}