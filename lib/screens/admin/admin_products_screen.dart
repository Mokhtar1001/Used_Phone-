import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/product_provider.dart';
import '../../providers/locale_provider.dart';
import '../../widgets/product_card.dart';
import '../customer/product_details_screen.dart';
import 'add_edit_product_screen.dart';
import 'sold_history_screen.dart';

class AdminProductsScreen extends StatefulWidget {
  const AdminProductsScreen({super.key});

  @override
  State<AdminProductsScreen> createState() => _AdminProductsScreenState();
}

class _AdminProductsScreenState extends State<AdminProductsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = context.read<ProductProvider>();
      provider.loadCategories();
      provider.loadProducts();
    });
  }

  @override
  Widget build(BuildContext context) {
    final isArabic = context.watch<LocaleProvider>().isArabic;
    final productProvider = context.watch<ProductProvider>();

    return Scaffold(
      appBar: AppBar(
        title: Text(isArabic ? 'لوحة التحكم' : 'Admin Dashboard'),
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.history),
            tooltip: isArabic ? 'سجل المبيعات' : 'Sales History',
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SoldHistoryScreen())),
          ),
        ],
      ),
      body: productProvider.isLoading
          ? const Center(child: CircularProgressIndicator())
          : productProvider.hasError
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.error_outline, size: 40, color: Colors.grey),
                      const SizedBox(height: 8),
                      Text(isArabic ? 'حصل خطأ، حاول تاني' : 'Something went wrong'),
                      const SizedBox(height: 12),
                      ElevatedButton(
                        onPressed: () => context.read<ProductProvider>().loadProducts(),
                        child: Text(isArabic ? 'حاول تاني' : 'Retry'),
                      ),
                    ],
                  ),
                )
              : productProvider.products.isEmpty
              ? Center(child: Text(isArabic ? 'لا يوجد منتجات - أضف أول منتج' : 'No products yet - add your first one'))
              : RefreshIndicator(
                  onRefresh: () => context.read<ProductProvider>().loadProducts(),
                  child: GridView.builder(
                    padding: const EdgeInsets.all(16),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      childAspectRatio: 0.68,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                    ),
                    itemCount: productProvider.products.length,
                    itemBuilder: (context, i) {
                      final product = productProvider.products[i];
                      return Stack(
                        children: [
                          ProductCard(
                            product: product,
                            isArabic: isArabic,
                            onTap: () => Navigator.push(
                              context,
                              MaterialPageRoute(builder: (_) => ProductDetailsScreen(productId: product.id)),
                            ),
                          ),
                          // زرار واضح (⋮) للتعديل/الحذف - بدل ما يبقى مخفي جوه ضغطة مطولة
                          // Badge عدد المشاهدات - Analytics بسيطة للأدمن
                          Positioned(
                            bottom: 44,
                            left: isArabic ? null : 6,
                            right: isArabic ? 6 : null,
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: Colors.black.withValues(alpha: 0.6),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(Icons.remove_red_eye_outlined, size: 11, color: Colors.white),
                                  const SizedBox(width: 3),
                                  Text('${product.viewsCount}', style: const TextStyle(color: Colors.white, fontSize: 10)),
                                ],
                              ),
                            ),
                          ),
                          Positioned(
                            top: 4,
                            right: isArabic ? null : 4,
                            left: isArabic ? 4 : null,
                            child: Material(
                              color: Colors.black.withValues(alpha: 0.55),
                              shape: const CircleBorder(),
                              child: InkWell(
                                customBorder: const CircleBorder(),
                                onTap: () => _showActions(context, product.id, isArabic),
                                child: const Padding(
                                  padding: EdgeInsets.all(6),
                                  child: Icon(Icons.more_vert, color: Colors.white, size: 18),
                                ),
                              ),
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          await Navigator.push(context, MaterialPageRoute(builder: (_) => const AddEditProductScreen()));
          if (context.mounted) context.read<ProductProvider>().loadProducts();
        },
        icon: const Icon(Icons.add),
        label: Text(isArabic ? 'إضافة منتج' : 'Add Product'),
      ),
    );
  }

  void _showActions(BuildContext context, String productId, bool isArabic) {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.edit),
              title: Text(isArabic ? 'تعديل' : 'Edit'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(context, MaterialPageRoute(builder: (_) => AddEditProductScreen(productId: productId)));
              },
            ),
            ListTile(
              leading: const Icon(Icons.check_circle_outline),
              title: Text(isArabic ? 'تحديد كـ متاح' : 'Mark as Available'),
              onTap: () {
                Navigator.pop(context);
                context.read<ProductProvider>().updateStatus(productId, 'available');
              },
            ),
            ListTile(
              leading: const Icon(Icons.pause_circle_outline),
              title: Text(isArabic ? 'تحديد كـ محجوز' : 'Mark as Reserved'),
              onTap: () {
                Navigator.pop(context);
                context.read<ProductProvider>().updateStatus(productId, 'reserved');
              },
            ),
            ListTile(
              leading: const Icon(Icons.sell_outlined),
              title: Text(isArabic ? 'تحديد كـ تم البيع' : 'Mark as Sold'),
              onTap: () {
                Navigator.pop(context);
                context.read<ProductProvider>().updateStatus(productId, 'sold');
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete_outline, color: Colors.red),
              title: Text(isArabic ? 'حذف' : 'Delete', style: const TextStyle(color: Colors.red)),
              onTap: () {
                Navigator.pop(context);
                _confirmDelete(context, productId, isArabic);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _confirmDelete(BuildContext context, String productId, bool isArabic) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(isArabic ? 'تأكيد الحذف' : 'Confirm Delete'),
        content: Text(isArabic ? 'هل أنت متأكد من حذف هذا المنتج؟ لا يمكن التراجع.' : 'Are you sure? This cannot be undone.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: Text(isArabic ? 'إلغاء' : 'Cancel')),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              context.read<ProductProvider>().deleteProduct(productId);
            },
            child: Text(isArabic ? 'حذف' : 'Delete', style: const TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}
