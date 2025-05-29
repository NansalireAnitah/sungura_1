import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:front_end/screens/login_screen.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'package:front_end/screens/signup.dart';
import 'package:provider/provider.dart';
import 'package:front_end/providers/cart_provider.dart';
import 'package:front_end/providers/auth_provider.dart';
// import 'package:image_picker_web/image_picker_web.dart';
import 'package:universal_html/html.dart' as html;
import 'package:intl/intl.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  bool _isOrderHistoryExpanded = false;

  Future<Map<String, dynamic>?> _fetchUserData() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return null;

    try {
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();
      return userDoc.data();
    } catch (e) {
      debugPrint('Error fetching user data: $e');
      return null;
    }
  }

  Future<List<Map<String, dynamic>>> _fetchOrderHistory() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return [];

    try {
      final querySnapshot = await FirebaseFirestore.instance
          .collection('orders')
          .where('userId', isEqualTo: user.uid)
          .orderBy('createdAt', descending: true)
          .get();

      return querySnapshot.docs
          .map((doc) => {
                ...doc.data(),
                'id': doc.id,
              })
          .toList();
    } catch (e) {
      debugPrint('Error fetching orders: $e');
      throw Exception('Failed to fetch orders: $e');
    }
  }

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
        // final html.File? pickedFile = await ImagePickerWeb.getImageAsFile();
        // if (pickedFile != null) {
        //   imageUrl = await _uploadImageToImgBBWeb(pickedFile);
        // }
      } else {
        final pickedFile =
            await ImagePicker().pickImage(source: ImageSource.gallery);
        if (pickedFile != null) {
          imageUrl = await _uploadImageToImgBBMobile(File(pickedFile.path));
        }
      }

      if (imageUrl != null) {
        final authProvider =
            Provider.of<MyAuthProvider>(context, listen: false);
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

  String _formatPrice(double price) => 'UGX ${price.toStringAsFixed(0)}';

  String _formatDate(DateTime? date) {
    if (date == null) return 'Unknown';
    return DateFormat('MMM dd, yyyy HH:mm').format(date);
  }

  @override
  Widget build(BuildContext context) {
    final firebaseUser = FirebaseAuth.instance.currentUser;

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
      body: FutureBuilder<Map<String, dynamic>?>(
        future: _fetchUserData(),
        builder: (context, userSnapshot) {
          if (userSnapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (userSnapshot.hasError) {
            return const Center(child: Text('Failed to load user data'));
          }

          final userData = userSnapshot.data;
          final userName = userData?['name']?.toString() ??
              firebaseUser?.displayName ??
              'Guest';
          final userEmail = firebaseUser?.email ?? '';
          final userPhotoUrl = userData?['profileImageUrl']?.toString() ??
              firebaseUser?.photoURL;

          return SingleChildScrollView(
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
                              firebaseUser?.photoURL,
                              userData?['profileImageUrl']?.toString(),
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
                  _buildProfileOption(
                    icon: Icons.person,
                    title: "Personal Data",
                    hasDropdown: true,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) =>
                                const SignUpScreen(isEditing: true)),
                      );
                    },
                  ),
                  _buildProfileOption(
                    icon: Icons.history,
                    title: "Order History",
                    hasDropdown: true,
                    onTap: () {
                      setState(() {
                        _isOrderHistoryExpanded = !_isOrderHistoryExpanded;
                      });
                    },
                  ),
                  if (_isOrderHistoryExpanded)
                    FutureBuilder<List<Map<String, dynamic>>>(
                      future: _fetchOrderHistory(),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState ==
                            ConnectionState.waiting) {
                          return const Padding(
                            padding: EdgeInsets.symmetric(horizontal: 20),
                            child: Center(child: CircularProgressIndicator()),
                          );
                        }
                        if (snapshot.hasError) {
                          return Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 20),
                            child: Column(
                              children: [
                                Text(
                                    'Failed to load order history: ${snapshot.error}'),
                                const SizedBox(height: 10),
                                ElevatedButton(
                                  onPressed: () => setState(() {}),
                                  child: const Text('Retry'),
                                ),
                              ],
                            ),
                          );
                        }
                        final orders = snapshot.data ?? [];
                        if (orders.isEmpty) {
                          return const Padding(
                            padding: EdgeInsets.symmetric(horizontal: 20),
                            child: Text('No orders found'),
                          );
                        }
                        return Column(
                          children: orders.map((order) {
                            final items = (order['items'] as List<dynamic>?)
                                    ?.cast<Map<String, dynamic>>() ??
                                [];
                            final total =
                                (order['total'] as num?)?.toDouble() ?? 0.0;
                            final createdAt =
                                (order['createdAt'] as Timestamp?)?.toDate();
                            final orderId =
                                order['id']?.toString() ?? 'Unknown';
                            final deliveryMethod =
                                order['deliveryMethod']?.toString() ??
                                    'Unknown';
                            final location = order['location'] != null
                                ? order['location']['address']?.toString() ??
                                    'N/A'
                                : 'Take Away';
                            final status =
                                order['status']?.toString() ?? 'Unknown';

                            return Card(
                              elevation: 2,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                              margin: const EdgeInsets.symmetric(
                                  horizontal: 20, vertical: 5),
                              child: Padding(
                                padding: const EdgeInsets.all(16),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(
                                          'Order #${orderId.substring(0, 8)}',
                                          style: const TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 16),
                                        ),
                                        Chip(
                                          label: Text(
                                            status,
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontSize: 12,
                                            ),
                                          ),
                                          backgroundColor:
                                              _getStatusColor(status),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      'Status: $status',
                                      style: TextStyle(
                                        fontWeight: FontWeight.w500,
                                        color: Colors.grey[800],
                                      ),
                                    ),
                                    Text(
                                      'Date: ${_formatDate(createdAt)}',
                                      style: TextStyle(color: Colors.grey[600]),
                                    ),
                                    Text(
                                      'Total: ${_formatPrice(total)}',
                                      style: TextStyle(color: Colors.grey[600]),
                                    ),
                                    Text(
                                      'Location: $location',
                                      style: TextStyle(color: Colors.grey[600]),
                                    ),
                                    const SizedBox(height: 12),
                                    const Text(
                                      'Items:',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 14,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    ...items.map((item) {
                                      final itemName =
                                          item['name']?.toString() ?? 'Unknown';
                                      final quantity =
                                          item['quantity'] as int? ?? 1;
                                      final price =
                                          (item['price'] as num?)?.toDouble() ??
                                              0.0;
                                      return Padding(
                                        padding: const EdgeInsets.only(
                                            left: 8, bottom: 4),
                                        child: Row(
                                          children: [
                                            ClipRRect(
                                              borderRadius:
                                                  BorderRadius.circular(8),
                                              child: Image.network(
                                                item['image']?.toString() ??
                                                    'https://via.placeholder.com/50',
                                                width: 50,
                                                height: 50,
                                                fit: BoxFit.cover,
                                                errorBuilder: (context, error,
                                                    stackTrace) {
                                                  return const Icon(
                                                      Icons.fastfood,
                                                      size: 50);
                                                },
                                              ),
                                            ),
                                            const SizedBox(width: 12),
                                            Expanded(
                                              child: Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: [
                                                  Text(
                                                    '$itemName x$quantity',
                                                    style: TextStyle(
                                                        color:
                                                            Colors.grey[700]),
                                                  ),
                                                  Text(
                                                    _formatPrice(
                                                        price * quantity),
                                                    style: TextStyle(
                                                        color:
                                                            Colors.green[700]),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ],
                                        ),
                                      );
                                    }),
                                  ],
                                ),
                              ),
                            );
                          }).toList(),
                        );
                      },
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
          );
        },
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return Colors.orange;
      case 'processing':
        return Colors.blue;
      case 'delivered':
        return Colors.green;
      default:
        return Colors.grey;
    }
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
              ? Icon(title == "Order History" && _isOrderHistoryExpanded
                  ? Icons.expand_less
                  : Icons.expand_more)
              : null,
          onTap: onTap,
        ),
      ),
    );
  }
}
