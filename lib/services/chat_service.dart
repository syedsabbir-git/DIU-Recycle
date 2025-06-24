// lib/services/chat_service.dart
import 'package:firebase_database/firebase_database.dart' as rtdb;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/foundation.dart';
import '../models/message.dart';
import '../models/chat.dart';
import '../models/product.dart';
import 'auth_service.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class ChatService {
  final FirebaseDatabase _database = FirebaseDatabase.instance;
  final AuthService _authService = AuthService();
  // You should store these securely - consider using environment variables or a config file
  final String _oneSignalAppId = "8d3967fe-85a2-4355-81e9-1445123ff464";
  final String _oneSignalRestApiKey = "os_v2_app_ru4wp7ufujbvlapjcrcrep7umqmvaoke2ljuype3ojienhdyia4blzljlfbiyquljszsvpuxs4iycn45tagjz5bwxf6ovev3yhb6vbq";

  // Get reference to chats node
  DatabaseReference get _chatsRef => _database.ref().child('chats');

  // Get reference to messages node for a specific chat
  DatabaseReference _messagesRef(String chatId) =>
      _database.ref().child('messages').child(chatId);

  // Create or get a chat between two users
  Future<String> createOrGetChat({
    required String otherUserId,
    Product? product,
  }) async {
    final currentUserId = _authService.getCurrentUserId();
    if (currentUserId == null) {
      throw Exception('User not logged in');
    }

    // Sort user IDs to ensure consistent chat ID regardless of who initiates
    final sortedUserIds = [currentUserId, otherUserId]..sort();
    final chatId = sortedUserIds.join('_');

    // Check if chat already exists
    final chatSnapshot = await _chatsRef.child(chatId).get();

    if (!chatSnapshot.exists) {
      // Get current user info
      final currentUserData = await _authService.getUserData();
      final currentUserName = currentUserData?['fullName'] ?? 'User';

      // Get product seller info
      final sellerSnapshot =
          await _database.ref().child('users').child(otherUserId).get();
      
      // Fix: Cast data safely
      Map<String, dynamic> sellerData = {};
      if (sellerSnapshot.value != null) {
        final rawData = sellerSnapshot.value as Map<dynamic, dynamic>;
        rawData.forEach((key, value) {
          sellerData[key.toString()] = value;
        });
      }
      
      final sellerName = sellerData.isNotEmpty ? sellerData['fullName'] ?? 'Seller' : 'Seller';

      // Create new chat
      final newChat = Chat(
        id: chatId,
        participants: sortedUserIds,
        productId: product?.id,
        productTitle: product?.title,
        productImageUrl: product?.imageUrls.isNotEmpty == true
            ? product!.imageUrls[0]
            : null,
        unreadCounts: {
          otherUserId: 0,
          currentUserId: 0,
        },
      );

      await _chatsRef.child(chatId).set(newChat.toMap());

      // If this is a product inquiry, create initial message
      if (product != null) {
        final initialMessage = Message(
          id: '',
          senderId: currentUserId,
          senderName: currentUserName,
          receiverId: otherUserId,
          content:
              'Hi, I am interested in your product "${product.title}". Is it still available?',
          timestamp: DateTime.now(),
          productId: product.id,
        );

        await sendMessage(chatId, initialMessage);
      }
    }

    return chatId;
  }

  // Send a message
  Future<void> sendMessage(String chatId, Message message) async {
    try {
      // Get a reference to the messages node for this chat
      final messagesRef = _messagesRef(chatId);

      // Push a new message (generates a unique ID)
      final newMessageRef = messagesRef.push();
      await newMessageRef.set(message.toMap());

      // Determine the last message text for chat preview
      // If there's an image but no text, show "📷 Image"
      // If there's both text and image, use the text
      // If there's only text, use the text
      final lastMessageText = message.content.isNotEmpty 
          ? message.content 
          : (message.imageUrl != null ? '📷 Image' : '');

      // Update chat with last message info
      await _chatsRef.child(chatId).update({
        'lastMessage': lastMessageText,
        'lastMessageTime': message.timestamp.millisecondsSinceEpoch,
        'lastSenderId': message.senderId,
      });

      // Increment unread count for the receiver
      await _chatsRef
          .child(chatId)
          .child('unreadCounts')
          .child(message.receiverId)
          .runTransaction((currentValue) {
        return rtdb.Transaction.success((currentValue as int? ?? 0) + 1);
      });

      // Send push notification to receiver
      await _sendMessageNotification(message);
    } catch (e) {
      if (kDebugMode) {
        print('Error sending message: $e');
      }
      rethrow;
    }
  }

  Future<void> _sendMessageNotification(Message message) async {
    print("Sending notification...................................................................................................");

    try {
      // Get receiver's OneSignal Player ID from Firestore
      final docSnapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(message.receiverId)
          .get();

      String? receiverPlayerId; // Declare nullable
      if (docSnapshot.exists) {
        final data = docSnapshot.data();
        receiverPlayerId = data != null ? data['oneSignalPlayerId'] as String? : null;
        print('Receiver Player ID: $receiverPlayerId');
      }

      // Get sender's name for the notification
      final senderName = message.senderName;

      // Determine notification content based on message type
      final notificationContent = message.content.isNotEmpty 
          ? message.content 
          : (message.imageUrl != null ? '📷 Sent you an image' : '');

      if (receiverPlayerId != null && receiverPlayerId.isNotEmpty) {
        // Send notification using OneSignal REST API
        final response = await http.post(
          Uri.parse('https://onesignal.com/api/v1/notifications'),
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Basic $_oneSignalRestApiKey',
          },
          body: jsonEncode({
            'app_id': _oneSignalAppId,
            'include_player_ids': [receiverPlayerId],
            'headings': {'en': '$senderName sent you a message'},
            'contents': {'en': notificationContent},
            'data': {
              'chatId': message.id.split('_')[0], // Extract the chat ID
              'senderId': message.senderId,
              'type': 'chat_message',
            },
          }),
        );

        if (response.statusCode == 200) {
          if (kDebugMode) {
            print('Notification successfully sent to $receiverPlayerId');
          }
        } else {
          if (kDebugMode) {
            print('Failed to send notification: ${response.body}');
          }
        }
      } else {
        if (kDebugMode) {
          print('Receiver OneSignal ID not found, notification not sent.');
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error sending notification: $e');
      }
      // No rethrow, because sending notification failure should not crash the app
    }
  }

  // Stream of messages for a specific chat
  Stream<List<Message>> getMessages(String chatId) {
    return _messagesRef(chatId).orderByChild('timestamp').onValue.map((event) {
      final data = event.snapshot.value;
      if (data == null) {
        return [];
      }
      
      // Fix: Cast data safely
      List<Message> messages = [];
      try {
        final messagesMap = data as Map<dynamic, dynamic>;
        messagesMap.forEach((key, value) {
          if (value is Map<dynamic, dynamic>) {
            // Convert dynamic Map to properly typed Map<String, dynamic>
            final typedMap = _convertMap(value);
            messages.add(Message.fromMap(typedMap, key.toString()));
          }
        });
      } catch (e) {
        if (kDebugMode) {
          print('Error parsing messages: $e');
        }
      }

      // Sort messages by timestamp
      messages.sort((a, b) => a.timestamp.compareTo(b.timestamp));
      return messages;
    });
  }

  // Stream of all chats for current user
  Stream<List<Chat>> getUserChats() {
    final currentUserId = _authService.getCurrentUserId();
    if (currentUserId == null) {
      return Stream.value([]);
    }

    return _chatsRef.orderByChild('lastMessageTime').onValue.map((event) {
      final data = event.snapshot.value;
      if (data == null) {
        return [];
      }

      List<Chat> chats = [];
      try {
        final chatsMap = data as Map<dynamic, dynamic>;
        chatsMap.forEach((key, value) {
          if (value is Map<dynamic, dynamic>) {
            // Convert dynamic Map to properly typed Map<String, dynamic>
            final typedMap = _convertMap(value);
            final chat = Chat.fromMap(typedMap, key.toString());
            
            // Only include chats where current user is a participant
            if (chat.participants.contains(currentUserId)) {
              chats.add(chat);
            }
          }
        });
      } catch (e) {
        if (kDebugMode) {
          print('Error parsing chats: $e');
        }
      }

      // Sort chats by last message time (newest first)
      chats.sort((a, b) {
        if (a.lastMessageTime == null) return 1;
        if (b.lastMessageTime == null) return -1;
        return b.lastMessageTime!.compareTo(a.lastMessageTime!);
      });

      return chats;
    });
  }

  // Helper method to convert Map<dynamic, dynamic> to Map<String, dynamic>
  Map<String, dynamic> _convertMap(Map<dynamic, dynamic> map) {
    Map<String, dynamic> result = {};
    map.forEach((key, value) {
      if (value is Map<dynamic, dynamic>) {
        // Recursively convert nested maps
        result[key.toString()] = _convertMap(value);
      } else if (value is List<dynamic>) {
        // Convert lists
        result[key.toString()] = _convertList(value);
      } else {
        result[key.toString()] = value;
      }
    });
    return result;
  }

  // Helper method to convert List<dynamic> with potential nested maps
  List<dynamic> _convertList(List<dynamic> list) {
    List<dynamic> result = [];
    for (var item in list) {
      if (item is Map<dynamic, dynamic>) {
        result.add(_convertMap(item));
      } else if (item is List<dynamic>) {
        result.add(_convertList(item));
      } else {
        result.add(item);
      }
    }
    return result;
  }

  // Get total unread message count for current user
  Stream<int> getTotalUnreadCount() {
    final currentUserId = _authService.getCurrentUserId();
    if (currentUserId == null) {
      return Stream.value(0);
    }

    return _chatsRef.onValue.map((event) {
      final data = event.snapshot.value;
      if (data == null) {
        return 0;
      }

      int totalUnread = 0;
      try {
        final chatsMap = data as Map<dynamic, dynamic>;
        chatsMap.forEach((key, value) {
          if (value is Map<dynamic, dynamic>) {
            // Convert dynamic Map to properly typed Map<String, dynamic>
            final typedMap = _convertMap(value);
            final chat = Chat.fromMap(typedMap, key.toString());
            
            // Only count unread messages in chats where current user is a participant
            if (chat.participants.contains(currentUserId)) {
              totalUnread += chat.getUnreadCountFor(currentUserId);
            }
          }
        });
      } catch (e) {
        if (kDebugMode) {
          print('Error calculating unread counts: $e');
        }
      }

      return totalUnread;
    });
  }

  // Mark messages as read
  Future<void> markMessagesAsRead(String chatId) async {
    final currentUserId = _authService.getCurrentUserId();
    if (currentUserId == null) {
      return;
    }

    try {
      // Get all messages in the chat
      final messagesSnapshot = await _messagesRef(chatId).get();
      if (messagesSnapshot.value == null) {
        return;
      }
      
      // Fix: Cast data safely
      Map<String, dynamic> updates = {};
      try {
        final messagesMap = messagesSnapshot.value as Map<dynamic, dynamic>;
        messagesMap.forEach((key, value) {
          if (value is Map<dynamic, dynamic>) {
            final receiverId = value['receiverId'];
            final isRead = value['isRead'] ?? false;
            
            if (receiverId == currentUserId && !isRead) {
              updates['$key/isRead'] = true;
            }
          }
        });
      } catch (e) {
        if (kDebugMode) {
          print('Error parsing messages for marking as read: $e');
        }
      }

      // If there are messages to update
      if (updates.isNotEmpty) {
        // Update all messages with one operation
        await _messagesRef(chatId).update(updates);

        // Reset unread count for current user
        await _chatsRef
            .child(chatId)
            .child('unreadCounts')
            .child(currentUserId)
            .set(0);
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error marking messages as read: $e');
      }
    }
  }
}