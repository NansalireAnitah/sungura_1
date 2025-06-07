import 'package:cloud_firestore/cloud_firestore.dart' as firestore;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:front_end/models/notification_model.dart';
import 'package:front_end/providers/notification_provider.dart';

class NotificationScreen extends StatefulWidget {
  const NotificationScreen({super.key});

  @override
  State<NotificationScreen> createState() => _NotificationScreenState();
}

class _NotificationScreenState extends State<NotificationScreen> {
  @override
  void initState() {
    super.initState();
    _loadNotifications();
  }

  Future<void> _loadNotifications() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final snapshot = await firestore.FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('notifications')
          .get();
      final notifications = snapshot.docs
          .map((doc) => AppNotification.fromMap(doc.data()))
          .toList();
      final provider = context.read<NotificationProvider>();
      provider.clearAll(); // Clear local notifications
      for (var notification in notifications) {
        provider.addNotification(notification);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications'),
        centerTitle: true,
        actions: [
          Consumer<NotificationProvider>(
            builder: (context, provider, _) {
              if (provider.notifications.isNotEmpty) {
                return IconButton(
                  icon: const Icon(Icons.delete_sweep),
                  onPressed: () => _confirmClearAll(context),
                  tooltip: 'Clear all',
                );
              }
              return const SizedBox.shrink();
            },
          ),
        ],
      ),
      body: user == null
          ? const Center(child: Text('Please log in to view notifications'))
          : StreamBuilder<firestore.QuerySnapshot>(
              stream: firestore.FirebaseFirestore.instance
                  .collection('users')
                  .doc(user.uid)
                  .collection('notifications')
                  .orderBy('timestamp', descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                }
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Center(child: Text('No notifications yet'));
                }

                final notifications = snapshot.data!.docs
                    .map((doc) => AppNotification.fromMap(doc.data() as Map<String, dynamic>))
                    .toList();

                // Update provider with Firestore data
                final provider = context.read<NotificationProvider>();
                provider.clearAll();
                for (var notification in notifications) {
                  provider.addNotification(notification);
                }

                return RefreshIndicator(
                  onRefresh: _loadNotifications,
                  child: ListView.builder(
                    itemCount: notifications.length,
                    itemBuilder: (context, index) {
                      final notification = notifications[index];
                      return Dismissible(
                        key: Key(notification.id),
                        background: Container(
                          color: Colors.red[200],
                          alignment: Alignment.centerRight,
                          padding: const EdgeInsets.only(right: 16),
                          child: const Icon(Icons.delete, color: Colors.white),
                        ),
                        onDismissed: (_) async {
                          final provider = context.read<NotificationProvider>();
                          provider.deleteNotification(notification.id);
                          await firestore.FirebaseFirestore.instance
                              .collection('users')
                              .doc(user.uid)
                              .collection('notifications')
                              .doc(notification.id)
                              .delete();
                                                },
                        child: Card(
                          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          child: ListTile(
                            contentPadding: const EdgeInsets.all(16),
                            leading: Icon(
                              Icons.notifications,
                              color: notification.isRead
                                  ? Colors.grey
                                  : Theme.of(context).primaryColor,
                            ),
                            title: Text(
                              notification.title,
                              style: TextStyle(
                                fontWeight: notification.isRead ? FontWeight.normal : FontWeight.bold,
                              ),
                            ),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  notification.body,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  _formatDate(notification.timestamp),
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey[600],
                                  ),
                                ),
                              ],
                            ),
                            trailing: notification.items != null
                                ? IconButton(
                                    icon: const Icon(Icons.cancel, color: Colors.red),
                                    onPressed: () => _confirmCancelOrder(context, notification.id),
                                    tooltip: 'Cancel Order',
                                  )
                                : null,
                            onTap: () async {
                              final provider = context.read<NotificationProvider>();
                              provider.markAsRead(notification.id);
                              if (!notification.isRead) {
                                await firestore.FirebaseFirestore.instance
                                    .collection('users')
                                    .doc(user.uid)
                                    .collection('notifications')
                                    .doc(notification.id)
                                    .update({'isRead': true});
                              }
                              if (notification.items != null) {
                                _showOrderDetails(context, notification);
                              }
                            },
                          ),
                        ),
                      );
                    },
                  ),
                );
              },
            ),
    );
  }

  void _showOrderDetails(BuildContext context, AppNotification notification) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(notification.title),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              StreamBuilder<firestore.DocumentSnapshot>(
                stream: firestore.FirebaseFirestore.instance
                    .collection('orders')
                    .doc(notification.id)
                    .snapshots(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (snapshot.hasError) {
                    return const Text('Error fetching order status');
                  }
                  final orderData = snapshot.data?.data() as Map<String, dynamic>?;
                  final status = orderData?['status'] ?? 'Unknown';
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Status: $status',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      Text('Total: UGX ${notification.total?.toStringAsFixed(0) ?? '0'}'),
                      const SizedBox(height: 8),
                      Text('Location: ${notification.location ?? 'N/A'}'),
                      const SizedBox(height: 16),
                      const Text('Items:', style: TextStyle(fontWeight: FontWeight.bold)),
                      if (notification.items != null)
                        ...notification.items!.map(
                          (item) => Padding(
                            padding: const EdgeInsets.symmetric(vertical: 4),
                            child: Text(
                              '${item['name']} x${item['quantity']} - UGX ${(item['price'] * item['quantity']).toStringAsFixed(0)}',
                            ),
                          ),
                        ),
                    ],
                  );
                },
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
          if (notification.items != null)
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                _confirmCancelOrder(context, notification.id);
              },
              child: const Text('Cancel Order', style: TextStyle(color: Colors.red)),
            ),
        ],
      ),
    );
  }

  void _confirmCancelOrder(BuildContext context, String orderId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cancel Order?'),
        content: const Text('Are you sure you want to cancel this order? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('No'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              final user = FirebaseAuth.instance.currentUser;
              if (user != null) {
                try {
                  await firestore.FirebaseFirestore.instance
                      .collection('orders')
                      .doc(orderId)
                      .update({'status': 'cancelled'});
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Order cancelled successfully')),
                  );
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error cancelling order: $e')),
                  );
                }
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Error: Unable to cancel order')),
                );
              }
            },
            child: const Text('Yes', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void _confirmClearAll(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear all notifications?'),
        content: const Text('This will remove all your notifications.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              final user = FirebaseAuth.instance.currentUser;
              if (user != null) {
                final batch = firestore.FirebaseFirestore.instance.batch();
                final snapshot = await firestore.FirebaseFirestore.instance
                    .collection('users')
                    .doc(user.uid)
                    .collection('notifications')
                    .get();
                for (var doc in snapshot.docs) {
                  batch.delete(doc.reference);
                }
                await batch.commit();
              }
              Provider.of<NotificationProvider>(context, listen: false).clearAll();
              Navigator.pop(context);
            },
            child: const Text('Clear', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
  }
}