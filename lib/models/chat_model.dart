/// Chat Message Model
/// 
/// Represents chat messages for real-time communication

class ChatMessageModel {
  final int? messageId;
  final int conversationId;
  final int? senderId;
  final String? senderName;
  final String message;
  final String? messageType; // 'text', 'image', 'file'
  final DateTime timestamp;
  final bool isRead;
  final String? attachmentUrl;

  ChatMessageModel({
    this.messageId,
    required this.conversationId,
    this.senderId,
    this.senderName,
    required this.message,
    this.messageType = 'text',
    required this.timestamp,
    this.isRead = false,
    this.attachmentUrl,
  });

  factory ChatMessageModel.fromJson(Map<String, dynamic> json) {
    return ChatMessageModel(
      messageId: json['message_id'] as int? ?? json['id'] as int?,
      conversationId: (json['conversation_id'] as num).toInt(),
      senderId: json['sender_id'] as int? ?? json['user_id'] as int?,
      senderName: json['sender_name'] as String? ?? json['full_name'] as String?,
      message: json['message'] as String,
      messageType: json['message_type'] as String? ?? 'text',
      timestamp: json['timestamp'] != null
          ? DateTime.parse(json['timestamp'] as String)
          : DateTime.now(),
      isRead: (json['is_read'] as num?)?.toInt() == 1 || json['is_read'] == true,
      attachmentUrl: json['attachment_url'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (messageId != null) 'message_id': messageId,
      'conversation_id': conversationId,
      if (senderId != null) 'sender_id': senderId,
      'message': message,
      'message_type': messageType,
      'timestamp': timestamp.toIso8601String(),
      'is_read': isRead ? 1 : 0,
      if (attachmentUrl != null) 'attachment_url': attachmentUrl,
    };
  }

  ChatMessageModel copyWith({
    int? messageId,
    int? conversationId,
    int? senderId,
    String? senderName,
    String? message,
    String? messageType,
    DateTime? timestamp,
    bool? isRead,
    String? attachmentUrl,
  }) {
    return ChatMessageModel(
      messageId: messageId ?? this.messageId,
      conversationId: conversationId ?? this.conversationId,
      senderId: senderId ?? this.senderId,
      senderName: senderName ?? this.senderName,
      message: message ?? this.message,
      messageType: messageType ?? this.messageType,
      timestamp: timestamp ?? this.timestamp,
      isRead: isRead ?? this.isRead,
      attachmentUrl: attachmentUrl ?? this.attachmentUrl,
    );
  }

  static List<ChatMessageModel> fromJsonList(List<dynamic> jsonList) {
    return jsonList.map((json) => ChatMessageModel.fromJson(json as Map<String, dynamic>)).toList();
  }
}

/// Chat Conversation Model
class ChatConversationModel {
  final int? conversationId;
  final String title;
  final List<int> participantIds;
  final ChatMessageModel? lastMessage;
  final int unreadCount;
  final DateTime? lastActivity;

  ChatConversationModel({
    this.conversationId,
    required this.title,
    required this.participantIds,
    this.lastMessage,
    this.unreadCount = 0,
    this.lastActivity,
  });

  factory ChatConversationModel.fromJson(Map<String, dynamic> json) {
    return ChatConversationModel(
      conversationId: json['conversation_id'] as int? ?? json['id'] as int?,
      title: json['title'] as String? ?? 'Conversation',
      participantIds: (json['participant_ids'] as List<dynamic>?)
              ?.map((id) => (id as num).toInt())
              .toList() ??
          [],
      lastMessage: json['last_message'] != null
          ? ChatMessageModel.fromJson(json['last_message'] as Map<String, dynamic>)
          : null,
      unreadCount: (json['unread_count'] as num?)?.toInt() ?? 0,
      lastActivity: json['last_activity'] != null
          ? DateTime.parse(json['last_activity'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (conversationId != null) 'conversation_id': conversationId,
      'title': title,
      'participant_ids': participantIds,
      if (lastMessage != null) 'last_message': lastMessage!.toJson(),
      'unread_count': unreadCount,
      if (lastActivity != null) 'last_activity': lastActivity!.toIso8601String(),
    };
  }
}

