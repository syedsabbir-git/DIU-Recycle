// lib/models/message.dart

class Message {
  final String id;
  final String senderId;
  final String senderName;
  final String receiverId;
  final String content;
  final DateTime timestamp;
  final String? imageUrl;
  final bool isRead;
  final String? productId;

  Message({
    required this.id,
    required this.senderId,
    required this.senderName,
    required this.receiverId,
    required this.content,
    required this.timestamp,
    this.imageUrl,
    this.isRead = false,
    this.productId,
  });

  Map<String, dynamic> toMap() {
    return {
      'senderId': senderId,
      'senderName': senderName,
      'receiverId': receiverId,
      'content': content,
      'timestamp': timestamp.millisecondsSinceEpoch, // Store as milliseconds integer
      'imageUrl': imageUrl,
      'isRead': isRead,
      'productId': productId,
    };
  }

  factory Message.fromMap(Map<String, dynamic> map, String docId) {
    // Handle timestamp conversion from various formats
    DateTime parsedTimestamp;
    
    var timestampData = map['timestamp'];
    if (timestampData is int) {
      // Integer timestamp (milliseconds since epoch)
      parsedTimestamp = DateTime.fromMillisecondsSinceEpoch(timestampData);
    } else if (timestampData is Map) {
      // Firestore timestamp format
      try {
        int seconds = timestampData['seconds'] ?? 0;
        int nanoseconds = timestampData['nanoseconds'] ?? 0;
        parsedTimestamp = DateTime.fromMillisecondsSinceEpoch(
          seconds * 1000 + (nanoseconds / 1000000).round(),
        );
      } catch (e) {
        parsedTimestamp = DateTime.now();
      }
    } else {
      // Default fallback
      parsedTimestamp = DateTime.now();
    }

    return Message(
      id: docId,
      senderId: map['senderId'] ?? '',
      senderName: map['senderName'] ?? '',
      receiverId: map['receiverId'] ?? '',
      content: map['content'] ?? '',
      timestamp: parsedTimestamp,
      imageUrl: map['imageUrl'],
      isRead: map['isRead'] ?? false,
      productId: map['productId'],
    );
  }
}