import 'package:flutter/material.dart';
import '../../widgets/customer_nav_actions.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../core/theme.dart';
import '../../providers/auth_provider.dart';
import '../../providers/locale_provider.dart';
import '../../services/inspection_service.dart';
import '../../models/inspection_request.dart';
import '../../widgets/visit_status_chip.dart';

/// مواعيد المعاينة في المحل بتاعت العميل
class MyInspectionRequestsScreen extends StatefulWidget {
  const MyInspectionRequestsScreen({super.key});

  @override
  State<MyInspectionRequestsScreen> createState() => _MyInspectionRequestsScreenState();
}

class _MyInspectionRequestsScreenState extends State<MyInspectionRequestsScreen> {
  final _service = InspectionService();
  List<InspectionRequest> _requests = [];
  bool _isLoading = true;
  bool _hasError = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final customerId = context.read<AuthProvider>().profile?.id;
    if (customerId == null) return;
    setState(() {
      _isLoading = true;
      _hasError = false;
    });
    try {
      final requests = await _service.getMyRequests(customerId);
      // الأحدث ميعادًا فوق؛ والطلبات القديمة (من غير ميعاد) بتتحط حسب تاريخ الإنشاء
      requests.sort((a, b) => (b.scheduledAt ?? b.createdAt).compareTo(a.scheduledAt ?? a.createdAt));
      if (mounted) setState(() => _requests = requests);
    } catch (_) {
      if (mounted) setState(() => _hasError = true);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _cancel(InspectionRequest r, bool isArabic) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: Text(isArabic ? 'إلغاء الميعاد؟' : 'Cancel this visit?'),
        content: Text(isArabic ? 'لو التليفون كان محجوزلك هيتفك الحجز.' : 'If the phone was held for you, the hold will be released.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(c, false), child: Text(isArabic ? 'لأ' : 'No')),
          TextButton(onPressed: () => Navigator.pop(c, true), child: Text(isArabic ? 'إلغاء الميعاد' : 'Cancel visit')),
        ],
      ),
    );
    if (ok != true) return;

    try {
      await _service.cancelMyVisit(r.id);
      await _load();
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(isArabic ? 'حصل خطأ، حاول تاني' : 'Something went wrong, please try again')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isArabic = context.watch<LocaleProvider>().isArabic;

    return Scaffold(
      appBar: withCustomerNav(context, AppBar(title: Text(isArabic ? 'مواعيد المعاينة' : 'Store Visits'))),
      body: RefreshIndicator(
        onRefresh: _load,
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _hasError
                ? ListView(children: [
                    const SizedBox(height: 120),
                    Center(child: Text(isArabic ? 'حصل خطأ في التحميل' : 'Failed to load')),
                    Center(child: TextButton(onPressed: _load, child: Text(isArabic ? 'حاول تاني' : 'Retry'))),
                  ])
                : _requests.isEmpty
                    ? ListView(children: [
                        const SizedBox(height: 120),
                        Center(child: Text(isArabic ? 'مفيش مواعيد معاينة لسه' : 'No store visits yet')),
                      ])
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        itemCount: _requests.length,
                        itemBuilder: (context, i) => _VisitCard(
                          request: _requests[i],
                          isArabic: isArabic,
                          onCancel: () => _cancel(_requests[i], isArabic),
                        ),
                      ),
      ),
    );
  }
}

class _VisitCard extends StatelessWidget {
  final InspectionRequest request;
  final bool isArabic;
  final VoidCallback onCancel;
  const _VisitCard({required this.request, required this.isArabic, required this.onCancel});

  @override
  Widget build(BuildContext context) {
    final r = request;
    final locale = isArabic ? 'ar' : 'en';
    final scheduled = r.scheduledAt;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(r.productName(isArabic), style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
                ),
                const SizedBox(width: 8),
                VisitStatusChip(request: r, isArabic: isArabic),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                const Icon(Icons.event_outlined, size: 18, color: AppTheme.midGray),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    scheduled != null
                        ? DateFormat('EEEE d MMM · h:mm a', locale).format(scheduled)
                        : (isArabic ? 'لسه ما اتحددش ميعاد' : 'No time set yet'),
                  ),
                ),
              ],
            ),
            if (r.isActive && (r.productHeld || r.holdRequested)) ...[
              const SizedBox(height: 8),
              r.productHeld
                  ? VisitPill(
                      label: r.holdExpiresAt != null
                          ? (isArabic
                              ? 'التليفون محجوزلك لحد ${DateFormat('EEE h:mm a', locale).format(r.holdExpiresAt!)}'
                              : 'Phone held for you until ${DateFormat('EEE h:mm a', locale).format(r.holdExpiresAt!)}')
                          : (isArabic ? 'التليفون محجوزلك' : 'Phone held for you'),
                      color: AppTheme.gold,
                      icon: Icons.lock_outline,
                    )
                  : VisitPill(
                      label: isArabic ? 'طلب الحجز مستني الرد' : 'Hold request pending',
                      color: AppTheme.midGray,
                      icon: Icons.hourglass_top,
                    ),
            ],
            if (r.adminNote != null) ...[
              const SizedBox(height: 10),
              Text(r.adminNote!, style: const TextStyle(color: AppTheme.deepGray)),
            ],
            if (r.report != null) ...[
              const SizedBox(height: 10),
              Text(r.report!, style: const TextStyle(color: AppTheme.deepGray)),
            ],
            if (r.isActive) ...[
              const SizedBox(height: 6),
              Align(
                alignment: AlignmentDirectional.centerEnd,
                child: TextButton(
                  onPressed: onCancel,
                  child: Text(isArabic ? 'إلغاء الميعاد' : 'Cancel visit'),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
