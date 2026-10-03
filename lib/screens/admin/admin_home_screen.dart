import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import '../../providers/locale_provider.dart';
import '../../providers/auth_provider.dart';
import '../../core/theme.dart';
import '../../core/responsive.dart';
import '../../services/analytics_service.dart';
import '../../models/product.dart';
import '../../widgets/product_list_card.dart';
import '../../widgets/profile_menu_button.dart';
import '../customer/product_details_screen.dart';
import 'add_edit_product_screen.dart';
import 'sold_history_screen.dart';
import 'analytics_screen.dart';
import 'inspection_requests_admin_screen.dart';
import 'orders_screen.dart';
import 'admin_chats_screen.dart';

/// الشاشة الرئيسية الفعلية للوحة تحكم الأدمن (Dashboard):
/// نظرة سريعة على الأرقام المهمة + تنبيهات لحاجات محتاجة متابعة + اختصارات
/// لأكتر الأدوات استخدامًا، بدل ما أول حاجة تفتح تكون شبكة المنتجات على طول.
class AdminHomeScreen extends StatefulWidget {
  const AdminHomeScreen({super.key});

  @override
  State<AdminHomeScreen> createState() => _AdminHomeScreenState();
}

class _AdminHomeScreenState extends State<AdminHomeScreen> {
  final _service = AnalyticsService();

