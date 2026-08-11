import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../../services/chat_service.dart';
import '../../models/chat.dart';
import '../../providers/auth_provider.dart';
import '../../providers/locale_provider.dart';
import '../../widgets/chat_bubble.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ChatScreen extends StatefulWidget {
  final String chatId;
  final String productName;

  const ChatScreen({super.key, required this.chatId, required this.productName});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final _chatService = ChatService();
  final _messageController = TextEditingController();
  final _scrollController = ScrollController();
  final List<MessageModel> _messages = [];
  RealtimeChannel? _channel;
  bool _isLoading = true;
  bool _isSending = false;

  @override
  void initState() {
    super.initState();
    _loadMessages();
    _subscribeRealtime();
  }

  Future<void> _loadMessages() async {
    final messages = await _chatService.getMessages(widget.chatId);
    setState(() {
      _messages.addAll(messages);
      _isLoading = false;
    });
    _scrollToBottom();

    // علّم كل الرسايل كمقروءة أول ما تفتح الشات
    final currentUserId = context.read<AuthProvider>().profile?.id;
    if (currentUserId != null) {
      _chatService.markMessagesAsRead(widget.chatId, currentUserId);
    }
  }

  void _subscribeRealtime() {
    _channel = _chatService.subscribeToMessages(
      chatId: widget.chatId,
      onNewMessage: (message) {
        // تجنب تكرار الرسالة لو هي نفسها اللي بعتناها من نفس الجهاز
        if (_messages.any((m) => m.id == message.id)) return;
        setState(() => _messages.add(message));
        _scrollToBottom();

        // علّمها كمقروءة على طول لأن الشات مفتوح دلوقتي فعليًا
        final currentUserId = context.read<AuthProvider>().profile?.id;
        if (currentUserId != null && message.senderId != currentUserId) {
          _chatService.markMessagesAsRead(widget.chatId, currentUserId);
        }
      },
    );
  }

  Future<void> _refresh() async {
    final messages = await _chatService.getMessages(widget.chatId);
    setState(() {
      _messages
        ..clear()
        ..addAll(messages);
    });
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _sendMessage() async {
    final text = _messageController.text.trim();
    if (text.isEmpty || _isSending) return;

    final senderId = context.read<AuthProvider>().profile?.id;
    if (senderId == null) return;

    setState(() => _isSending = true);
    _messageController.clear();

    await _chatService.sendMessage(
      chatId: widget.chatId,
      senderId: senderId,
      content: text,
    );

    setState(() => _isSending = false);
  }

  Future<void> _sendImage() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery, imageQuality: 70);
    if (picked == null) return;

    final senderId = context.read<AuthProvider>().profile?.id;
    if (senderId == null) return;

    final imageUrl = await _chatService.uploadChatImage(File(picked.path));
    await _chatService.sendMessage(chatId: widget.chatId, senderId: senderId, imageUrl: imageUrl);
  }

  @override
  void dispose() {
    if (_channel != null) _chatService.unsubscribe(_channel!);
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isArabic = context.watch<LocaleProvider>().isArabic;
    final currentUserId = context.watch<AuthProvider>().profile?.id;

    return Scaffold(
      appBar: AppBar(
        title: Column(
          children: [
            Text(widget.productName, style: const TextStyle(fontSize: 16)),
            Text(
              isArabic ? 'شات عن هذا المنتج' : 'Chat about this product',
              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.normal),
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _messages.isEmpty
                    ? Center(child: Text(isArabic ? 'ابدأ المحادثة الآن' : 'Start the conversation'))
                    : RefreshIndicator(
                        onRefresh: _refresh,
                        child: ListView.builder(
                          controller: _scrollController,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          itemCount: _messages.length,
                          itemBuilder: (context, i) {
                            final message = _messages[i];
                            return ChatBubble(message: message, isMe: message.senderId == currentUserId);
                          },
                        ),
                      ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
              child: Row(
                children: [
                  IconButton(icon: const Icon(Icons.image_outlined), onPressed: _sendImage),
                  Expanded(
                    child: TextField(
                      controller: _messageController,
                      decoration: InputDecoration(
                        hintText: isArabic ? 'اكتب رسالة...' : 'Type a message...',
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      ),
                      textInputAction: TextInputAction.send,
                      onSubmitted: (_) => _sendMessage(),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton.filled(
                    icon: const Icon(Icons.send),
                    onPressed: _isSending ? null : _sendMessage,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
