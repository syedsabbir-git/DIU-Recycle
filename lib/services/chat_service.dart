// lib/services/chat_service.dart
import 'package:firebase_database/firebase_database.dart' as rtdb;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/foundation.dart';
import '../config/env.dart';
import '../models/message.dart';
import '../models/chat.dart';
import '../models/product.dart';
import 'auth_service.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class ChatService {
  final FirebaseDatabase _database = FirebaseDatabase.instance;
  final AuthService _authService = AuthService();
  final String _oneSignalAppId = Env.oneSignalAppId;
  final String _oneSignalRestApiKey = Env.oneSignalRestApiKey;

  DatabaseReference get _chatsRef => _database.ref().child('chats');

  DatabaseReference _messagesRef(String chatId) =>
      _database.ref().child('messages').child(chatId);

  // chat between two users
  Future<String> createOrGetChat({
    required String otherUserId,
    Product? product,
  }) async {
    final currentUserId = _authService.getCurrentUserId();
    if (currentUserId == null) {
      throw Exception('User not logged in');
    }

    // Sort user ID
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
      final messagesRef = _messagesRef(chatId);

      final newMessageRef = messagesRef.push();
      await newMessageRef.set(message.toMap());
      final lastMessageText = message.content.isNotEmpty 
          ? message.content 
          : (message.imageUrl != null ? '📷 Image' : '');


      await _chatsRef.child(chatId).update({
        'lastMessage': lastMessageText,
        'lastMessageTime': message.timestamp.millisecondsSinceEpoch,
        'lastSenderId': message.senderId,
      });


      await _chatsRef
          .child(chatId)
          .child('unreadCounts')
          .child(message.receiverId)
          .runTransaction((currentValue) {
        return rtdb.Transaction.success((currentValue as int? ?? 0) + 1);
      });

      await _sendMessageNotification(message);
    } catch (e) {
      if (kDebugMode) {
        print('Error sending message: $e');
      }
      rethrow;
    }
  }

  Future<void> _sendMessageNotification(Message message) async {
    if (kDebugMode) {
      print("Sending notification...................................................................................................");
    }

    try {
      // Get receiver's OneSignal Player ID
      final receiverDocSnapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(message.receiverId)
          .get();

      String? receiverPlayerId; 
      if (receiverDocSnapshot.exists) {
        final data = receiverDocSnapshot.data();
        receiverPlayerId = data != null ? data['oneSignalPlayerId'] as String? : null;
        if (kDebugMode) {
          print('Receiver Player ID: $receiverPlayerId');
        }
      }

      // Get sender's OneSignal Player ID to exclude from notifications
      final senderDocSnapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(message.senderId)
          .get();

      String? senderPlayerId; 
      if (senderDocSnapshot.exists) {
        final data = senderDocSnapshot.data();
        senderPlayerId = data != null ? data['oneSignalPlayerId'] as String? : null;
        if (kDebugMode) {
          print('Sender Player ID (to exclude): $senderPlayerId');
        }
      }

      final senderName = message.senderName;

      final notificationContent = message.content.isNotEmpty 
          ? message.content 
          : (message.imageUrl != null ? '📷 Sent you an image' : '');

      // Only send notification if receiver has a valid Player ID
      // and it's different from sender's Player ID
      if (receiverPlayerId != null && 
          receiverPlayerId.isNotEmpty && 
          receiverPlayerId != senderPlayerId) {
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
              'chatId': message.id.split('_')[0],
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
          if (receiverPlayerId == null || receiverPlayerId.isEmpty) {
            print('Receiver OneSignal ID not found, notification not sent.');
          } else if (receiverPlayerId == senderPlayerId) {
            print('Sender and receiver are the same device, notification not sent to avoid duplicate.');
          }
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error sending notification: $e');
      }
    }
  }

  Stream<List<Message>> getMessages(String chatId) {
    return _messagesRef(chatId).orderByChild('timestamp').onValue.map((event) {
      final data = event.snapshot.value;
      if (data == null) {
        return [];
      }
      
      List<Message> messages = [];
      try {
        final messagesMap = data as Map<dynamic, dynamic>;
        messagesMap.forEach((key, value) {
          if (value is Map<dynamic, dynamic>) {
            final typedMap = _convertMap(value);
            messages.add(Message.fromMap(typedMap, key.toString()));
          }
        });
      } catch (e) {
        if (kDebugMode) {
          print('Error parsing messages: $e');
        }
      }

      messages.sort((a, b) => a.timestamp.compareTo(b.timestamp));
      return messages;
    });
  }

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

      // Sort chats (newest first)
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

        result[key.toString()] = _convertMap(value);
      } else if (value is List<dynamic>) {

        result[key.toString()] = _convertList(value);
      } else {
        result[key.toString()] = value;
      }
    });
    return result;
  }

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

  // Get total unread message count
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
            final typedMap = _convertMap(value);
            final chat = Chat.fromMap(typedMap, key.toString());
            

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

      final messagesSnapshot = await _messagesRef(chatId).get();
      if (messagesSnapshot.value == null) {
        return;
      }
      

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


      if (updates.isNotEmpty) {

        await _messagesRef(chatId).update(updates);


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