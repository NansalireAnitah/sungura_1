import 'package:cloud_firestore/cloud_firestore.dart';

class OrderItem {
  final String name;
  final String image;
  final double price;
  final int quantity;

  OrderItem({
    required this.name,
    required this.image,
    required this.price,
    required this.quantity,
  });

  factory OrderItem.fromMap(Map<String, dynamic> map) {
    return OrderItem(
      name: map['name'] as String? ?? 'Unknown Item',
      image: map['image'] as String? ?? '',
      price: (map['price'] as num?)?.toDouble() ?? 0.0,
      quantity: map['quantity'] as int? ?? 1,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'image': image,
      'price': price,
      'quantity': quantity,
    };
  }
}

class Order {
  final String id;
  final String userId;
  final String userName;
  final List<OrderItem> items;
  final double total;
  final String status;
  final DateTime createdAt;
  final String phone;
  final String deliveryMethod;
  final String? location;

  Order({
    required this.id,
    required this.userId,
    required this.userName,
    required this.items,
    required this.total,
    required this.status,
    required this.createdAt,
    required this.phone,
    required this.deliveryMethod,
    this.location,
  });

  factory Order.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;

    // Debug print to see the actual data structure
    print('Order data: $data');

    // Safe parsing of items
    final itemsData = data['items'] as List<dynamic>? ?? [];
    final items = <OrderItem>[];
    for (var item in itemsData) {
      try {
        if (item is Map<String, dynamic>) {
          items.add(OrderItem.fromMap(item));
        }
      } catch (e) {
        print('Error parsing item: $e');
      }
    }

    // Safe parsing of location - handle both String and Map cases
    String? location;
    final locationData = data['location'];
    if (locationData is String) {
      location = locationData;
    } else if (locationData is Map<String, dynamic>) {
      // If location is stored as a map, extract relevant fields
      // Adjust these fields based on your actual data structure
      location = locationData['address'] as String? ??
          locationData['name'] as String? ??
          locationData.toString();
    } else {
      location = null;
    }

    return Order(
      id: data['id'] as String? ?? doc.id,
      userId: data['userId'] as String? ?? '',
      userName: data['userName'] as String? ?? 'Anonymous',
      items: items,
      total: (data['total'] as num?)?.toDouble() ?? 0.0,
      status: data['status'] as String? ?? 'Pending',
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      phone: data['phone'] as String? ?? '',
      deliveryMethod: data['deliveryMethod'] as String? ?? 'Take Away',
      location: location,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'userName': userName,
      'items': items.map((item) => item.toMap()).toList(),
      'total': total,
      'status': status,
      'createdAt': createdAt,
      'phone': phone,
      'deliveryMethod': deliveryMethod,
      'location': location,
    };
  }
}
