import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/message.dart';
import '../models/user_profile.dart';

class MessageService {
  final SupabaseClient _supabase;

  MessageService(this._supabase);

  Future<void> sendMessage({
    required String senderId,
    required String receiverId,
    String? content,
    MessageType messageType = MessageType.text,
    String? fileUrl,
  }) async {
    await _supabase.from('messages').insert({
      'sender_id': senderId,
      'receiver_id': receiverId,
      'content': content,
      'message_type': messageType.name,
      'file_url': fileUrl,
    });
  }

  Future<List<Message>> getConversation(
    String userId,
    String otherUserId,
  ) async {
    final response = await _supabase
        .from('messages')
        .select('''
          *,
          sender:profiles!sender_id(*),
          receiver:profiles!receiver_id(*)
        ''')
        .or('and(sender_id.eq.$userId,receiver_id.eq.$otherUserId),and(sender_id.eq.$otherUserId,receiver_id.eq.$userId)')
        .order('created_at');

    return (response as List).map((e) => Message.fromJson(e)).toList();
  }

  Future<List<Conversation>> getConversations(String userId) async {
    final response = await _supabase
        .from('messages')
        .select('''
          *,
          sender:profiles!sender_id(*),
          receiver:profiles!receiver_id(*)
        ''')
        .or('sender_id.eq.$userId,receiver_id.eq.$userId')
        .order('created_at', ascending: false);

    final messages = (response as List).map((e) => Message.fromJson(e)).toList();

    final conversationMap = <String, Conversation>{};

    for (final message in messages) {
      final otherUserId =
          message.senderId == userId ? message.receiverId : message.senderId;

      if (conversationMap.containsKey(otherUserId)) continue;

      final otherUser = message.senderId == userId
          ? message.receiver
          : message.sender;

      if (otherUser == null) continue;

      final unreadCount = messages
          .where((m) =>
              m.senderId == otherUserId &&
              m.receiverId == userId &&
              m.readAt == null)
          .length;

      conversationMap[otherUserId] = Conversation(
        otherUser: otherUser,
        lastMessage: message,
        unreadCount: unreadCount,
      );
    }

    return conversationMap.values.toList();
  }

  Future<void> markAsRead(String userId, String otherUserId) async {
    await _supabase
        .from('messages')
        .update({'read_at': DateTime.now().toIso8601String()})
        .eq('receiver_id', userId)
        .eq('sender_id', otherUserId)
        .is_('read_at', null);
  }

  Future<void> sendBroadcast({
    required String adminId,
    required String content,
    String? targetRole,
  }) async {
    await _supabase.from('broadcast_messages').insert({
      'admin_id': adminId,
      'content': content,
      'target_role': targetRole,
    });
  }

  Stream<List<Message>> getMessageStream(
    String userId,
    String otherUserId,
  ) {
    return _supabase
        .from('messages')
        .select('''
          *,
          sender:profiles!sender_id(*),
          receiver:profiles!receiver_id(*)
        ''')
        .or('and(sender_id.eq.$userId,receiver_id.eq.$otherUserId),and(sender_id.eq.$otherUserId,receiver_id.eq.$userId)')
        .order('created_at')
        .asStream()
        .map((event) =>
            (event as List).map((e) => Message.fromJson(e)).toList());
  }

  Future<int> getUnreadCount(String userId) async {
    final response = await _supabase
        .from('messages')
        .select('id')
        .eq('receiver_id', userId)
        .is_('read_at', null);

    return (response as List).length;
  }
}