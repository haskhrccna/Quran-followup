import 'user_profile.dart';

enum MessageType { text, file, system }

class Message {
  final String id;
  final String senderId;
  final String receiverId;
  final String? content;
  final MessageType messageType;
  final String? fileUrl;
  final DateTime? readAt;
  final DateTime createdAt;
  final UserProfile? sender;
  final UserProfile? receiver;

  Message({
    required this.id,
    required this.senderId,
    required this.receiverId,
    this.content,
    required this.messageType,
    this.fileUrl,
    this.readAt,
    required this.createdAt,
    this.sender,
    this.receiver,
  });

  bool get isRead => readAt != null;
  bool get isText => messageType == MessageType.text;
  bool get isFile => messageType == MessageType.file;
  bool get isSystem => messageType == MessageType.system;

  factory Message.fromJson(Map<String, dynamic> json) {
    return Message(
      id: json['id'] as String,
      senderId: json['sender_id'] as String,
      receiverId: json['receiver_id'] as String,
      content: json['content'] as String?,
      messageType: MessageType.values.firstWhere(
        (e) => e.name == json['message_type'],
        orElse: () => MessageType.text,
      ),
      fileUrl: json['file_url'] as String?,
      readAt: json['read_at'] != null
          ? DateTime.parse(json['read_at'] as String)
          : null,
      createdAt: DateTime.parse(json['created_at'] as String),
      sender: json['sender'] != null
          ? UserProfile.fromJson(json['sender'] as Map<String, dynamic>)
          : null,
      receiver: json['receiver'] != null
          ? UserProfile.fromJson(json['receiver'] as Map<String, dynamic>)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'sender_id': senderId,
      'receiver_id': receiverId,
      'content': content,
      'message_type': messageType.name,
      'file_url': fileUrl,
      'read_at': readAt?.toIso8601String(),
      'created_at': createdAt.toIso8601String(),
    };
  }

  Message copyWith({
    String? id,
    String? senderId,
    String? receiverId,
    String? content,
    MessageType? messageType,
    String? fileUrl,
    DateTime? readAt,
    DateTime? createdAt,
    UserProfile? sender,
    UserProfile? receiver,
  }) {
    return Message(
      id: id ?? this.id,
      senderId: senderId ?? this.senderId,
      receiverId: receiverId ?? this.receiverId,
      content: content ?? this.content,
      messageType: messageType ?? this.messageType,
      fileUrl: fileUrl ?? this.fileUrl,
      readAt: readAt ?? this.readAt,
      createdAt: createdAt ?? this.createdAt,
      sender: sender ?? this.sender,
      receiver: receiver ?? this.receiver,
    );
  }
}

class Conversation {
  final UserProfile otherUser;
  final Message lastMessage;
  final int unreadCount;

  Conversation({
    required this.otherUser,
    required this.lastMessage,
    required this.unreadCount,
  });
}