  bool _isLoading = true;
  Map<String, int> _statusCounts = {'available': 0, 'reserved': 0, 'sold': 0, 'total': 0};
  double _totalRevenue = 0;
  int _pendingOrders = 0;
  int _pendingInspections = 0;
  int _totalVisits = 0;
  int _todayVisits = 0;
  List<Product> _mostViewed = [];
  Map<String, double> _monthlyRevenue = {};

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _isLoading = true);
    final results = await Future.wait([
      _service.getProductStatusCounts(),
      _service.getTotalRevenue(),
      _service.getPendingOrdersCount(),
      _service.getPendingInspectionCount(),
      _service.getMostViewedProducts(limit: 4),
      _service.getMonthlyRevenue(months: 6),
      _service.getTotalVisits(),
      _service.getTodayVisits(),
    ]);
    if (!mounted) return;
    setState(() {
      _statusCounts = results[0] as Map<String, int>;
      _totalRevenue = results[1] as double;
      _pendingOrders = results[2] as int;
      _pendingInspections = results[3] as int;
      _mostViewed = results[4] as List<Product>;
      _monthlyRevenue = results[5] as Map<String, double>;
      _totalVisits = results[6] as int;
      _todayVisits = results[7] as int;
      _isLoading = false;
    });
  }

  String _monthLabel(String key, bool isArabic) {
    final parts = key.split('-');
    final monthIndex = int.parse(parts[1]);
    const namesAr = ['', 'ينا', 'فبر', 'مار', 'أبر', 'مايو', 'يون', 'يول', 'أغس', 'سبت', 'أكت', 'نوف', 'ديس'];
    const namesEn = ['', 'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return isArabic ? namesAr[monthIndex] : namesEn[monthIndex];
  }

  @override
  Widget build(BuildContext context) {
    final isArabic = context.watch<LocaleProvider>().isArabic;
    final adminName = context.watch<AuthProvider>().profile?.fullName;
    final isDesktop = Responsive.isDesktop(context);

    final content = _isLoading
        ? const Center(child: CircularProgressIndicator())
        : RefreshIndicator(
            onRefresh: _load,
            child: ListView(
              padding: const EdgeInsets.all(20),
              children: [
                // ترحيب + التاريخ
                Text(
                  adminName != null
                      ? (isArabic ? 'أهلاً بيك، $adminName 👋' : 'Welcome back, $adminName 👋')
                      : (isArabic ? 'أهلاً بيك 👋' : 'Welcome back 👋'),
                  style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: AppTheme.charcoal),
                ),
                const SizedBox(height: 4),
                Text(
                  DateFormat(isArabic ? 'EEEE، d MMMM y' : 'EEEE, d MMMM y', isArabic ? 'ar' : 'en').format(DateTime.now()),
                  style: const TextStyle(color: AppTheme.midGray, fontSize: 13),
                ),
                const SizedBox(height: 20),

                // 👀 زوار الموقع - بارز أول الصفحة زي ما طلبت
                _VisitsBanner(total: _totalVisits, today: _todayVisits, isArabic: isArabic),
                const SizedBox(height: 20),

                // تنبيهات محتاجة متابعة - بتظهر بس لو فيه حاجة فعلاً
                if (_pendingOrders > 0 || _pendingInspections > 0) ...[
                  Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    children: [
                      if (_pendingOrders > 0)
                        _AlertCard(
                          icon: Icons.receipt_long_outlined,
                          text: isArabic ? '$_pendingOrders طلب محتاج متابعة' : '$_pendingOrders order(s) need attention',
                          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const OrdersScreen())),
                        ),
                      if (_pendingInspections > 0)
                        _AlertCard(
                          icon: Icons.fact_check_outlined,
                          text: isArabic
                              ? '$_pendingInspections طلب فحص فني محتاج رد'
                              : '$_pendingInspections inspection request(s) awaiting reply',
                          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const InspectionRequestsAdminScreen())),
                        ),
                    ],
                  ),
                  const SizedBox(height: 20),
                ],

                // كروت الأرقام الأساسية
                LayoutBuilder(
                  builder: (context, constraints) {
                    final cols = constraints.maxWidth >= 900 ? 4 : 2;
                    return GridView.count(
                      crossAxisCount: cols,
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                      childAspectRatio: 1.7,
                      children: [
                        _StatCard(
                          icon: Icons.inventory_2_outlined,
                          label: isArabic ? 'متاح للبيع' : 'Available',
                          value: '${_statusCounts['available']}',
                        ),
                        _StatCard(
                          icon: Icons.pause_circle_outlined,
                          label: isArabic ? 'محجوز' : 'Reserved',
                          value: '${_statusCounts['reserved']}',
                        ),
                        _StatCard(
                          icon: Icons.sell_outlined,
                          label: isArabic ? 'تم بيعه' : 'Sold',
                          value: '${_statusCounts['sold']}',
                        ),
                        _StatCard(
                          icon: Icons.payments_outlined,
                          label: isArabic ? 'إجمالي الإيرادات' : 'Total Revenue',
                          value: '${_totalRevenue.toStringAsFixed(0)} ${isArabic ? 'ج.م' : 'EGP'}',
                          highlight: true,
                        ),
                      ],
                    );
                  },
                ),
                const SizedBox(height: 24),

                // اختصارات سريعة لأكتر الأدوات استخدامًا
                Text(isArabic ? 'اختصارات سريعة' : 'Quick actions', style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16, color: AppTheme.charcoal)),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: [
                    _QuickAction(
                      icon: Icons.add_circle_outline,
                      label: isArabic ? 'إضافة منتج' : 'Add Product',
                      onTap: () async {
                        await Navigator.push(context, MaterialPageRoute(builder: (_) => const AddEditProductScreen()));
                        if (context.mounted) _load();
                      },
                    ),
                    _QuickAction(
                      icon: Icons.chat_bubble_outline,
                      label: isArabic ? 'كل المحادثات' : 'All Chats',
                      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AdminChatsScreen())),
                    ),
                    _QuickAction(
                      icon: Icons.history_rounded,
                      label: isArabic ? 'سجل المبيعات' : 'Sales History',
                      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SoldHistoryScreen())),
                    ),
                    _QuickAction(
                      icon: Icons.bar_chart_rounded,
                      label: isArabic ? 'كل الإحصائيات' : 'Full Analytics',
                      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AnalyticsScreen())),
                    ),
                    _QuickAction(
                      icon: Icons.fact_check_outlined,
                      label: isArabic ? 'طلبات الفحص' : 'Inspections',
                      badgeCount: _pendingInspections,
                      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const InspectionRequestsAdminScreen())),
                    ),
                  ],
                ),
                const SizedBox(height: 28),

                // رسم بياني مصغر للإيرادات + لينك لصفحة الإحصائيات الكاملة
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(isArabic ? 'الإيرادات آخر 6 شهور' : 'Revenue - last 6 months',
                        style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16, color: AppTheme.charcoal)),
                    TextButton(
                      onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AnalyticsScreen())),
                      child: Text(isArabic ? 'التفاصيل' : 'View details'),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                SizedBox(
                  height: 160,
                  child: _monthlyRevenue.values.every((v) => v == 0)
                      ? Center(child: Text(isArabic ? 'لا يوجد مبيعات لسه' : 'No sales yet', style: const TextStyle(color: AppTheme.midGray)))
                      : BarChart(
                          BarChartData(
                            maxY: (_monthlyRevenue.values.reduce((a, b) => a > b ? a : b)) * 1.2,
                            gridData: const FlGridData(show: false),
                            borderData: FlBorderData(show: false),
                            titlesData: FlTitlesData(
                              leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                              rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                              topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                              bottomTitles: AxisTitles(
                                sideTitles: SideTitles(
                                  showTitles: true,
                                  getTitlesWidget: (value, meta) {
                                    final months = _monthlyRevenue.keys.toList();
                                    final i = value.toInt();
                                    if (i < 0 || i >= months.length) return const SizedBox();
                                    return Padding(
                                      padding: const EdgeInsets.only(top: 6),
                                      child: Text(_monthLabel(months[i], isArabic), style: const TextStyle(fontSize: 10, color: AppTheme.midGray)),
                                    );
                                  },
                                ),
                              ),
                            ),
                            barGroups: List.generate(_monthlyRevenue.length, (i) {
                              final months = _monthlyRevenue.keys.toList();
                              return BarChartGroupData(x: i, barRods: [
                                BarChartRodData(
                                  toY: _monthlyRevenue[months[i]] ?? 0,
                                  color: AppTheme.charcoal,
                                  width: 16,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                              ]);
                            }),
                          ),
                        ),
                ),
                const SizedBox(height: 28),

                // أكتر المنتجات مشاهدة - List Card
                Text(isArabic ? 'أكتر المنتجات مشاهدة' : 'Most viewed products',
                    style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16, color: AppTheme.charcoal)),
                const SizedBox(height: 12),
                if (_mostViewed.isEmpty)
                  Text(isArabic ? 'لا يوجد بيانات كفاية لسه' : 'Not enough data yet', style: const TextStyle(color: AppTheme.midGray))
                else
                  ..._mostViewed.map((p) => Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: ProductListCard(
                          product: p,
                          isArabic: isArabic,
                          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => ProductDetailsScreen(productId: p.id))),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.remove_red_eye_outlined, size: 15, color: AppTheme.midGray),
                              const SizedBox(width: 4),
                              Text('${p.viewsCount}', style: const TextStyle(color: AppTheme.midGray, fontSize: 12)),
                            ],
                          ),
                        ),
                      )),
              ],
            ),
          );

    return Scaffold(
      appBar: AppBar(
        title: Text(isArabic ? 'الرئيسية' : 'Dashboard'),
        automaticallyImplyLeading: false,
        // بما إن تاب "الإعدادات" مخفي مؤقتًا، سايبين وصول للبروفايل/تسجيل الخروج من هنا على الموبايل
        // (على الديسكتوب أصلاً موجود في التوب نافيجيشن فمش محتاجين نكرره)
        actions: isDesktop ? null : const [Padding(padding: EdgeInsets.only(right: 12), child: ProfileMenuButton())],
      ),
      body: isDesktop
          ? Center(child: ConstrainedBox(constraints: const BoxConstraints(maxWidth: Responsive.maxContentWidth), child: content))
          : content,
    );
  }
}

