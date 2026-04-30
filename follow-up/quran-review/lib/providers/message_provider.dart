import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/message.dart';
import '../services/message_service.dart';
import 'auth_provider.dart';

final messageServiceProvider = Provider<MessageService>((ref) {
  return MessageService(ref.watch(supabaseProvider));
});

final conversationsProvider = FutureProvider.family<List<Conversation>, String>((ref, userId) async {
  return ref.watch(messageServiceProvider).getConversations(userId);
});

final conversationProvider = FutureProvider.family<List<Message>, ({String userId, String otherUserId})>((ref, params) async {
  return ref.watch(messageServiceProvider).getConversation(params.userId, params.otherUserId);
});

final unreadCountProvider = FutureProvider.family<int, String>((ref, userId) async {
  return ref.watch(messageServiceProvider).getUnreadCount(userId);
});

class MessageNotifier extends StateNotifier<AsyncValue<void>> {
  final MessageService _service;

  MessageNotifier(this._service) : super(const AsyncValue.data(null));

  Future<void> sendMessage({
    required String senderId,
    required String receiverId,
    String? content,
    MessageType messageType = MessageType.text,
    String? fileUrl,
  }) async {
    state = const AsyncValue.loading();
    try {
      await _service.sendMessage(
        senderId: senderId,
        receiverId: receiverId,
        content: content,
        messageType: messageType,
        fileUrl: fileUrl,
      );
      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> markAsRead(String userId, String otherUserId) async {
    await _service.markAsRead(userId, otherUserId);
  }

  Future<void> sendBroadcast({
    required String adminId,
    required String content,
    String? targetRole,
  }) async {
    state = const AsyncValue.loading();
    try {
      await _service.sendBroadcast(
        adminId: adminId,
        content: content,
        targetRole: targetRole,
      );
      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }
}

final messageNotifierProvider = StateNotifierProvider<MessageNotifier, AsyncValue<void>>((ref) {
  return MessageNotifier(ref.watch(messageServiceProvider));
});

final messageStreamProvider = StreamProvider.family<List<Message>, ({String userId, String otherUserId})>((ref, params) {
  return ref.watch(messageServiceProvider).getMessageStream(params.userId, params.otherUserId);
});