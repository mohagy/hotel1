/// Messages List Screen
/// 
/// Displays group chat and private conversations

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../services/chat_service.dart';
import '../../services/notification_service.dart';
import '../../core/theme/app_theme.dart';
import 'chat_screen.dart';

class MessagesListScreen extends StatefulWidget {
  const MessagesListScreen({Key? key}) : super(key: key);

  @override
  State<MessagesListScreen> createState() => _MessagesListScreenState();
}

class _MessagesListScreenState extends State<MessagesListScreen> {
  final ChatService _chatService = ChatService();
  final NotificationService _notificationService = NotificationService();
  final FirebaseAuth _auth = FirebaseAuth.instance;

  @override
  void initState() {
    super.initState();
    // Initialize group chat if it doesn't exist
    _chatService.getOrCreateGroupChat();
  }

  @override
  Widget build(BuildContext context) {
    final currentUserId = _auth.currentUser?.uid;
    if (currentUserId == null) {
      return const Scaffold(
        body: Center(child: Text('Please log in to view messages')),
      );
    }

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: const Text('Messages'),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () {
              _showSearchDialog(context);
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Group Chat Section
          _buildGroupChatSection(currentUserId),
          
          const Divider(height: 1),
          
          // Private Chats Section
          Expanded(
            child: _buildPrivateChatsSection(currentUserId),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showNewConversationDialog(context),
        child: const Icon(Icons.add_comment),
      ),
    );
  }

