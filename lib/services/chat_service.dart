import 'dart:io';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';
import '../models/chat.dart';
import '../core/constants.dart';

class ChatService {
  final _client = Supabase.instance.client;
  final _uuid = const Uuid();

  /// يبحث عن شات موجود بين العميل والمنتج ده، لو مش موجود يعمل واحد جديد.
  /// ده اللي بيتنفذ لما العميل يدوس "شات" جوه صفحة المنتج.
  Future<String> getOrCreateChat({
    required String productId,
    required String customerId,
  }) async {
    final existing = await _client
        .from('chats')
        .select('id')
        .eq('product_id', productId)
        .eq('customer_id', customerId)
        .maybeSingle();

    if (existing != null) {
      return existing['id'] as String;
    }

    final created = await _client
        .from('chats')
        .insert({
          'product_id': productId,
          'customer_id': customerId,
        })
        .select('id')
        .single();

    return created['id'] as String;
  }

  /// شاتات العميل نفسه (مع عداد الرسايل الغير مقروءة)
  Future<List<ChatModel>> getMyChats(String customerId) async {
    final data = await _client
        .from('chats')
        .select('*, products(name_ar, name_en, product_images(*)), profiles!chats_customer_id_fkey(full_name)')
        .eq('customer_id', customerId)
        .order('last_message_at', ascending: false);

    final chats = (data as List).map((e) => ChatModel.fromJson(e)).toList();
    return _attachUnreadCounts(chats, customerId);
  }

  /// كل الشاتات (للأدمن بس - الصلاحيات بتتحكم فيها الـ RLS في Supabase)
  Future<List<ChatModel>> getAllChats(String adminId) async {
    final data = await _client
        .from('chats')
        .select('*, products(name_ar, name_en, product_images(*)), profiles!chats_customer_id_fkey(full_name)')
        .order('last_message_at', ascending: false);

    final chats = (data as List).map((e) => ChatModel.fromJson(e)).toList();
    return _attachUnreadCounts(chats, adminId);
  }

  /// يحسب عدد الرسايل الغير مقروءة (اللي مش من المستخدم الحالي) لكل شات
  Future<List<ChatModel>> _attachUnreadCounts(List<ChatModel> chats, String currentUserId) async {
    final result = <ChatModel>[];
    for (final chat in chats) {
      final count = await _client
          .from('messages')
          .select('id')
          .eq('chat_id', chat.id)
          .eq('is_read', false)
          .neq('sender_id', currentUserId)
          .count(CountOption.exact);

      result.add(ChatModel(
        id: chat.id,
        productId: chat.productId,
        customerId: chat.customerId,
        lastMessageAt: chat.lastMessageAt,
        createdAt: chat.createdAt,
        productNameAr: chat.productNameAr,
        productNameEn: chat.productNameEn,
        productImage: chat.productImage,
        customerName: chat.customerName,
        unreadCount: count.count,
      ));
    }
    return result;
  }

  /// يعلّم كل رسايل الشات ده كـ "مقروءة" - بينادى عليه لما تفتح الشات
  Future<void> markMessagesAsRead(String chatId, String currentUserId) async {
    await _client
        .from('messages')
        .update({'is_read': true})
        .eq('chat_id', chatId)
        .eq('is_read', false)
        .neq('sender_id', currentUserId);
  }

  Future<List<MessageModel>> getMessages(String chatId) async {
    final data = await _client
        .from('messages')
        .select()
        .eq('chat_id', chatId)
        .order('created_at');

    return (data as List).map((e) => MessageModel.fromJson(e)).toList();
  }

  Future<void> sendMessage({
    required String chatId,
    required String senderId,
    String? content,
    String? imageUrl,
  }) async {
    await _client.from('messages').insert({
      'chat_id': chatId,
      'sender_id': senderId,
      'content': content,
      'image_url': imageUrl,
    });
  }

  Future<String> uploadChatImage(File file) async {
    final fileExt = file.path.split('.').last;
    final fileName = '${_uuid.v4()}.$fileExt';

    await _client.storage.from(AppConstants.chatImagesBucket).upload(fileName, file);
    return _client.storage.from(AppConstants.chatImagesBucket).getPublicUrl(fileName);
  }

  /// Realtime subscription على الرسايل الجديدة في شات معين
  RealtimeChannel subscribeToMessages({
    required String chatId,
    required void Function(MessageModel message) onNewMessage,
  }) {
    final channel = _client
        .channel('messages:$chatId')
        .onPostgresChanges(
          event: PostgresChangeEvent.insert,
          schema: 'public',
          table: 'messages',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'chat_id',
            value: chatId,
          ),
          callback: (payload) {
            onNewMessage(MessageModel.fromJson(payload.newRecord));
          },
        )
        .subscribe();

    return channel;
  }

  void unsubscribe(RealtimeChannel channel) {
    _client.removeChannel(channel);
  }
}
