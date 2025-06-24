import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/chat.dart';
import '../services/chat_service.dart';
import '../services/auth_service.dart';
import 'chat_screen.dart';

class ChatsListScreen extends StatefulWidget {
  const ChatsListScreen({Key? key}) : super(key: key);

  @override
  _ChatsListScreenState createState() => _ChatsListScreenState();
}

class _ChatsListScreenState extends State<ChatsListScreen> {
  final ChatService _chatService = ChatService();
  final AuthService _authService = AuthService();
  late String _currentUserId;

  @override
  void initState() {
    super.initState();
    _currentUserId = _authService.getCurrentUserId() ?? '';
  }

  String _getOtherUserId(List<String> participants) {
    return participants.firstWhere(
      (id) => id != _currentUserId,
      orElse: () => '',
    );
  }

  Future<String> _getUserName(String userId) async {
  try {
    if (userId.isEmpty) return 'User';

    // Get user document from Firestore
    final userDoc = await FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .get();

    if (userDoc.exists && userDoc.data()?['fullName'] != null) {
      return userDoc.data()!['fullName'].toString();
    }

    return 'User';
  } catch (e) {
    print('Error getting user name: $e');
    return 'User';
  }
}

  String _formatMessageTime(DateTime? time) {
    if (time == null) return '';

    final now = DateTime.now();
    if (time.year == now.year &&
        time.month == now.month &&
        time.day == now.day) {
      return DateFormat('h:mm a').format(time);
    } else if (time.year == now.year) {
      return DateFormat('MMM d').format(time);
    } else {
      return DateFormat('MMM d, y').format(time);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Messages'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.green.shade800,
      ),
      body: StreamBuilder<List<Chat>>(
        stream: _chatService.getUserChats(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(
              child: Text('Error: ${snapshot.error}'),
            );
          }

          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final chats = snapshot.data!;

          if (chats.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.chat_bubble_outline,
                    size: 80,
                    color: Colors.grey.shade400,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No conversations yet',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey.shade700,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Start a conversation by messaging a seller',
                    style: TextStyle(
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            itemCount: chats.length,
            itemBuilder: (context, index) {
              final chat = chats[index];
              final otherUserId = _getOtherUserId(chat.participants);
              final unreadCount = chat.getUnreadCountFor(_currentUserId);

              return FutureBuilder<String>(
                future: _getUserName(otherUserId),
                builder: (context, snapshot) {
                  final otherUserName = snapshot.data ?? 'Loading...';

                  return ListTile(
                    leading: Stack(
                      children: [
                        CircleAvatar(
                          backgroundColor: Colors.green.shade100,
                          child: Text(
                            otherUserName.isNotEmpty
                                ? otherUserName[0].toUpperCase()
                                : '?',
                            style: TextStyle(
                              color: Colors.green.shade800,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        if (unreadCount > 0)
                          Positioned(
                            right: 0,
                            bottom: 0,
                            child: Container(
                              padding: const EdgeInsets.all(4),
                              decoration: BoxDecoration(
                                color: Colors.red,
                                shape: BoxShape.circle,
                                border:
                                    Border.all(color: Colors.white, width: 2),
                              ),
                              constraints: const BoxConstraints(
                                minWidth: 14,
                                minHeight: 14,
                              ),
                            ),
                          ),
                      ],
                    ),
                    title: Text(
                      otherUserName,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    subtitle: Row(
                      children: [
                        if (chat.productImageUrl != null)
                          Padding(
                            padding: const EdgeInsets.only(right: 8.0),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(4),
                              child: Image.network(
                                chat.productImageUrl!,
                                width: 20,
                                height: 20,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) =>
                                    Container(
                                  width: 20,
                                  height: 20,
                                  color: Colors.grey.shade300,
                                ),
                              ),
                            ),
                          ),
                        Expanded(
                          child: Text(
                            chat.lastMessage ?? 'No messages yet',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: unreadCount > 0
                                ? TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.black,
                                  )
                                : null,
                          ),
                        ),
                      ],
                    ),
                    trailing: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          _formatMessageTime(chat.lastMessageTime),
                          style: TextStyle(
                            color: unreadCount > 0
                                ? Colors.green.shade700
                                : Colors.grey.shade600,
                            fontSize: 12,
                            fontWeight: unreadCount > 0
                                ? FontWeight.bold
                                : FontWeight.normal,
                          ),
                        ),
                        if (unreadCount > 0) ...[
                          const SizedBox(height: 4),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.green.shade500,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              '$unreadCount',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => ChatScreen(
                            chatId: chat.id,
                            otherUserId: otherUserId,
                            otherUserName: otherUserName,
                            productId: chat.productId,
                            productTitle: chat.productTitle,
                            productImageUrl: chat.productImageUrl,
                          ),
                        ),
                      );

                      // Mark messages as read when opening the chat
                      _chatService.markMessagesAsRead(chat.id);
                    },
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}