  Widget _buildGroupChatSection(String currentUserId) {
    return StreamBuilder<DocumentSnapshot>(
      stream: _chatService.watchGroupChat(),
      builder: (context, snapshot) {
        if (!snapshot.hasData || !snapshot.data!.exists) {
          return const SizedBox.shrink();
        }

        final data = snapshot.data!.data() as Map<String, dynamic>;
        final lastMessage = data['lastMessage'] as String? ?? '';
        final lastMessageTime = data['lastMessageTime'] as Timestamp?;
        final lastSenderName = data['lastSenderName'] as String? ?? '';

        return Container(
          decoration: BoxDecoration(
            color: Theme.of(context).primaryColor.withOpacity(0.1),
            border: Border(
              bottom: BorderSide(
                color: Theme.of(context).primaryColor.withOpacity(0.2),
                width: 1,
              ),
            ),
          ),
          child: ListTile(
            leading: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Theme.of(context).primaryColor,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.group,
                color: Colors.white,
                size: 24,
              ),
            ),
            title: Row(
              children: [
                const Text(
                  'All Staff Chat',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: Theme.of(context).primaryColor,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Text(
                    'GROUP',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            subtitle: lastMessage.isNotEmpty
                ? Text(
                    '$lastSenderName: $lastMessage',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  )
                : const Text('No messages yet'),
            trailing: lastMessageTime != null
                ? Text(
                    _formatTime(lastMessageTime.toDate()),
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  )
                : null,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => ChatScreen(
                    conversationId: ChatService.groupChatId,
                    isGroupChat: true,
                    title: 'All Staff Chat',
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildPrivateChatsSection(String currentUserId) {
    return StreamBuilder<QuerySnapshot>(
      stream: _chatService.watchConversations(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(
            child: Text('Error loading conversations: ${snapshot.error}'),
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
                  'No private conversations yet',
                  style: TextStyle(color: Colors.grey[600], fontSize: 16),
                ),
                const SizedBox(height: 8),
                Text(
                  'Tap the + button to start a conversation',
                  style: TextStyle(color: Colors.grey[500], fontSize: 12),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          );
        }

        final conversations = snapshot.data!.docs
            .where((doc) {
              final data = doc.data() as Map<String, dynamic>;
              return data['type'] != 'group'; // Filter out group chat
            })
            .toList();

        if (conversations.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.chat_bubble_outline, size: 64, color: Colors.grey[400]),
                const SizedBox(height: 16),
                Text(
                  'No private conversations yet',
                  style: TextStyle(color: Colors.grey[600], fontSize: 16),
                ),
                const SizedBox(height: 8),
                Text(
                  'Tap the + button to start a conversation',
                  style: TextStyle(color: Colors.grey[500], fontSize: 12),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(8),
          itemCount: conversations.length,
          itemBuilder: (context, index) {
            final conversation = conversations[index];
            final data = conversation.data() as Map<String, dynamic>;
            final participants = List<String>.from(data['participants'] ?? []);
            final otherParticipantId = participants.firstWhere(
              (id) => id != currentUserId,
              orElse: () => '',
            );
            final lastMessage = data['lastMessage'] as String? ?? '';
            final lastMessageTime = data['lastMessageTime'] as Timestamp?;
            final unreadCount = data['unreadCount_$currentUserId'] as int? ?? 0;
            final otherParticipantName = data['otherParticipantName_$currentUserId'] as String? ??
                data['otherParticipantName'] as String? ??
                'Unknown User';

            return ListTile(
              leading: CircleAvatar(
                backgroundColor: Theme.of(context).primaryColor,
                child: Text(
                  otherParticipantName.isNotEmpty
                      ? otherParticipantName[0].toUpperCase()
                      : otherParticipantId.isNotEmpty
                          ? otherParticipantId[0].toUpperCase()
                          : '?',
                  style: const TextStyle(color: Colors.white),
                ),
              ),
              title: Text(
                otherParticipantName,
                style: TextStyle(
                  fontWeight: unreadCount > 0 ? FontWeight.bold : FontWeight.normal,
                ),
              ),
              subtitle: Text(
                lastMessage,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              trailing: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  if (lastMessageTime != null)
                    Text(
                      _formatTime(lastMessageTime.toDate()),
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                  if (unreadCount > 0)
                    Container(
                      margin: const EdgeInsets.only(top: 4),
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.red,
                        borderRadius: BorderRadius.circular(12),
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
              ),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ChatScreen(
                      conversationId: conversation.id,
                      isGroupChat: false,
                      otherParticipantId: otherParticipantId,
                      otherParticipantName: otherParticipantName,
                    ),
                  ),
                );
              },
            );
          },
        );
      },
    );
  }

  String _formatTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inDays == 0) {
      return '${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
    } else if (difference.inDays == 1) {
      return 'Yesterday';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} days ago';
    } else {
      return '${dateTime.day}/${dateTime.month}/${dateTime.year}';
    }
  }

  void _showSearchDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Search Messages'),
        content: const Text('Search functionality coming soon'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _showNewConversationDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (dialogContext) => Dialog(
        child: Container(
          width: 400,
          height: 500,
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Start New Conversation',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(dialogContext),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              const Text(
                'Select a user to start a private conversation:',
                style: TextStyle(fontSize: 14, color: Colors.grey),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: StreamBuilder<QuerySnapshot>(
                  stream: _chatService.watchUsers(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    if (snapshot.hasError) {
                      return Center(
                        child: Text('Error loading users: ${snapshot.error}'),
                      );
                    }

                    if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                      return const Center(
                        child: Text('No users available'),
                      );
                    }

                    final users = snapshot.data!.docs;
                    final currentUserId = _auth.currentUser?.uid;

                    // Filter out current user
                    final otherUsers = users.where((doc) {
                      final data = doc.data() as Map<String, dynamic>;
                      final userId = doc.id; // Firestore document ID or uid field
                      return userId != currentUserId;
                    }).toList();

                    if (otherUsers.isEmpty) {
                      return const Center(
                        child: Text('No other users available'),
                      );
                    }

                    return ListView.builder(
                      itemCount: otherUsers.length,
                      itemBuilder: (context, index) {
                        final userDoc = otherUsers[index];
                        final userData = userDoc.data() as Map<String, dynamic>;
                        final userId = userDoc.id;
                        final userName = userData['email'] as String? ?? 
                                       userData['displayName'] as String? ?? 
                                       userData['name'] as String? ?? 
                                       'User ${userId.substring(0, 8)}';
                        final userEmail = userData['email'] as String? ?? '';

                        return ListTile(
                          leading: CircleAvatar(
                            backgroundColor: Theme.of(context).primaryColor,
                            child: Text(
                              userName.isNotEmpty
                                  ? userName[0].toUpperCase()
                                  : userEmail.isNotEmpty
                                      ? userEmail[0].toUpperCase()
                                      : '?',
                              style: const TextStyle(color: Colors.white),
                            ),
                          ),
                          title: Text(userName),
                          subtitle: userEmail.isNotEmpty ? Text(userEmail) : null,
                          onTap: () async {
                            Navigator.pop(dialogContext);
                            
                            try {
                              // Get or create conversation
                              final conversationId = await _chatService.getOrCreatePrivateConversation(userId);
                              
                              // Navigate to chat screen
                              if (context.mounted) {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => ChatScreen(
                                      conversationId: conversationId,
                                      isGroupChat: false,
                                      otherParticipantId: userId,
                                      otherParticipantName: userName,
                                    ),
                                  ),
                                );
                              }
                            } catch (e) {
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text('Error starting conversation: $e')),
                                );
                              }
                            }
                          },
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}