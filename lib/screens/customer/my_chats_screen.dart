import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:timeago/timeago.dart' as timeago;
import '../../services/chat_service.dart';
import '../../models/chat.dart';
import '../../providers/auth_provider.dart';
import '../../providers/locale_provider.dart';
import 'chat_screen.dart';

class MyChatsScreen extends StatefulWidget {
  const MyChatsScreen({super.key});

  @override
  State<MyChatsScreen> createState() => _MyChatsScreenState();
}

class _MyChatsScreenState extends State<MyChatsScreen> {
  final _chatService = ChatService();
  List<ChatModel> _chats = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final customerId = context.read<AuthProvider>().profile?.id;
    if (customerId == null) return;
    final chats = await _chatService.getMyChats(customerId);
    setState(() {
      _chats = chats;
      _isLoading = false;
    });
  }

  Future<void> _startGeneralChat() async {
    final customerId = context.read<AuthProvider>().profile?.id;
    if (customerId == null) return;

    final chatId = await _chatService.getOrCreateGeneralChat(customerId: customerId);
    final isArabic = context.read<LocaleProvider>().isArabic;

    if (mounted) {
      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => ChatScreen(
            chatId: chatId,
            productName: isArabic ? 'استفسار عام' : 'General Inquiry',
          ),
        ),
      );
      _load(); // نحدث القايمة بعد الرجوع، عشان لو الشات الجديد يظهر فورًا
    }
  }

  @override
  Widget build(BuildContext context) {
    final isArabic = context.watch<LocaleProvider>().isArabic;

    return Scaffold(
      appBar: AppBar(title: Text(isArabic ? 'محادثاتي' : 'My Chats'), automaticallyImplyLeading: false),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _startGeneralChat,
        icon: const Icon(Icons.support_agent_rounded),
        label: Text(isArabic ? 'تواصل مع الدعم' : 'Contact Support'),
      ),
      body: RefreshIndicator(
        onRefresh: _load,
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _chats.isEmpty
                ? Center(
                    child: Text(isArabic
                        ? 'لا يوجد محادثات بعد\nاسأل عن أي منتج أو دوس "تواصل مع الدعم" لو عندك استفسار عام'
                        : 'No chats yet\nAsk about any product, or tap "Contact Support" for a general question',
                    textAlign: TextAlign.center),
                  )
                : ListView.builder(
                    itemCount: _chats.length,
                    itemBuilder: (context, i) {
                      final chat = _chats[i];
                      return ListTile(
                        leading: CircleAvatar(
                          backgroundImage: chat.productImage != null ? CachedNetworkImageProvider(chat.productImage!) : null,
                          child: chat.productImage == null
                              ? Icon(chat.isGeneral ? Icons.support_agent_rounded : Icons.phone_android)
                              : null,
                        ),
                        title: Text(chat.productName(isArabic)),
                        subtitle: Text(timeago.format(chat.lastMessageAt, locale: isArabic ? 'ar' : 'en')),
                        trailing: chat.unreadCount > 0
                            ? CircleAvatar(
                                radius: 11,
                                backgroundColor: Theme.of(context).colorScheme.primary,
                                child: Text('${chat.unreadCount}', style: const TextStyle(color: Colors.white, fontSize: 11)),
                              )
                            : const Icon(Icons.chevron_right),
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => ChatScreen(chatId: chat.id, productName: chat.productName(isArabic)),
                          ),
                        ),
                      );
                    },
                  ),
      ),
    );
  }
}