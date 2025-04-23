import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart' hide Order;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/auth_provider.dart';
import '../providers/admin_user_provider.dart';
import '../providers/product_provider.dart';
import '../providers/order_provider.dart';
import '../models/user_model.dart';
import '../models/product_model.dart';
import '../models/order_model.dart';
import 'add_product_screen.dart';
import 'order_detail_screen.dart';

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

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadInitialData());
  }

  Future<void> _loadInitialData() async {
    try {
      await Future.wait([
        Provider.of<AdminUserProvider>(context, listen: false).fetchAllUsers(),
        Provider.of<ProductProvider>(context, listen: false).fetchProducts(),
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard'),
      ),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            const DrawerHeader(
              decoration: BoxDecoration(color: Color.fromARGB(255, 124, 64, 235)),
              child: Text('Admin Menu',
                  style: TextStyle(color: Colors.white, fontSize: 24)),
            ),
            ListTile(
              leading: const Icon(Icons.dashboard),
              title: const Text('Overview'),
              selected: _selectedIndex == 0,
              onTap: () => _onDrawerItemSelected(0),
            ),
            ListTile(
              leading: const Icon(Icons.people),
              title: const Text('Users'),
              selected: _selectedIndex == 1,
              onTap: () => _onDrawerItemSelected(1),
            ),
            ListTile(
              leading: const Icon(Icons.shopping_bag),
              title: const Text('Orders'),
              selected: _selectedIndex == 2,
              onTap: () => _onDrawerItemSelected(2),
            ),
            ListTile(
              leading: const Icon(Icons.fastfood),
              title: const Text('Products'),
              selected: _selectedIndex == 3,
              onTap: () => _onDrawerItemSelected(3),
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.refresh),
              title: const Text('Refresh Data'),
              onTap: () {
                Navigator.pop(context);
                _loadInitialData();
              },
            ),
            ListTile(
              leading: const Icon(Icons.logout),
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
              child: const Icon(Icons.add),
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
      default:
        return _buildOverviewTab();
    }
  }

  Widget _buildOverviewTab() {
    return FutureBuilder(
      future: _fetchDashboardStats(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }

        final stats = snapshot.data ?? {};
        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
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
          ),
        );
      },
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
            : users.where((user) {
                final emailMatch =
                    user.email.toLowerCase().contains(_userSearchQuery.toLowerCase());
                final nameMatch = user.name
                        ?.toLowerCase()
                        .contains(_userSearchQuery.toLowerCase()) ??
                    false;
                return emailMatch || nameMatch;
              }).toList();

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
                onChanged: (value) => setState(() => _userSearchQuery = value),
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
    return StreamBuilder<List<Order>>(
      stream: Provider.of<OrderProvider>(context, listen: false).getOrdersStream(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }

        final orders = snapshot.data ?? [];
        if (orders.isEmpty) {
          return const Center(child: Text('No orders found'));
        }

        final filteredOrders = _currentOrderFilter == 'All'
            ? orders
            : orders.where((o) => o.status == _currentOrderFilter).toList();

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
                      onSelected: (selected) => setState(() =>
                          _currentOrderFilter = selected ? status : 'All'),
                    ),
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: filteredOrders.length,
                itemBuilder: (context, index) => OrderListItem(
                  order: filteredOrders[index],
                  onStatusChange: (newStatus) {
                    Provider.of<OrderProvider>(context, listen: false)
                        .updateOrderStatus(filteredOrders[index].id, newStatus);
                  },
                ),
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
                .where((p) =>
                    p.name.toLowerCase().contains(_productSearchQuery.toLowerCase()))
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
                onChanged: (value) =>
                    setState(() => _productSearchQuery = value),
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

  Widget _buildStatCard(String title, String value, IconData icon) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Icon(icon, color: const Color.fromARGB(255, 238, 153, 27)),
                Text(value,
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              ],
            ),
            const SizedBox(height: 8),
            Text(title, style: const TextStyle(color: Colors.grey)),
          ],
        ),
      ),
    );
  }

  Widget _buildRecentSection(String title, Widget content) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        content,
      ],
    );
  }

  Widget _buildRecentUsers() {
    return Consumer<AdminUserProvider>(
      builder: (context, provider, _) {
        final users = provider.users.take(5).toList();
        return Card(
          child: Padding(
            padding: const EdgeInsets.all(8),
            child: Column(
              children: users
                  .map((user) => ListTile(
                        leading: const CircleAvatar(child: Icon(Icons.person)),
                        title: Text(user.name ?? 'No name'),
                        subtitle: Text(user.email),
                        trailing: Text(user.role),
                      ))
                  .toList(),
            ),
          ),
        );
      },
    );
  }

  Widget _buildRecentOrders() {
    return StreamBuilder<List<Order>>(
      stream: Provider.of<OrderProvider>(context, listen: false).getOrdersStream(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }

        final orders = snapshot.data?.take(5).toList() ?? [];
        if (orders.isEmpty) {
          return const Center(child: Text('No recent orders'));
        }
        return Card(
          child: Padding(
            padding: const EdgeInsets.all(8),
            child: Column(
              children: orders
                  .map((order) => ExpansionTile(
                        leading: const Icon(Icons.shopping_bag, color: Colors.blue),
                        title: Text('Order #${order.id.substring(0, 8)}'),
                        subtitle:
                            Text('UGX ${order.total.toStringAsFixed(0)} - ${order.userName}'),
                        trailing: Chip(
                          label: Text(order.status),
                          backgroundColor:
                              _getStatusColor(order.status).withOpacity(0.2),
                          labelStyle:
                              TextStyle(color: _getStatusColor(order.status)),
                        ),
                        children: [
                          ListTile(
                            title: Text('Contact: ${order.phone}'),
                            subtitle: order.location != null
                                ? Text('Delivery to: ${order.location}')
                                : null,
                          ),
                          ...order.items
                              .map((item) => ListTile(
                                    leading: item.image.isNotEmpty
                                        ? SizedBox(
                                            width: 40,
                                            height: 40,
                                            child: Image.network(
                                              item.image,
                                              fit: BoxFit.cover,
                                              loadingBuilder: (context, child,
                                                  loadingProgress) {
                                                if (loadingProgress == null) {
                                                  return child;
                                                }
                                                return const Center(
                                                    child:
                                                        CircularProgressIndicator());
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
                                  ))
                              .toList(),
                        ],
                      ))
                  .toList(),
            ),
          ),
        );
      },
    );
  }

  Future<Map<String, dynamic>> _fetchDashboardStats() async {
    try {
      final users =
          await FirebaseFirestore.instance.collection('users').count().get();
      final orders =
          await FirebaseFirestore.instance.collection('orders').count().get();
      final products =
          await FirebaseFirestore.instance.collection('products').count().get();

      final revenueSnapshot =
          await FirebaseFirestore.instance.collection('orders').get();
      final revenue = revenueSnapshot.docs.fold<double>(0, (sum, doc) {
        return sum + (doc.data()['total'] as num).toDouble();
      });

      return {
        'users': users.count,
        'orders': orders.count,
        'products': products.count,
        'revenue': revenue,
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
      Navigator.pushReplacementNamed(context, '/login');
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

class UserListItem extends StatelessWidget {
  final UserModel user;
  final String? currentUserId;

  const UserListItem({super.key, required this.user, this.currentUserId});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: const CircleAvatar(child: Icon(Icons.person)),
        title: Text(user.name ?? 'No name'),
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
                itemBuilder: (context) => [
                  const PopupMenuItem(
                    value: 'make_admin',
                    child: Text('Make Admin'),
                  ),
                  const PopupMenuItem(
                    value: 'make_user',
                    child: Text('Make Regular User'),
                  ),
                  const PopupMenuItem(
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

    if (confirmed == true) {
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
      margin: const EdgeInsets.only(bottom: 8),
      child: InkWell(
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
                  Text('Order #${order.id.substring(0, 8)}',
                      style: const TextStyle(fontWeight: FontWeight.bold)),
                  Text(DateFormat('MMM dd, yyyy').format(order.createdAt)),
                ],
              ),
              const SizedBox(height: 8),
              Text('Customer: ${order.userName}',
                  style: const TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Text('Contact: ${order.phone}'),
              if (order.location != null) ...[
                const SizedBox(height: 8),
                Text('Delivery to: ${order.location}'),
              ],
              const SizedBox(height: 8),
              Text('Total: UGX ${order.total.toStringAsFixed(0)}',
                  style: const TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              const Text('Items:', style: TextStyle(fontWeight: FontWeight.bold)),
              ...order.items.map((item) => Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Row(
                      children: [
                        item.image.isNotEmpty
                            ? SizedBox(
                                width: 50,
                                height: 50,
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
                                        size: 50);
                                  },
                                ),
                              )
                            : const SizedBox(
                                width: 50,
                                height: 50,
                                child: Icon(Icons.image, size: 50)),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(item.name, style: const TextStyle(fontSize: 16)),
                              Text(
                                  'UGX ${item.price.toStringAsFixed(0)} x ${item.quantity}',
                                  style: const TextStyle(color: Colors.grey)),
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
                      style: TextStyle(color: _getStatusColor(order.status)),
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
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
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
        borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
        child: Container(
          color: Colors.grey[100],
          child: _buildImageContent(),
        ),
      ),
    );
  }

  Widget _buildImageContent() {
    return Image.network(
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
          print('Admin ProductCard image error for ${product.imageUrl}: $error');
        }
        return Image.network(
          'https://via.placeholder.com/150',
          fit: BoxFit.cover,
        );
      },
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
            style: TextStyle(
              color: Colors.green[700],
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
                    icon: const Icon(Icons.delete, size: 20, color: Colors.red),
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