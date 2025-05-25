import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart' as firestore;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:front_end/screens/login_screen.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:image_picker_web/image_picker_web.dart';
import 'package:universal_html/html.dart' as html;
import '../providers/auth_provider.dart';
import '../providers/admin_user_provider.dart';
import '../providers/product_provider.dart';
import '../providers/order_provider.dart';
import '../models/user_model.dart';
import '../models/product_model.dart';
import '../models/order_model.dart';
import 'add_product_screen.dart';
import 'order_detail_screen.dart';
import 'carousel_management_screen.dart';

class AdminDashboard extends StatefulWidget {
  const AdminDashboard({super.key});

  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {
  final List<String> _orderStatusFilters = [
    'All',
    'Pending',
    'Processing',
    'Completed',
    'Cancelled'
  ];
  String _currentOrderFilter = 'All';
  String _productSearchQuery = '';
  String _userSearchQuery = '';
  int _selectedIndex = 0;

  final _formKey = GlobalKey<FormState>();
  final _labelController = TextEditingController();
  bool _isVisible = true;
  bool _isUploading = false;
  final String _imgbbApiKey = 'a76d491b3f50093fddaf42dcfaedc1c6';

  @override
  void initState() {
    super.initState();
    _loadInitialData();
  }

  Future<void> _loadInitialData() async {
    try {
      await Future.wait([
        Provider.of<AdminUserProvider>(context, listen: false).fetchAllUsers(),
        Provider.of<ProductProvider>(context, listen: false).fetchProducts(),
        Provider.of<OrderProvider>(context, listen: false).fetchOrders(),
      ]);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading data: $e')),
        );
      }
    }
  }

  void _onDrawerItemSelected(int index) {
    setState(() {
      _selectedIndex = index;
    });
    Navigator.pop(context);
  }

  Future<String?> _uploadImageToImgBBMobile(File imageFile) async {
    final uri = Uri.parse('https://api.imgbb.com/1/upload?key=$_imgbbApiKey');
    final request = http.MultipartRequest('POST', uri)
      ..files.add(await http.MultipartFile.fromPath('image', imageFile.path));

    final response = await request.send();
    final responseData = await response.stream.bytesToString();
    final jsonData = jsonDecode(responseData);

    if (response.statusCode != 200 || !jsonData['success']) {
      throw Exception('Failed to upload image: ${jsonData['error']?['message'] ?? 'Unknown error'}');
    }

    return jsonData['data']['url'];
  }

  Future<String?> _uploadImageToImgBBWeb(html.File imageFile) async {
    final uri = Uri.parse('https://api.imgbb.com/1/upload?key=$_imgbbApiKey');
    final reader = html.FileReader();
    reader.readAsArrayBuffer(imageFile);
    await reader.onLoad.first;

    final bytes = reader.result as List<int>;
    final base64Image = base64Encode(bytes);

    final response = await http.post(
      uri,
      body: {'image': base64Image},
    );

    final jsonData = jsonDecode(response.body);
    if (response.statusCode != 200 || !jsonData['success']) {
      throw Exception('Failed to upload image: ${jsonData['error']?['message'] ?? 'Unknown error'}');
    }

    return jsonData['data']['url'];
  }

  Future<void> _uploadCarouselImage() async {
    if (_formKey.currentState?.validate() ?? false) {
      try {
        setState(() {
          _isUploading = true;
        });

        String? imageUrl;
        if (kIsWeb) {
          final html.File? pickedFile = await ImagePickerWeb.getImageAsFile();
          if (pickedFile != null) {
            final fileSizeMB = pickedFile.size / (1024 * 1024);
            if (fileSizeMB > 32) {
              throw Exception('File size exceeds 32MB limit');
            }
            imageUrl = await _uploadImageToImgBBWeb(pickedFile);
          }
        } else {
          final pickedFile = await ImagePicker().pickImage(source: ImageSource.gallery);
          if (pickedFile != null) {
            File file = File(pickedFile.path);
            final fileSizeMB = file.lengthSync() / (1024 * 1024);
            if (fileSizeMB > 32) {
              throw Exception('File size exceeds 32MB limit');
            }
            imageUrl = await _uploadImageToImgBBMobile(file);
          }
        }

        if (imageUrl != null) {
          await firestore.FirebaseFirestore.instance.collection('carousel_items').add({
            'imageUrl': imageUrl,
            'label': _labelController.text,
            'isVisible': _isVisible,
            'createdAt': firestore.FieldValue.serverTimestamp(),
          });

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Carousel image added: ${_labelController.text}')),
          );

          _labelController.clear();
          setState(() {
            _isVisible = true;
          });
        } else {
          throw Exception('No image selected');
        }
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to upload image: $e')),
        );
      } finally {
        setState(() {
          _isUploading = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _labelController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Dashboard'),
        backgroundColor: Colors.white,
        elevation: 2,
        centerTitle: true,
      ),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            DrawerHeader(
              decoration: const BoxDecoration(color: Color(0xFFFFC107)),
              child: Text(
                'Admin Menu',
                style: TextStyle(color: Colors.black, fontSize: 24),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.dashboard, color: Colors.black),
              title: const Text('Overview'),
              selected: _selectedIndex == 0,
              onTap: () => _onDrawerItemSelected(0),
            ),
            ListTile(
              leading: const Icon(Icons.people, color: Colors.black),
              title: const Text('Users'),
              selected: _selectedIndex == 1,
              onTap: () => _onDrawerItemSelected(1),
            ),
            ListTile(
              leading: const Icon(Icons.shopping_bag, color: Colors.black),
              title: const Text('Orders'),
              selected: _selectedIndex == 2,
              onTap: () => _onDrawerItemSelected(2),
            ),
            ListTile(
              leading: const Icon(Icons.fastfood, color: Colors.black),
              title: const Text('Products'),
              selected: _selectedIndex == 3,
              onTap: () => _onDrawerItemSelected(3),
            ),
            ListTile(
              leading: const Icon(Icons.slideshow, color: Colors.black),
              title: const Text('Carousel'),
              selected: _selectedIndex == 4,
              onTap: () => _onDrawerItemSelected(4),
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.refresh, color: Colors.black),
              title: const Text('Refresh Data'),
              onTap: () {
                Navigator.pop(context);
                _loadInitialData();
              },
            ),
            ListTile(
              leading: const Icon(Icons.logout, color: Colors.red),
              title: const Text('Logout'),
              onTap: () {
                Navigator.pop(context);
                _confirmLogout();
              },
            ),
          ],
        ),
      ),
      body: _buildContent(),
      floatingActionButton: _selectedIndex == 3
          ? FloatingActionButton(
              onPressed: () => _navigateToAddProduct(context),
              backgroundColor: const Color(0xFFFFC107),
              child: const Icon(Icons.add, color: Colors.black),
            )
          : null,
    );
  }

  Widget _buildContent() {
    switch (_selectedIndex) {
      case 0:
        return _buildOverviewTab();
      case 1:
        return _buildUsersTab();
      case 2:
        return _buildOrdersTab();
      case 3:
        return _buildProductsTab();
      case 4:
        return _buildCarouselTab();
      default:
        return _buildOverviewTab();
    }
  }

  Widget _buildOverviewTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          const AdminCarousel(),
          const SizedBox(height: 24),
          FutureBuilder<Map<String, dynamic>>(
            future: _fetchDashboardStats(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (snapshot.hasError) {
                return Center(child: Text('Error: ${snapshot.error}'));
              }

              final stats = snapshot.data ?? {};
              return Column(
                children: [
                  GridView.count(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisCount: 2,
                    childAspectRatio: 1.2,
                    crossAxisSpacing: 15,
                    mainAxisSpacing: 15,
                    children: [
                      _buildStatCard('Total Users',
                          stats['users']?.toString() ?? '0', Icons.people),
                      _buildStatCard('Total Orders',
                          stats['orders']?.toString() ?? '0', Icons.shopping_bag),
                      _buildStatCard('Products',
                          stats['products']?.toString() ?? '0', Icons.fastfood),
                      _buildStatCard(
                          'Revenue',
                          'UGX ${stats['revenue']?.toStringAsFixed(0) ?? '0'}',
                          Icons.attach_money),
                    ],
                  ),
                  const SizedBox(height: 24),
                  _buildRecentSection('Recent Users', _buildRecentUsers()),
                  const SizedBox(height: 24),
                  _buildRecentSection('Recent Orders', _buildRecentOrders()),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildUsersTab() {
    return Consumer2<AdminUserProvider, MyAuthProvider>(
      builder: (context, userProvider, authProvider, _) {
        if (userProvider.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        final users = userProvider.users;
        if (users.isEmpty) {
          return const Center(child: Text('No users found'));
        }

        final filteredUsers = _userSearchQuery.isEmpty
            ? users
            : users
                .where((user) =>
                    user.email
                        .toLowerCase()
                        .contains(_userSearchQuery.toLowerCase()) ||
                    (user.name
                            ?.toLowerCase()
                            .contains(_userSearchQuery.toLowerCase()) ??
                        false))
                .toList();

        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: TextField(
                decoration: InputDecoration(
                  hintText: 'Search users...',
                  prefixIcon: const Icon(Icons.search),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                onChanged: (value) {
                  setState(() => _userSearchQuery = value);
                },
              ),
            ),
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: filteredUsers.length,
                itemBuilder: (context, index) => UserListItem(
                  user: filteredUsers[index],
                  currentUserId: authProvider.user?.uid,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildOrdersTab() {
    return Consumer<OrderProvider>(
      builder: (context, orderProvider, _) {
        return Column(
          children: [
            SizedBox(
              height: 50,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                children: _orderStatusFilters.map((status) {
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ChoiceChip(
                      label: Text(status),
                      selected: _currentOrderFilter == status,
                      selectedColor: const Color(0xFFFFC107),
                      labelStyle: TextStyle(
                        color: _currentOrderFilter == status
                            ? Colors.black
                            : Colors.grey,
                      ),
                      onSelected: (selected) {
                        setState(() =>
                            _currentOrderFilter = selected ? status : 'All');
                      },
                    ),
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: Builder(
                builder: (context) {
                  if (orderProvider.isLoading) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (orderProvider.error != null) {
                    return Center(child: Text('Error: ${orderProvider.error}'));
                  }

                  final orders = orderProvider.orders ?? [];
                  if (orders.isEmpty) {
                    return const Center(child: Text('No orders found'));
                  }

                  final filteredOrders = _currentOrderFilter == 'All'
                      ? orders
                      : orders
                          .where((o) => o.status == _currentOrderFilter)
                          .toList();

                  return ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: filteredOrders.length,
                    itemBuilder: (context, index) => OrderListItem(
                      order: filteredOrders[index],
                      onStatusChange: (newStatus) {
                        orderProvider.updateOrderStatus(
                            filteredOrders[index].id, newStatus);
                      },
                    ),
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildProductsTab() {
    return Consumer<ProductProvider>(
      builder: (context, provider, _) {
        if (provider.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }
        if (provider.products.isEmpty) {
          return const Center(child: Text('No products found'));
        }

        final filteredProducts = _productSearchQuery.isEmpty
            ? provider.products
            : provider.products
                .where((p) => p.name
                    .toLowerCase()
                    .contains(_productSearchQuery.toLowerCase()))
                .toList();

        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: TextField(
                decoration: InputDecoration(
                  hintText: 'Search products...',
                  prefixIcon: const Icon(Icons.search),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                onChanged: (value) {
                  setState(() => _productSearchQuery = value);
                },
              ),
            ),
            Expanded(
              child: GridView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  childAspectRatio: 0.65,
                  crossAxisSpacing: 15,
                  mainAxisSpacing: 15,
                ),
                itemCount: filteredProducts.length,
                itemBuilder: (context, index) => ProductCard(
                  product: filteredProducts[index],
                  onEdit: () =>
                      _navigateToEditProduct(context, filteredProducts[index]),
                  onDelete: () =>
                      _confirmDeleteProduct(context, filteredProducts[index]),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildCarouselTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Add Carousel Image',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 10),
          Card(
            elevation: 2,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextFormField(
                      controller: _labelController,
                      decoration: const InputDecoration(
                        labelText: 'Label',
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Label is required';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 10),
                    SwitchListTile(
                      title: const Text('Visible'),
                      value: _isVisible,
                      onChanged: (value) {
                        setState(() {
                          _isVisible = value;
                        });
                      },
                    ),
                    const SizedBox(height: 10),
                    ElevatedButton(
                      onPressed: _isUploading ? null : _uploadCarouselImage,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFFFC107),
                        foregroundColor: Colors.black,
                        padding:
                            const EdgeInsets.symmetric(vertical: 15, horizontal: 20),
                      ),
                      child: Text(_isUploading ? 'Uploading...' : 'Upload Image'),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Recent Carousel Items',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
              ),
              TextButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => const CarouselManagementScreen()),
                  );
                },
                child: const Text(
                  'Manage All',
                  style: TextStyle(color: Color(0xFFFFC107)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          _buildCarouselPreview(),
        ],
      ),
    );
  }

  Widget _buildCarouselPreview() {
    return StreamBuilder<firestore.QuerySnapshot>(
      stream: firestore.FirebaseFirestore.instance
          .collection('carousel_items')
          .orderBy('createdAt', descending: true)
          .limit(5)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }

        var items = snapshot.data?.docs ?? [];
        if (items.isEmpty) {
          return const Center(child: Text('No carousel items added.'));
        }

        return SizedBox(
          height: 100,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: items.length,
            itemBuilder: (context, index) {
              var item = items[index];
              return Padding(
                padding: const EdgeInsets.only(right: 10),
                child: Column(
                  children: [
                    SizedBox(
                      width: 80,
                      height: 60,
                      child: Image.network(
                        item['imageUrl'],
                        fit: BoxFit.cover,
                        loadingBuilder: (context, child, loadingProgress) {
                          if (loadingProgress == null) return child;
                          return const Center(child: CircularProgressIndicator());
                        },
                        errorBuilder: (context, error, stackTrace) {
                          if (kDebugMode) {
                            print('Carousel image error for ${item['imageUrl']}: $error');
                          }
                          return const Icon(Icons.image_not_supported, size: 50);
                        },
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      item['label'],
                      style: const TextStyle(fontSize: 12),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Icon(icon, color: const Color(0xFFFFC107)),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              title,
              style: TextStyle(color: Colors.grey[600]),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecentSection(String title, Widget content) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        Card(
          elevation: 2,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          child: content,
        ),
      ],
    );
  }

  Widget _buildRecentUsers() {
    return Consumer<AdminUserProvider>(
      builder: (context, provider, _) {
        final users = provider.users.take(5).toList();
        if (users.isEmpty) {
          return const Padding(
            padding: EdgeInsets.all(16),
            child: Text('No recent users'),
          );
        }
        return Padding(
          padding: const EdgeInsets.all(8),
          child: Column(
            children: users
                .map((user) => ListTile(
                      leading: const CircleAvatar(
                        backgroundColor: Color(0xFFFFC107),
                        child: Icon(Icons.person, color: Colors.black),
                      ),
                      title: Text(user.name),
                      subtitle: Text(user.email),
                      trailing: Text(user.role),
                    ))
                .toList(),
          ),
        );
      },
    );
  }

  Widget _buildRecentOrders() {
    return Consumer<OrderProvider>(
      builder: (context, provider, _) {
        final orders = provider.orders?.take(5).toList() ?? [];
        if (provider.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }
        if (provider.error != null) {
          return Center(child: Text('Error: ${provider.error}'));
        }
        if (orders.isEmpty) {
          return const Padding(
            padding: EdgeInsets.all(16),
            child: Text('No recent orders'),
          );
        }
        return Padding(
          padding: const EdgeInsets.all(8),
          child: Column(
            children: orders
                .map((order) => ExpansionTile(
                      leading: const Icon(
                        Icons.shopping_bag,
                        color: Color(0xFFFFC107),
                      ),
                      title: Text('Order #${order.id.substring(0, 8)}'),
                      subtitle: Text(
                        'UGX ${order.total.toStringAsFixed(0)} - ${order.userName}',
                      ),
                      trailing: Chip(
                        label: Text(order.status),
                        backgroundColor:
                            _getStatusColor(order.status).withOpacity(0.2),
                        labelStyle:
                            TextStyle(color: _getStatusColor(order.status)),
                      ),
                      children: [
                        ListTile(
                          title: Text('Customer: ${order.userName}'),
                          subtitle: Text('Contact: ${order.phone}'),
                        ),
                        if (order.location != null)
                          ListTile(
                            title: Text('Delivery to: ${order.location}'),
                          ),
                        ...order.items.map((item) => ListTile(
                              leading: item.image.isNotEmpty
                                  ? SizedBox(
                                      width: 40,
                                      height: 40,
                                      child: Image.network(
                                        item.image,
                                        fit: BoxFit.cover,
                                        loadingBuilder:
                                            (context, child, loadingProgress) {
                                          if (loadingProgress == null) {
                                            return child;
                                          }
                                          return const Center(
                                              child: CircularProgressIndicator());
                                        },
                                        errorBuilder:
                                            (context, error, stackTrace) {
                                          if (kDebugMode) {
                                            print(
                                                'Order item image error for ${item.image}: $error');
                                          }
                                          return const Icon(
                                              Icons.image_not_supported,
                                              size: 40);
                                        },
                                      ),
                                    )
                                  : const SizedBox(
                                      width: 40,
                                      height: 40,
                                      child: Icon(Icons.image, size: 40)),
                              title: Text(item.name),
                              subtitle: Text(
                                  'UGX ${item.price.toStringAsFixed(0)} x ${item.quantity}'),
                            )),
                      ],
                    ))
                .toList(),
          ),
        );
      },
    );
  }

  Future<Map<String, dynamic>> _fetchDashboardStats() async {
    try {
      final usersSnapshot =
          await firestore.FirebaseFirestore.instance.collection('users').get();
      final productsSnapshot =
          await firestore.FirebaseFirestore.instance.collection('products').get();
      final ordersSnapshot =
          await firestore.FirebaseFirestore.instance.collection('orders').get();

      return {
        'users': usersSnapshot.docs.length,
        'orders': ordersSnapshot.docs.length,
        'products': productsSnapshot.docs.length,
        'revenue': ordersSnapshot.docs.fold<double>(
            0, (sum, doc) => sum + ((doc.data()['total'] as num?)?.toDouble() ?? 0)),
      };
    } catch (e) {
      throw Exception('Failed to load stats: $e');
    }
  }

  Future<void> _confirmLogout() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Logout'),
        content: const Text('Are you sure you want to logout?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Logout', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      await Provider.of<MyAuthProvider>(context, listen: false).logout();
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const LoginScreen()),
      );
    }
  }

  void _navigateToAddProduct(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const AddProductScreen()),
    ).then((_) {
      if (mounted) {
        Provider.of<ProductProvider>(context, listen: false).fetchProducts();
      }
    });
  }

  void _navigateToEditProduct(BuildContext context, Product product) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => AddProductScreen(product: product)),
    ).then((_) {
      if (mounted) {
        Provider.of<ProductProvider>(context, listen: false).fetchProducts();
      }
    });
  }

  Future<void> _confirmDeleteProduct(
      BuildContext context, Product product) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Product'),
        content: Text('Delete ${product.name} permanently?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      try {
        await Provider.of<ProductProvider>(context, listen: false)
            .deleteProduct(product.id);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Deleted ${product.name}')),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to delete: $e')),
        );
      }
    }
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return Colors.orange;
      case 'processing':
        return Colors.blue;
      case 'completed':
        return Colors.green;
      case 'cancelled':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }
}

class AdminCarousel extends StatelessWidget {
  const AdminCarousel({super.key});

  double getViewportFraction(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    if (width < 600) return 0.85;
    if (width < 1200) return 0.6;
    return 0.4;
  }

  double getCarouselHeight(BuildContext context) {
    final height = MediaQuery.of(context).size.height;
    return height < 600 ? height * 0.3 : height * 0.4;
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: StreamBuilder<firestore.QuerySnapshot>(
        stream: firestore.FirebaseFirestore.instance
            .collection('carousel_items')
            .where('isVisible', isEqualTo: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return const Center(child: Text('Error loading carousel'));
          }
          final items = snapshot.data?.docs ?? [];
          if (items.isEmpty) {
            return const Center(child: Text('No carousel items'));
          }
          return CarouselSlider(
            items: items.map((item) {
              return Container(
                margin: const EdgeInsets.all(6.0),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8.0),
                  image: DecorationImage(
                    image: NetworkImage(item['imageUrl']),
                    fit: BoxFit.cover,
                    onError: (exception, stackTrace) {
                      if (kDebugMode) {
                        print('Carousel image error for ${item['imageUrl']}: $exception');
                      }
                    },
                  ),
                ),
                child: Align(
                  alignment: Alignment.bottomCenter,
                  child: Container(
                    color: Colors.black.withOpacity(0.5),
                    padding: const EdgeInsets.all(8.0),
                    child: Text(
                      item['label'],
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16.0,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
            options: CarouselOptions(
              height: getCarouselHeight(context),
              aspectRatio: 16 / 9,
              viewportFraction: getViewportFraction(context),
              initialPage: 0,
              enableInfiniteScroll: true,
              reverse: false,
              autoPlay: true,
              autoPlayInterval: const Duration(seconds: 3),
              autoPlayAnimationDuration: const Duration(milliseconds: 800),
              autoPlayCurve: Curves.fastOutSlowIn,
              enlargeCenterPage: true,
              scrollDirection: Axis.horizontal,
            ),
          );
        },
      ),
    );
  }
}

class UserListItem extends StatelessWidget {
  final UserModel user;
  final String? currentUserId;

  const UserListItem({super.key, required this.user, this.currentUserId});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: const CircleAvatar(
          backgroundColor: Color(0xFFFFC107),
          child: Icon(Icons.person, color: Colors.black),
        ),
        title: Text(user.name),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(user.email),
            Text('Role: ${user.role}'),
          ],
        ),
        trailing: currentUserId != user.uid
            ? PopupMenuButton<String>(
                onSelected: (value) => _handleUserAction(context, value, user),
                itemBuilder: (context) => const [
                  PopupMenuItem(
                    value: 'make_admin',
                    child: Text('Make Admin'),
                  ),
                  PopupMenuItem(
                    value: 'make_user',
                    child: Text('Make Regular User'),
                  ),
                  PopupMenuItem(
                    value: 'delete',
                    child: Text('Delete', style: TextStyle(color: Colors.red)),
                  ),
                ],
              )
            : null,
      ),
    );
  }

  Future<void> _handleUserAction(
      BuildContext context, String action, UserModel user) async {
    final adminProvider =
        Provider.of<AdminUserProvider>(context, listen: false);

    try {
      switch (action) {
        case 'make_admin':
          await adminProvider.updateUserRole(user.uid, 'admin');
          break;
        case 'make_user':
          await adminProvider.updateUserRole(user.uid, 'user');
          break;
        case 'delete':
          await _confirmDeleteUser(context, user);
          break;
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }

  Future<void> _confirmDeleteUser(BuildContext context, UserModel user) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete User'),
        content: Text('Delete ${user.email} permanently?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      try {
        await Provider.of<AdminUserProvider>(context, listen: false)
            .deleteUser(user.uid);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Deleted ${user.email}')),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to delete: $e')),
        );
      }
    }
  }
}

class OrderListItem extends StatelessWidget {
  final Order order;
  final Function(String) onStatusChange;

  const OrderListItem({
    super.key,
    required this.order,
    required this.onStatusChange,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      margin: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => OrderDetailScreen(order: order),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Order #${order.id.substring(0, 8)}',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  Text(
                    DateFormat('MMM dd, yyyy').format(order.createdAt),
                    style: TextStyle(color: Colors.grey[600], fontSize: 12),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                'Customer: ${order.userName}',
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 4),
              Text(
                'Contact: ${order.phone}',
                style: TextStyle(color: Colors.grey[700], fontSize: 14),
              ),
              const SizedBox(height: 4),
              Text(
                'Method: ${order.deliveryMethod}',
                style: TextStyle(color: Colors.grey[700], fontSize: 14),
              ),
              if (order.location != null) ...[
                const SizedBox(height: 4),
                Text(
                  'Address: ${order.location}',
                  style: TextStyle(color: Colors.grey[700], fontSize: 14),
                ),
              ],
              const SizedBox(height: 8),
              Text(
                'Total: UGX ${order.total.toStringAsFixed(0)}',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.green,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Items:',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
              ...order.items.map((item) => Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        item.image.isNotEmpty
                            ? SizedBox(
                                width: 40,
                                height: 40,
                                child: Image.network(
                                  item.image,
                                  fit: BoxFit.cover,
                                  loadingBuilder:
                                      (context, child, loadingProgress) {
                                    if (loadingProgress == null) return child;
                                    return const Center(
                                        child: CircularProgressIndicator());
                                  },
                                  errorBuilder: (context, error, stackTrace) {
                                    if (kDebugMode) {
                                      print(
                                          'Order item image error for ${item.image}: $error');
                                    }
                                    return const Icon(
                                        Icons.image_not_supported,
                                        size: 40);
                                  },
                                ),
                              )
                            : const SizedBox(
                                width: 40,
                                height: 40,
                                child: Icon(Icons.image, size: 40)),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                item.name,
                                style: const TextStyle(fontSize: 14),
                              ),
                              Text(
                                'UGX ${item.price.toStringAsFixed(0)} x ${item.quantity}',
                                style: TextStyle(
                                    color: Colors.grey[600], fontSize: 12),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  )),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: _getStatusColor(order.status).withOpacity(0.2),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      order.status,
                      style: TextStyle(
                        color: _getStatusColor(order.status),
                        fontSize: 12,
                      ),
                    ),
                  ),
                  if (order.status == 'Pending')
                    Row(
                      children: [
                        IconButton(
                          icon: const Icon(Icons.check, color: Colors.green),
                          onPressed: () => onStatusChange('Processing'),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close, color: Colors.red),
                          onPressed: () => onStatusChange('Cancelled'),
                        ),
                      ],
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return Colors.orange;
      case 'processing':
        return Colors.blue;
      case 'completed':
        return Colors.green;
      case 'cancelled':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }
}

class ProductCard extends StatelessWidget {
  final Product product;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const ProductCard({
    super.key,
    required this.product,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: onEdit,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildImageSection(),
            _buildProductDetails(),
          ],
        ),
      ),
    );
  }

  Widget _buildImageSection() {
    return AspectRatio(
      aspectRatio: 1,
      child: ClipRRect(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(10)),
        child: Container(
          color: Colors.grey[100],
          child: Image.network(
            product.imageUrl,
            fit: BoxFit.cover,
            loadingBuilder: (context, child, loadingProgress) {
              if (loadingProgress == null) return child;
              return Center(
                child: CircularProgressIndicator(
                  value: loadingProgress.expectedTotalBytes != null
                      ? loadingProgress.cumulativeBytesLoaded /
                          loadingProgress.expectedTotalBytes!
                      : null,
                ),
              );
            },
            errorBuilder: (context, error, stackTrace) {
              if (kDebugMode) {
                print('ProductCard image error for ${product.imageUrl}: $error');
              }
              return Image.network(
                'https://via.placeholder.com/150',
                fit: BoxFit.cover,
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildProductDetails() {
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            product.name,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 4),
          Text(
            'UGX ${product.price.toStringAsFixed(0)}',
            style: const TextStyle(
              color: Color(0xFFFFC107),
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                product.isAvailable ? 'Available' : 'Out of Stock',
                style: TextStyle(
                  color: product.isAvailable ? Colors.green : Colors.red,
                  fontSize: 14,
                ),
              ),
              Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.edit, size: 20),
                    onPressed: onEdit,
                  ),
                  IconButton(
                    icon: const Icon(
                      Icons.delete,
                      size: 20,
                      color: Colors.red,
                    ),
                    onPressed: onDelete,
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}