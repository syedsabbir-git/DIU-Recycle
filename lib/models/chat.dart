// lib/models/chat.dart
class Chat {
  final String id;
  final List<String> participants;
  final String? lastMessage;
  final DateTime? lastMessageTime;
  final String? productId;
  final String? productTitle;
  final String? productImageUrl;
  final Map<String, int>? unreadCounts; // Map of userId -> unread count

  Chat({
    required this.id,
    required this.participants,
    this.lastMessage,
    this.lastMessageTime,
    this.productId,
    this.productTitle,
    this.productImageUrl,
    this.unreadCounts,
  });

  factory Chat.fromMap(Map<dynamic, dynamic> data, String id) {
    Map<String, int> unreadMap = {};
    if (data['unreadCounts'] != null) {
      (data['unreadCounts'] as Map<dynamic, dynamic>).forEach((key, value) {
        unreadMap[key.toString()] = value as int;
      });
    }

    return Chat(
      id: id,
      participants: List<String>.from(data['participants'] ?? []),
      lastMessage: data['lastMessage'],
      lastMessageTime: data['lastMessageTime'] != null
          ? DateTime.fromMillisecondsSinceEpoch(data['lastMessageTime'])
          : null,
      productId: data['productId'],
      productTitle: data['productTitle'],
      productImageUrl: data['productImageUrl'],
      unreadCounts: unreadMap,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'participants': participants,
      'lastMessage': lastMessage,
      'lastMessageTime': lastMessageTime?.millisecondsSinceEpoch,
      'productId': productId,
      'productTitle': productTitle,
      'productImageUrl': productImageUrl,
      'unreadCounts': unreadCounts,
    };
  }

  // Get unread count for a specific user
  int getUnreadCountFor(String userId) {
    return unreadCounts?[userId] ?? 0;
  }
}