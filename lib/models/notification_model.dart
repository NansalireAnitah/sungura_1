class AppNotification {
  final String id;
  final String title;
  final String body;
  final DateTime timestamp;
  bool isRead;
  final List<Map<String, dynamic>>? items; // List of ordered items
  final double? total; // Total amount
  final String? location; // Delivery address or "Take Away"

  AppNotification({
    required this.id,
    required this.title,
    required this.body,
    DateTime? timestamp,
    this.isRead = false,
    this.items,
    this.total,
    this.location,
  }) : timestamp = timestamp ?? DateTime.now();

  factory AppNotification.fromMap(Map<String, dynamic> map) {
    return AppNotification(
      id: map['id'] as String,
      title: map['title'] as String,
      body: map['body'] as String,
      timestamp: DateTime.parse(map['timestamp'] as String),
      isRead: map['isRead'] as bool? ?? false,
      items: map['items'] != null
          ? (map['items'] as List<dynamic>)
              .map((item) => Map<String, dynamic>.from(item as Map))
              .toList()
          : null,
      total: (map['total'] as num?)?.toDouble(),
      location: map['location'] as String?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'body': body,
      'timestamp': timestamp.toIso8601String(),
      'isRead': isRead,
      'items': items,
      'total': total,
      'location': location,
    };
  }
}