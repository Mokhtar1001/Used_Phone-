import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../providers/auth_provider.dart';
import '../../providers/locale_provider.dart';
import '../../services/inspection_service.dart';
import '../../models/inspection_request.dart';

class MyInspectionRequestsScreen extends StatefulWidget {
  const MyInspectionRequestsScreen({super.key});

  @override
  State<MyInspectionRequestsScreen> createState() => _MyInspectionRequestsScreenState();
}

class _MyInspectionRequestsScreenState extends State<MyInspectionRequestsScreen> {
  final _service = InspectionService();
  List<InspectionRequest> _requests = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final customerId = context.read<AuthProvider>().profile?.id;
    if (customerId == null) return;
    setState(() => _isLoading = true);
    final requests = await _service.getMyRequests(customerId);
    if (mounted) setState(() { _requests = requests; _isLoading = false; });
  }

  @override
  Widget build(BuildContext context) {
    final isArabic = context.watch<LocaleProvider>().isArabic;

    return Scaffold(
      appBar: AppBar(title: Text(isArabic ? 'طلبات الفحص الفني' : 'Inspection Requests')),
      body: RefreshIndicator(
        onRefresh: _load,
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _requests.isEmpty
                ? Center(child: Text(isArabic ? 'لا يوجد طلبات فحص بعد' : 'No inspection requests yet'))
                : ListView.builder(
                    itemCount: _requests.length,
                    itemBuilder: (context, i) {
                      final r = _requests[i];
                      return Card(
                        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                        child: ExpansionTile(
                          leading: Icon(
                            r.isCompleted ? Icons.fact_check : Icons.hourglass_top,
                            color: r.isCompleted ? Colors.green : Colors.orange,
                          ),
                          title: Text(r.productName(isArabic), style: const TextStyle(fontWeight: FontWeight.w600)),
                          subtitle: Text(
                            r.isCompleted
                                ? (isArabic ? 'اكتمل الفحص' : 'Inspection completed')
                                : (isArabic ? 'قيد الانتظار' : 'Pending'),
                            style: TextStyle(color: r.isCompleted ? Colors.green : Colors.orange, fontSize: 12),
                          ),
                          trailing: Text(DateFormat.yMd(isArabic ? 'ar' : 'en').format(r.createdAt), style: const TextStyle(fontSize: 11)),
                          children: [
                            Padding(
                              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                              child: Align(
                                alignment: Alignment.centerRight,
                                child: Text(
                                  r.report ?? (isArabic ? 'الأدمن لسه ما ردش على الطلب' : 'No response yet from the seller'),
                                  style: TextStyle(color: r.report == null ? Colors.grey.shade500 : null),
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
      ),
    );
  }
}
