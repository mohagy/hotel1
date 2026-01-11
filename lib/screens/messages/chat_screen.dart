/// Chat Screen
/// 
/// Real-time chat interface for group and private chats

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../services/chat_service.dart';
import '../../services/notification_service.dart';
import '../../core/theme/app_theme.dart';

class ChatScreen extends StatefulWidget {
  final String conversationId;
  final bool isGroupChat;
  final String? title;
  final String? otherParticipantId;
  final String? otherParticipantName;

  const ChatScreen({
    Key? key,
    required this.conversationId,
    required this.isGroupChat,
    this.title,
    this.otherParticipantId,
    this.otherParticipantName,
  }) : super(key: key);

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final ChatService _chatService = ChatService();
  final NotificationService _notificationService = NotificationService();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  String _selectedMessageType = 'normal';
  String? _lastMessageId; // Track last message to only play sound for new messages

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    // Mark messages as read when screen loads
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _chatService.markMessagesAsRead(widget.conversationId);
    });
  }

  Future<void> _sendMessage(String text) async {
    if (text.trim().isEmpty) return;

    final currentUserId = _auth.currentUser?.uid;
    if (currentUserId == null) return;

    try {
      if (widget.isGroupChat) {
        await _chatService.sendGroupMessage(
          message: text.trim(),
          messageType: _selectedMessageType != 'normal' ? _selectedMessageType : null,
        );
      } else {
        await _chatService.sendPrivateMessage(
          conversationId: widget.conversationId,
          message: text.trim(),
          messageType: _selectedMessageType != 'normal' ? _selectedMessageType : null,
        );
      }

      _messageController.clear();
      _selectedMessageType = 'normal';

      // Scroll to bottom
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          0,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error sending message: $e')),
        );
      }
    }
  }

  Stream<QuerySnapshot> _getMessagesStream() {
    if (widget.isGroupChat) {
      return _chatService.watchGroupMessages();
    } else {
      return _chatService.watchPrivateMessages(widget.conversationId);
    }
  }

  String _getTitle() {
    if (widget.isGroupChat) {
      return widget.title ?? 'All Staff Chat';
    } else {
      return widget.otherParticipantName ?? 'Private Chat';
    }
  }

  Color _getMessageTypeColor(String? messageType) {
    switch (messageType) {
      case 'emergency':
        return Colors.red;
      case 'alert':
        return Colors.orange;
      case 'announcement':
        return Colors.blue;
      case 'task':
        return Colors.purple;
      default:
        return Colors.transparent;
    }
  }

  IconData _getMessageTypeIcon(String? messageType) {
    switch (messageType) {
      case 'emergency':
        return Icons.warning;
      case 'alert':
        return Icons.notifications;
      case 'announcement':
        return Icons.campaign;
      case 'task':
        return Icons.task;
      default:
        return Icons.chat;
    }
  }

  String _getMessageTypeLabel(String? messageType) {
    switch (messageType) {
      case 'emergency':
        return 'EMERGENCY';
      case 'alert':
        return 'ALERT';
      case 'announcement':
        return 'ANNOUNCEMENT';
      case 'task':
        return 'TASK';
      default:
        return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentUserId = _auth.currentUser?.uid;

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _getTitle(),
              style: const TextStyle(fontSize: 16),
            ),
            if (widget.isGroupChat)
              const Text(
                'Group Chat',
                style: TextStyle(fontSize: 12),
              )
            else
              const Text(
                'Private Chat',
                style: TextStyle(fontSize: 12),
              ),
          ],
        ),
        actions: [
          if (widget.isGroupChat)
            IconButton(
              icon: const Icon(Icons.group),
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Group info coming soon')),
                );
              },
            ),
          IconButton(
            icon: const Icon(Icons.more_vert),
            onPressed: () {
              _showMessageTypeDialog(context);
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Messages List
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: _getMessagesStream(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasError) {
                  return Center(
                    child: Text('Error loading messages: ${snapshot.error}'),
                  );
                }

                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.chat_bubble_outline, size: 64, color: Colors.grey[400]),
                        const SizedBox(height: 16),
                        Text(
                          'No messages yet',
                          style: TextStyle(color: Colors.grey[600], fontSize: 16),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          widget.isGroupChat
                              ? 'Start the conversation in the group chat!'
                              : 'Start the conversation!',
                          style: TextStyle(color: Colors.grey[500], fontSize: 12),
                        ),
                      ],
                    ),
                  );
                }

                final messages = snapshot.data!.docs.reversed.toList();

                // Play sound only for new messages (not already seen)
                if (messages.isNotEmpty && currentUserId != null) {
                  final lastMessage = messages.last;
                  final lastMessageId = lastMessage.id;
                  final lastMessageData = lastMessage.data() as Map<String, dynamic>;
                  final senderId = lastMessageData['senderId'] as String?;
                  
                  // Only play sound if this is a new message from someone else
                  if (lastMessageId != _lastMessageId && 
                      senderId != null && 
                      senderId != currentUserId) {
                    _lastMessageId = lastMessageId;
                    _notificationService.playNotificationSound(
                      messageType: lastMessageData['messageType'] as String?,
                    );
                  }
                }

                return ListView.builder(
                  controller: _scrollController,
                  reverse: true,
                  padding: const EdgeInsets.all(16),
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    final messageDoc = messages[index];
                    final messageData = messageDoc.data() as Map<String, dynamic>;
                    final isMe = messageData['senderId'] == currentUserId;
                    final text = messageData['text'] as String? ?? '';
                    final timestamp = messageData['timestamp'] as Timestamp?;
                    final senderName = messageData['senderName'] as String? ?? 'Unknown';
                    final messageType = messageData['messageType'] as String?;

                    return _MessageBubble(
                      text: text,
                      isMe: isMe,
                      senderName: senderName,
                      timestamp: timestamp?.toDate(),
                      messageType: messageType,
                      getMessageTypeColor: _getMessageTypeColor,
                      getMessageTypeIcon: _getMessageTypeIcon,
                      getMessageTypeLabel: _getMessageTypeLabel,
                    );
                  },
                );
              },
            ),
          ),

          // Message Type Selector (only for group chat)
          if (widget.isGroupChat && _selectedMessageType != 'normal')
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              color: _getMessageTypeColor(_selectedMessageType).withOpacity(0.1),
              child: Row(
                children: [
                  Icon(
                    _getMessageTypeIcon(_selectedMessageType),
                    color: _getMessageTypeColor(_selectedMessageType),
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    _getMessageTypeLabel(_selectedMessageType),
                    style: TextStyle(
                      color: _getMessageTypeColor(_selectedMessageType),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.close, size: 20),
                    onPressed: () {
                      setState(() {
                        _selectedMessageType = 'normal';
                      });
                    },
                  ),
                ],
              ),
            ),

          // Message Input
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  offset: const Offset(0, -2),
                  blurRadius: 4,
                  color: Colors.black.withOpacity(0.1),
                ),
              ],
            ),
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
            child: Row(
              children: [
                if (widget.isGroupChat)
                  IconButton(
                    icon: Icon(
                      Icons.label,
                      color: _selectedMessageType != 'normal'
                          ? _getMessageTypeColor(_selectedMessageType)
                          : Colors.grey,
                    ),
                    onPressed: () => _showMessageTypeDialog(context),
                  ),
                Expanded(
                  child: TextField(
                    controller: _messageController,
                    decoration: InputDecoration(
                      hintText: widget.isGroupChat
                          ? 'Type a message to all staff...'
                          : 'Type a message...',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                    ),
                    maxLines: null,
                    textCapitalization: TextCapitalization.sentences,
                    onSubmitted: (_) => _sendMessage(_messageController.text),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  icon: const Icon(Icons.send),
                  color: Theme.of(context).primaryColor,
                  onPressed: () => _sendMessage(_messageController.text),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showMessageTypeDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Message Type'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: Icon(Icons.chat, color: Colors.grey),
              title: const Text('Normal Message'),
              onTap: () {
                setState(() {
                  _selectedMessageType = 'normal';
                });
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: Icon(Icons.campaign, color: Colors.blue),
              title: const Text('Announcement'),
              onTap: () {
                setState(() {
                  _selectedMessageType = 'announcement';
                });
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: Icon(Icons.task, color: Colors.purple),
              title: const Text('Task'),
              onTap: () {
                setState(() {
                  _selectedMessageType = 'task';
                });
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: Icon(Icons.notifications, color: Colors.orange),
              title: const Text('Alert'),
              onTap: () {
                setState(() {
                  _selectedMessageType = 'alert';
                });
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: Icon(Icons.warning, color: Colors.red),
              title: const Text('Emergency'),
              onTap: () {
                setState(() {
                  _selectedMessageType = 'emergency';
                });
                Navigator.pop(context);
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }
}

class _MessageBubble extends StatelessWidget {
  final String text;
  final bool isMe;
  final String senderName;
  final DateTime? timestamp;
  final String? messageType;
  final Color Function(String?) getMessageTypeColor;
  final IconData Function(String?) getMessageTypeIcon;
  final String Function(String?) getMessageTypeLabel;

  const _MessageBubble({
    required this.text,
    required this.isMe,
    required this.senderName,
    this.timestamp,
    this.messageType,
    required this.getMessageTypeColor,
    required this.getMessageTypeIcon,
    required this.getMessageTypeLabel,
  });

  @override
  Widget build(BuildContext context) {
    final typeColor = getMessageTypeColor(messageType);
    final hasType = messageType != null && messageType != 'normal';

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isMe) ...[
            CircleAvatar(
              radius: 16,
              backgroundColor: hasType ? typeColor : Colors.blue,
              child: Icon(
                hasType ? getMessageTypeIcon(messageType) : Icons.person,
                color: Colors.white,
                size: 16,
              ),
            ),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: hasType && !isMe
                    ? typeColor.withOpacity(0.1)
                    : isMe
                        ? Theme.of(context).primaryColor
                        : Colors.grey[200],
                border: hasType
                    ? Border.all(color: typeColor, width: 2)
                    : null,
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(16),
                  topRight: const Radius.circular(16),
                  bottomLeft: Radius.circular(isMe ? 16 : 0),
                  bottomRight: Radius.circular(isMe ? 0 : 16),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (hasType)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: Row(
                        children: [
                          Icon(
                            getMessageTypeIcon(messageType),
                            size: 14,
                            color: typeColor,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            getMessageTypeLabel(messageType),
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: typeColor,
                            ),
                          ),
                        ],
                      ),
                    ),
                  if (!isMe)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: Text(
                        senderName,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: isMe ? Colors.white70 : Colors.black87,
                        ),
                      ),
                    ),
                  Text(
                    text,
                    style: TextStyle(
                      color: isMe ? Colors.white : Colors.black87,
                      fontSize: 15,
                    ),
                  ),
                  if (timestamp != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(
                        _formatTime(timestamp!),
                        style: TextStyle(
                          fontSize: 10,
                          color: isMe ? Colors.white70 : Colors.black54,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
          if (isMe) ...[
            const SizedBox(width: 8),
            CircleAvatar(
              radius: 16,
              backgroundColor: Theme.of(context).primaryColor.withOpacity(0.3),
              child: Text(
                senderName.substring(0, 1).toUpperCase(),
                style: TextStyle(
                  color: Theme.of(context).primaryColor,
                  fontSize: 12,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  String _formatTime(DateTime dateTime) {
    final hour = dateTime.hour % 12 == 0 ? 12 : dateTime.hour % 12;
    final minute = dateTime.minute.toString().padLeft(2, '0');
    final amPm = dateTime.hour < 12 ? 'AM' : 'PM';
    return '$hour:$minute $amPm';
  }
}