/// بانر بارز بعدد زوار الموقع (الكلي + النهاردة) - أول حاجة يشوفها الأدمن في الداشبورد
class _VisitsBanner extends StatelessWidget {
  final int total;
  final int today;
  final bool isArabic;
  const _VisitsBanner({required this.total, required this.today, required this.isArabic});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppTheme.charcoal,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: const BoxDecoration(color: Colors.white12, shape: BoxShape.circle),
            child: const Icon(Icons.visibility_outlined, color: AppTheme.gold, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isArabic ? 'زوار الموقع' : 'Site Visitors',
                  style: const TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.w500),
                ),
                const SizedBox(height: 4),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    Text('$total', style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w700)),
                    const SizedBox(width: 6),
                    Text(isArabic ? 'زيارة إجمالاً' : 'total visits', style: const TextStyle(color: Colors.white54, fontSize: 12)),
                  ],
                ),
              ],
            ),
          ),
          // عدد النهاردة - بادچ Gold صغير
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(color: AppTheme.gold.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(12)),
            child: Column(
              children: [
                Text('$today', style: const TextStyle(color: AppTheme.gold, fontSize: 17, fontWeight: FontWeight.w700)),
                Text(isArabic ? 'النهاردة' : 'today', style: const TextStyle(color: AppTheme.gold, fontSize: 10, fontWeight: FontWeight.w500)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final bool highlight;
  const _StatCard({required this.icon, required this.label, required this.value, this.highlight = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: highlight ? AppTheme.charcoal : AppTheme.pureWhite,
        border: Border.all(color: highlight ? AppTheme.charcoal : AppTheme.lightGray),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 18, color: highlight ? AppTheme.gold : AppTheme.midGray),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(fontWeight: FontWeight.w700, fontSize: 17, color: highlight ? AppTheme.pureWhite : AppTheme.charcoal),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(fontSize: 11.5, color: highlight ? AppTheme.pureWhite.withValues(alpha: 0.75) : AppTheme.midGray),
          ),
        ],
      ),
    );
  }
}

class _AlertCard extends StatelessWidget {
  final IconData icon;
  final String text;
  final VoidCallback onTap;
  const _AlertCard({required this.icon, required this.text, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: AppTheme.offWhite,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppTheme.gold.withValues(alpha: 0.4)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 18, color: AppTheme.gold),
            const SizedBox(width: 8),
            Text(text, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12.5, color: AppTheme.charcoal)),
            const SizedBox(width: 4),
            const Icon(Icons.chevron_right, size: 16, color: AppTheme.midGray),
          ],
        ),
      ),
    );
  }
}

class _QuickAction extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final int badgeCount;
  const _QuickAction({required this.icon, required this.label, required this.onTap, this.badgeCount = 0});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(30),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: AppTheme.offWhite,
          borderRadius: BorderRadius.circular(30),
          border: Border.all(color: AppTheme.lightGray),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 17, color: AppTheme.charcoal),
            const SizedBox(width: 8),
            Text(label, style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 13, color: AppTheme.charcoal)),
            if (badgeCount > 0) ...[
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                decoration: BoxDecoration(color: AppTheme.errorColor, borderRadius: BorderRadius.circular(30)),
                child: Text('$badgeCount', style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w600)),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
