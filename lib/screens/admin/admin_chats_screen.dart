import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:timeago/timeago.dart' as timeago;
import '../../services/chat_service.dart';
import '../../models/chat.dart';
import '../../providers/locale_provider.dart';
import '../../providers/auth_provider.dart';
import '../customer/chat_screen.dart';

class AdminChatsScreen extends StatefulWidget {
  const AdminChatsScreen({super.key});

  @override
  State<AdminChatsScreen> createState() => _AdminChatsScreenState();
}

class _AdminChatsScreenState extends State<AdminChatsScreen> {
  final _chatService = ChatService();
  List<ChatModel> _chats = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _isLoading = true);
    final adminId = context.read<AuthProvider>().profile?.id;
    if (adminId == null) return;
    // بيرجع كل الشاتات لأن المستخدم الحالي أدمن - RLS بتسمح له يشوف الكل
    final chats = await _chatService.getAllChats(adminId);
    setState(() {
      _chats = chats;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final isArabic = context.watch<LocaleProvider>().isArabic;

    return Scaffold(
      appBar: AppBar(title: Text(isArabic ? 'كل المحادثات' : 'All Chats'), automaticallyImplyLeading: false),
      body: RefreshIndicator(
        onRefresh: _load,
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _chats.isEmpty
                ? Center(child: Text(isArabic ? 'لا يوجد محادثات بعد' : 'No chats yet'))
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
                        subtitle: Text(
                          '${chat.customerName ?? (isArabic ? "عميل" : "Customer")} • ${timeago.format(chat.lastMessageAt, locale: isArabic ? 'ar' : 'en')}',
                        ),
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