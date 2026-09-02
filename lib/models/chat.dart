class ChatModel {
  final String id;
  final String? productId; // null = شات عام (استفسار عام مش مربوط بمنتج)
  final String customerId;
  final DateTime lastMessageAt;
  final DateTime createdAt;
  // joined data (optional, populated when fetched with relations)
  final String? productNameAr;
  final String? productNameEn;
  final String? productImage;
  final String? customerName;
  final String? lastMessagePreview;
  final int unreadCount;

  ChatModel({
    required this.id,
    this.productId,
    required this.customerId,
    required this.lastMessageAt,
    required this.createdAt,
    this.productNameAr,
    this.productNameEn,
    this.productImage,
    this.customerName,
    this.lastMessagePreview,
    this.unreadCount = 0,
  });

  bool get isGeneral => productId == null;

  String productName(bool isArabic) {
    if (isGeneral) return isArabic ? 'استفسار عام' : 'General Inquiry';
    return (isArabic ? productNameAr : productNameEn) ?? '';
  }

  factory ChatModel.fromJson(Map<String, dynamic> json) {
    final product = json['products'];
    final customer = json['profiles'];
    final images = product != null ? product['product_images'] as List<dynamic>? : null;

    return ChatModel(
      id: json['id'],
      productId: json['product_id'],
      customerId: json['customer_id'],
      lastMessageAt: DateTime.parse(json['last_message_at']),
      createdAt: DateTime.parse(json['created_at']),
      productNameAr: product?['name_ar'],
      productNameEn: product?['name_en'],
      productImage: (images != null && images.isNotEmpty) ? images.first['image_url'] : null,
      customerName: customer?['full_name'],
      unreadCount: json['unread_count'] ?? 0,
    );
  }
}

class MessageModel {
  final String id;
  final String chatId;
  final String senderId;
  final String? content;
  final String? imageUrl;
  final bool isRead;
  final DateTime createdAt;

  MessageModel({
    required this.id,
    required this.chatId,
    required this.senderId,
    this.content,
    this.imageUrl,
    required this.isRead,
    required this.createdAt,
  });

  factory MessageModel.fromJson(Map<String, dynamic> json) {
    return MessageModel(
      id: json['id'],
      chatId: json['chat_id'],
      senderId: json['sender_id'],
      content: json['content'],
      imageUrl: json['image_url'],
      isRead: json['is_read'] ?? false,
      createdAt: DateTime.parse(json['created_at']),
    );
  }
}