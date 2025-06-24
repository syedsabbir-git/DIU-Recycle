import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:cloudinary_public/cloudinary_public.dart';
import '../models/message.dart';
import '../services/chat_service.dart';
import '../services/auth_service.dart';

class ChatScreen extends StatefulWidget {
  final String chatId;
  final String otherUserId;
  final String otherUserName;
  final String? productId;
  final String? productTitle;
  final String? productImageUrl;

  const ChatScreen({
    Key? key,
    required this.chatId,
    required this.otherUserId,
    required this.otherUserName,
    this.productId,
    this.productTitle,
    this.productImageUrl,
  }) : super(key: key);

  @override
  _ChatScreenState createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final ChatService _chatService = ChatService();
  final AuthService _authService = AuthService();
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final ImagePicker _imagePicker = ImagePicker();
  final cloudinary = CloudinaryPublic('dexm0l8os', 'DIURecycle', cache: false);

  late String _currentUserId;
  String? _currentUserName;
  File? _selectedImage;
  bool _isUploading = false;

  @override
  void initState() {
    super.initState();
    _currentUserId = _authService.getCurrentUserId() ?? '';
    _loadUserData();
    
    // Mark messages as read when opening chat
    _chatService.markMessagesAsRead(widget.chatId);
    
    // Scroll to bottom when new messages arrive
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollToBottom();
    });
  }

  Future<void> _loadUserData() async {
    final userData = await _authService.getUserData();
    if (userData != null && mounted) {
      setState(() {
        _currentUserName = userData['fullName'];
      });
    }
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  Future<void> _pickImage() async {
    final XFile? pickedFile = await _imagePicker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 70,
    );
    
    if (pickedFile != null) {
      setState(() {
        _selectedImage = File(pickedFile.path);
      });
    }
  }

  Future<void> _takePhoto() async {
    final XFile? pickedFile = await _imagePicker.pickImage(
      source: ImageSource.camera,
      imageQuality: 70,
    );
    
    if (pickedFile != null) {
      setState(() {
        _selectedImage = File(pickedFile.path);
      });
    }
  }

  void _clearSelectedImage() {
    setState(() {
      _selectedImage = null;
    });
  }

  Future<String?> _uploadImageToCloudinary(File imageFile) async {
    try {
      final response = await cloudinary.uploadFile(
        CloudinaryFile.fromFile(
          imageFile.path,
          resourceType: CloudinaryResourceType.Image,
        ),
      );
      return response.secureUrl;
    } catch (e) {
      debugPrint('Error uploading image: $e');
      return null;
    }
  }

  Future<void> _sendMessage() async {
    final messageText = _messageController.text.trim();
    
    if (messageText.isEmpty && _selectedImage == null) return;
    
    _messageController.clear();
    
    setState(() {
      _isUploading = _selectedImage != null;
    });

    String? imageUrl;
    if (_selectedImage != null) {
      imageUrl = await _uploadImageToCloudinary(_selectedImage!);
      setState(() {
        _selectedImage = null;
        _isUploading = false;
      });
      
      if (imageUrl == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to upload image')),
        );
        return;
      }
    }

    final message = Message(
      id: '',
      senderId: _currentUserId,
      senderName: _currentUserName ?? 'Me',
      receiverId: widget.otherUserId,
      content: messageText,
      imageUrl: imageUrl,
      timestamp: DateTime.now(),
      productId: widget.productId,
    );

    try {
      await _chatService.sendMessage(widget.chatId, message);
      _scrollToBottom();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to send message: $e')),
      );
    }
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final yesterday = DateTime(now.year, now.month, now.day - 1);
    
    if (date.year == now.year && date.month == now.month && date.day == now.day) {
      return 'Today';
    } else if (date.year == yesterday.year && date.month == yesterday.month && date.day == yesterday.day) {
      return 'Yesterday';
    } else {
      return DateFormat('MMM d, yyyy').format(date);
    }
  }
  
  String _formatTime(DateTime dateTime) {
    return DateFormat('h:mm a').format(dateTime);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.otherUserName),
        backgroundColor: Colors.white,
        foregroundColor: Colors.green.shade800,
      ),
      body: Column(
        children: [
          // Product info banner (if this chat is about a product)
          if (widget.productId != null && widget.productTitle != null)
            Container(
              padding: const EdgeInsets.all(12),
              color: Colors.green.shade50,
              child: Row(
                children: [
                  if (widget.productImageUrl != null)
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.network(
                        widget.productImageUrl!,
                        width: 50,
                        height: 50,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) => Container(
                          width: 50,
                          height: 50,
                          color: Colors.grey.shade300,
                          child: const Icon(Icons.image_not_supported),
                        ),
                      ),
                    ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Chatting about:',
                          style: TextStyle(
                            color: Colors.grey.shade700,
                            fontSize: 12,
                          ),
                        ),
                        Text(
                          widget.productTitle!,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.green.shade800,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

          // Messages
          Expanded(
            child: StreamBuilder<List<Message>>(
              stream: _chatService.getMessages(widget.chatId),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Center(
                    child: Text('Error: ${snapshot.error}'),
                  );
                }

                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                final messages = snapshot.data!;
                
                // Mark messages as read when viewing them
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  _chatService.markMessagesAsRead(widget.chatId);
                });
                
                if (messages.isEmpty) {
                  return Center(
                    child: Text(
                      'No messages yet.\nSend a message to start the conversation!',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: 16,
                      ),
                    ),
                  );
                }

                WidgetsBinding.instance.addPostFrameCallback((_) {
                  _scrollToBottom();
                });

                return ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.all(16),
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    final message = messages[index];
                    final isMe = message.senderId == _currentUserId;
                    
                    // Check if we should show date header
                    bool showDateHeader = false;
                    if (index == 0) {
                      showDateHeader = true;
                    } else {
                      final prevDate = messages[index - 1].timestamp;
                      final currDate = message.timestamp;
                      if (prevDate.day != currDate.day ||
                          prevDate.month != currDate.month ||
                          prevDate.year != currDate.year) {
                        showDateHeader = true;
                      }
                    }

                    return Column(
                      children: [
                        if (showDateHeader)
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            child: Center(
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.grey.shade200,
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                child: Text(
                                  _formatDate(message.timestamp),
                                  style: TextStyle(
                                    color: Colors.grey.shade700,
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: Align(
                            alignment: isMe
                                ? Alignment.centerRight
                                : Alignment.centerLeft,
                            child: Container(
                              constraints: BoxConstraints(
                                maxWidth: MediaQuery.of(context).size.width * 0.75,
                              ),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 10,
                              ),
                              decoration: BoxDecoration(
                                color: isMe
                                    ? Colors.green.shade100
                                    : Colors.grey.shade100,
                                borderRadius: BorderRadius.circular(16).copyWith(
                                  bottomRight: isMe ? Radius.zero : null,
                                  bottomLeft: !isMe ? Radius.zero : null,
                                ),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Show image if exists
                                  if (message.imageUrl != null)
                                    Padding(
                                      padding: const EdgeInsets.only(bottom: 8),
                                      child: GestureDetector(
                                        onTap: () {
                                          // Open image in full-screen view
                                          Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder: (context) => Scaffold(
                                                appBar: AppBar(
                                                  backgroundColor: Colors.black,
                                                  iconTheme: const IconThemeData(color: Colors.white),
                                                ),
                                                backgroundColor: Colors.black,
                                                body: Center(
                                                  child: InteractiveViewer(
                                                    child: Image.network(
                                                      message.imageUrl!,
                                                      fit: BoxFit.contain,
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
                                                      errorBuilder: (context, error, stackTrace) => const Center(
                                                        child: Icon(Icons.error, color: Colors.white),
                                                      ),
                                                    ),
                                                  ),
                                                ),
                                              ),
                                            ),
                                          );
                                        },
                                        child: ClipRRect(
                                          borderRadius: BorderRadius.circular(8),
                                          child: Image.network(
                                            message.imageUrl!,
                                            fit: BoxFit.cover,
                                            width: double.infinity,
                                            loadingBuilder: (context, child, loadingProgress) {
                                              if (loadingProgress == null) return child;
                                              return SizedBox(
                                                height: 150,
                                                child: Center(
                                                  child: CircularProgressIndicator(
                                                    value: loadingProgress.expectedTotalBytes != null
                                                        ? loadingProgress.cumulativeBytesLoaded /
                                                            loadingProgress.expectedTotalBytes!
                                                        : null,
                                                  ),
                                                ),
                                              );
                                            },
                                            errorBuilder: (context, error, stackTrace) => Container(
                                              height: 150,
                                              color: Colors.grey.shade300,
                                              child: const Center(
                                                child: Icon(Icons.image_not_supported),
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  
                                  // Show text if exists
                                  if (message.content.isNotEmpty)
                                    Text(
                                      message.content,
                                      style: const TextStyle(fontSize: 16),
                                    ),
                                  
                                  const SizedBox(height: 4),
                                  Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(
                                        _formatTime(message.timestamp),
                                        style: TextStyle(
                                          color: Colors.grey.shade600,
                                          fontSize: 12,
                                        ),
                                      ),
                                      if (isMe) ...[
                                        const SizedBox(width: 4),
                                        Icon(
                                          message.isRead 
                                              ? Icons.done_all 
                                              : Icons.done,
                                          size: 14,
                                          color: message.isRead 
                                              ? Colors.blue 
                                              : Colors.grey.shade500,
                                        ),
                                      ]
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    );
                  },
                );
              },
            ),
          ),

          // Selected image preview
          if (_selectedImage != null)
            Container(
              padding: const EdgeInsets.all(8),
              color: Colors.grey.shade100,
              child: Row(
                children: [
                  Expanded(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Stack(
                        alignment: Alignment.topRight,
                        children: [
                          Image.file(
                            _selectedImage!,
                            height: 100,
                            fit: BoxFit.cover,
                          ),
                          Container(
                            decoration: const BoxDecoration(
                              color: Colors.black54,
                              shape: BoxShape.circle,
                            ),
                            child: IconButton(
                              icon: const Icon(Icons.close, color: Colors.white),
                              onPressed: _clearSelectedImage,
                              iconSize: 20,
                              padding: const EdgeInsets.all(4),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),

          // Message input area
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.3),
                  spreadRadius: 1,
                  blurRadius: 5,
                  offset: const Offset(0, -1),
                ),
              ],
            ),
            child: Row(
              children: [
                // Image attachment button
                IconButton(
                  icon: Icon(
                    Icons.photo,
                    color: Colors.green.shade700,
                  ),
                  onPressed: _isUploading ? null : _pickImage,
                ),
                
                // Camera button
                IconButton(
                  icon: Icon(
                    Icons.camera_alt,
                    color: Colors.green.shade700,
                  ),
                  onPressed: _isUploading ? null : _takePhoto,
                ),
                
                // Text input field
                Expanded(
                  child: TextField(
                    controller: _messageController,
                    decoration: InputDecoration(
                      hintText: 'Type a message...',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24),
                        borderSide: BorderSide.none,
                      ),
                      filled: true,
                      fillColor: Colors.grey.shade100,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 10,
                      ),
                      isDense: true,
                    ),
                    textCapitalization: TextCapitalization.sentences,
                    maxLines: 5,
                    minLines: 1,
                    onSubmitted: (_) => _sendMessage(),
                  ),
                ),
                
                // Send button
                Padding(
                  padding: const EdgeInsets.only(left: 8),
                  child: Material(
                    color: Colors.green.shade700,
                    borderRadius: BorderRadius.circular(24),
                    child: _isUploading
                        ? const Padding(
                            padding: EdgeInsets.all(12),
                            child: SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            ),
                          )
                        : InkWell(
                            borderRadius: BorderRadius.circular(24),
                            onTap: _sendMessage,
                            child: const Padding(
                              padding: EdgeInsets.all(12),
                              child: Icon(
                                Icons.send,
                                color: Colors.white,
                                size: 24,
                              ),
                            ),
                          ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}