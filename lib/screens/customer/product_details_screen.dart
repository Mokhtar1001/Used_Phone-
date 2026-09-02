import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:share_plus/share_plus.dart';
import '../../services/product_service.dart';
import '../../services/chat_service.dart';
import '../../services/favorites_service.dart';
import '../../services/reviews_service.dart';
import '../../models/product.dart';
import '../../models/review.dart';
import '../../providers/locale_provider.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/guest_guard.dart';
import 'chat_screen.dart';
import 'checkout_screen.dart';

class ProductDetailsScreen extends StatefulWidget {
  final String productId;
  const ProductDetailsScreen({super.key, required this.productId});

  @override
  State<ProductDetailsScreen> createState() => _ProductDetailsScreenState();
}

class _ProductDetailsScreenState extends State<ProductDetailsScreen> {
  final _productService = ProductService();
  final _chatService = ChatService();
  final _favoritesService = FavoritesService();
  final _reviewsService = ReviewsService();

  Product? _product;
  List<Review> _reviews = [];
  double? _avgRating;
  bool _isFavorite = false;
  bool _isStartingChat = false;
  bool _hasError = false;
  bool _viewCounted = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _hasError = false);
    try {
      final product = await _productService.getProductById(widget.productId);
      final reviews = await _reviewsService.getProductReviews(widget.productId);
      final avg = await _reviewsService.getAverageRating(widget.productId);

      final userId = context.read<AuthProvider>().profile?.id;
      bool isFav = false;
      if (userId != null) {
        final favIds = await _favoritesService.getMyFavoriteIds(userId);
        isFav = favIds.contains(widget.productId);
      }

      // زوّد عداد المشاهدات مرة واحدة بس لكل مرة تفتح فيها الشاشة
      if (!_viewCounted) {
        _viewCounted = true;
        _productService.incrementViews(widget.productId);
      }

      setState(() {
        _product = product;
        _reviews = reviews;
        _avgRating = avg;
        _isFavorite = isFav;
      });
    } catch (e) {
      setState(() => _hasError = true);
    }
  }

  Future<void> _toggleFavorite() async {
    if (!await requireLogin(
      context,
      messageAr: 'محتاج تسجل دخول عشان تضيف المنتج للمفضلة',
      messageEn: 'You need to log in to add this to favorites',
    )) return;
    if (!mounted) return;

    final userId = context.read<AuthProvider>().profile?.id;
    if (userId == null) return;
    final newState = await _favoritesService.toggleFavorite(userId, widget.productId);
    if (mounted) setState(() => _isFavorite = newState);
  }

  Future<void> _share() async {
    final isArabic = context.read<LocaleProvider>().isArabic;
    if (_product == null) return;
    final text = isArabic
        ? 'شوف الموبايل ده: ${_product!.nameAr} - ${_product!.price.toStringAsFixed(0)} ج.م'
        : 'Check this phone: ${_product!.nameEn} - ${_product!.price.toStringAsFixed(0)} EGP';
    await Share.share(text);
  }

  Future<void> _startChat() async {
    if (!await requireLogin(
      context,
      messageAr: 'محتاج تسجل دخول عشان تبدأ محادثة مع البائع',
      messageEn: 'You need to log in to start a chat with the seller',
    )) return;
    if (!mounted) return;

    setState(() => _isStartingChat = true);
    final auth = context.read<AuthProvider>();
    final customerId = auth.profile?.id;

    if (customerId == null) {
      setState(() => _isStartingChat = false);
      return;
    }

    final chatId = await _chatService.getOrCreateChat(
      productId: widget.productId,
      customerId: customerId,
    );

    setState(() => _isStartingChat = false);
    if (mounted && _product != null) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => ChatScreen(
            chatId: chatId,
            productName: _product!.name(context.read<LocaleProvider>().isArabic),
          ),
        ),
      );
    }
  }

  void _showReviewDialog() {
    final isArabic = context.read<LocaleProvider>().isArabic;
    int rating = 5;
    final commentController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text(isArabic ? 'قيّم المنتج' : 'Rate this product'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(5, (i) => IconButton(
                      icon: Icon(i < rating ? Icons.star : Icons.star_border, color: const Color(0xFFFFC107)),
                      onPressed: () => setDialogState(() => rating = i + 1),
                    )),
              ),
              TextField(
                controller: commentController,
                decoration: InputDecoration(hintText: isArabic ? 'تعليق (اختياري)' : 'Comment (optional)'),
                maxLines: 2,
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: Text(isArabic ? 'إلغاء' : 'Cancel')),
            TextButton(
              onPressed: () async {
                final customerId = context.read<AuthProvider>().profile?.id;
                if (customerId != null) {
                  await _reviewsService.addOrUpdateReview(
                    productId: widget.productId,
                    customerId: customerId,
                    rating: rating,
                    comment: commentController.text.trim().isEmpty ? null : commentController.text.trim(),
                  );
                  if (context.mounted) {
                    Navigator.pop(context);
                    _load();
                  }
                }
              },
              child: Text(isArabic ? 'إرسال' : 'Submit'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isArabic = context.watch<LocaleProvider>().isArabic;

    if (_hasError) {
      return Scaffold(
        appBar: AppBar(),
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline, size: 48, color: Colors.grey),
              const SizedBox(height: 12),
              Text(isArabic ? 'حصل خطأ أثناء تحميل المنتج' : 'Something went wrong loading this product'),
              const SizedBox(height: 16),
              ElevatedButton(onPressed: _load, child: Text(isArabic ? 'حاول تاني' : 'Retry')),
            ],
          ),
        ),
      );
    }

    if (_product == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final product = _product!;

    return Scaffold(
      appBar: AppBar(
        title: Text(isArabic ? 'تفاصيل المنتج' : 'Product Details'),
        actions: [
          IconButton(icon: const Icon(Icons.share_outlined), onPressed: _share),
          IconButton(
            icon: Icon(_isFavorite ? Icons.favorite : Icons.favorite_border, color: _isFavorite ? Colors.red : null),
            onPressed: _toggleFavorite,
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _load,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                height: 280,
                child: product.images.isEmpty
                    ? Container(color: Colors.grey.shade200, child: const Icon(Icons.phone_android, size: 80))
                    : PageView.builder(
                        itemCount: product.images.length,
                        itemBuilder: (context, i) => CachedNetworkImage(
                          imageUrl: product.images[i],
                          fit: BoxFit.cover,
                        ),
                      ),
              ),
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(product.name(isArabic), style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                        ),
                        Icon(Icons.remove_red_eye_outlined, size: 16, color: Colors.grey.shade500),
                        const SizedBox(width: 4),
                        Text('${product.viewsCount}', style: TextStyle(color: Colors.grey.shade500, fontSize: 12)),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Text(
                          '${product.price.toStringAsFixed(0)} ${isArabic ? 'ج.م' : 'EGP'}',
                          style: TextStyle(fontSize: 20, color: Theme.of(context).colorScheme.primary, fontWeight: FontWeight.w600),
                        ),
                        if (_avgRating != null) ...[
                          const SizedBox(width: 12),
                          const Icon(Icons.star, size: 18, color: Color(0xFFFFC107)),
                          const SizedBox(width: 2),
                          Text('${_avgRating!.toStringAsFixed(1)} (${_reviews.length})'),
                        ],
                      ],
                    ),
                    const SizedBox(height: 16),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        if (product.brand != null && product.brand!.isNotEmpty) _InfoChip(icon: Icons.branding_watermark, label: product.brand!),
                        if (product.storage != null && product.storage!.isNotEmpty) _InfoChip(icon: Icons.sd_storage, label: product.storage!),
                        if (product.color != null && product.color!.isNotEmpty) _InfoChip(icon: Icons.color_lens, label: product.color!),
                        if (product.condition != null) _InfoChip(icon: Icons.verified, label: _conditionLabel(product.condition!, isArabic)),
                      ],
                    ),
                    const SizedBox(height: 20),
                    Text(isArabic ? 'الوصف' : 'Description', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    const SizedBox(height: 8),
                    Text(product.description(isArabic), style: const TextStyle(height: 1.5)),
                    const SizedBox(height: 24),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(isArabic ? 'التقييمات (${_reviews.length})' : 'Reviews (${_reviews.length})',
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                        TextButton.icon(
                          onPressed: _showReviewDialog,
                          icon: const Icon(Icons.star_border, size: 18),
                          label: Text(isArabic ? 'قيّم' : 'Rate'),
                        ),
                      ],
                    ),
                    if (_reviews.isEmpty)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        child: Text(isArabic ? 'لا يوجد تقييمات بعد' : 'No reviews yet', style: TextStyle(color: Colors.grey.shade500)),
                      )
                    else
                      ..._reviews.map((r) => Padding(
                            padding: const EdgeInsets.symmetric(vertical: 6),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Text(r.customerName ?? (isArabic ? 'عميل' : 'Customer'), style: const TextStyle(fontWeight: FontWeight.w600)),
                                    const SizedBox(width: 6),
                                    ...List.generate(5, (i) => Icon(i < r.rating ? Icons.star : Icons.star_border, size: 13, color: const Color(0xFFFFC107))),
                                  ],
                                ),
                                if (r.comment != null) Text(r.comment!, style: TextStyle(color: Colors.grey.shade700)),
                              ],
                            ),
                          )),
                    const SizedBox(height: 100),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              if (product.status != 'sold')
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () async {
                      if (!await requireLogin(context)) return;
                      if (!context.mounted) return;
                      Navigator.push(context, MaterialPageRoute(builder: (_) => CheckoutScreen(product: product)));
                    },
                    icon: const Icon(Icons.credit_card, size: 18),
                    label: Text(isArabic ? 'شراء' : 'Buy'),
                  ),
                ),
              if (product.status != 'sold') const SizedBox(width: 10),
              Expanded(
                flex: 2,
                child: ElevatedButton.icon(
                  onPressed: (product.status == 'sold' || _isStartingChat) ? null : _startChat,
                  icon: _isStartingChat
                      ? const SizedBox(height: 16, width: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : const Icon(Icons.chat_bubble_outline),
                  label: Text(isArabic ? 'شات عن هذا المنتج' : 'Chat about this product'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _conditionLabel(String condition, bool isArabic) {
    switch (condition) {
      case 'excellent':
        return isArabic ? 'ممتازة' : 'Excellent';
      case 'good':
        return isArabic ? 'جيدة' : 'Good';
      case 'fair':
        return isArabic ? 'مقبولة' : 'Fair';
      default:
        return condition;
    }
  }
}

class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String label;
  const _InfoChip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Chip(
      avatar: Icon(icon, size: 16),
      label: Text(label),
    );
  }
}