import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../core/responsive.dart';
import '../../core/theme.dart';
import '../../models/sell_models.dart';
import '../../providers/locale_provider.dart';
import '../../services/sell_service.dart';

/// طلبات بيع الموبايلات اللي الزبائن بعتوها - متاحة لأي أدمن.
class SellRequestsAdminScreen extends StatefulWidget {
  const SellRequestsAdminScreen({super.key});

  @override
  State<SellRequestsAdminScreen> createState() => _SellRequestsAdminScreenState();
}

class _SellRequestsAdminScreenState extends State<SellRequestsAdminScreen> {
  final _service = SellService();
  final _money = NumberFormat('#,##0');

  List<SellRequest> _requests = [];
  bool _loading = true;
  bool _error = false;
  bool _ar = false;

  String _t(String ar, String en) => sellTr(_ar, ar, en);

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = false;
    });
    try {
      final data = await _service.getAllRequests();
      if (mounted) setState(() => _requests = data);
    } catch (_) {
      if (mounted) setState(() => _error = true);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _handle(SellRequest r, String status) async {
    final controller = TextEditingController(text: r.adminNote ?? '');
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: Text(status == 'completed' ? _t('تم التواصل / إتمام الطلب', 'Mark as completed') : _t('رفض الطلب', 'Reject request')),
        content: TextField(
          controller: controller,
          maxLines: 3,
          decoration: InputDecoration(hintText: _t('ملاحظة (اختياري)', 'Note (optional)')),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(c, false), child: Text(_t('إلغاء', 'Cancel'))),
          ElevatedButton(onPressed: () => Navigator.pop(c, true), child: Text(_t('تأكيد', 'Confirm'))),
        ],
      ),
    );
    if (confirmed != true) return;
    try {
      await _service.updateRequest(id: r.id, status: status, note: controller.text);
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(_t('حصل خطأ', 'Something went wrong'))));
      }
    }
    if (mounted) _load();
  }

  Color _statusColor(String s) {
    switch (s) {
      case 'completed':
        return AppTheme.successColor;
      case 'rejected':
        return AppTheme.errorColor;
      default:
        return AppTheme.warningColor;
    }
  }

  String _statusLabel(String s) {
    switch (s) {
      case 'completed':
        return _t('تم', 'Completed');
      case 'rejected':
        return _t('مرفوض', 'Rejected');
      default:
        return _t('جديد', 'Pending');
    }
  }

  @override
  Widget build(BuildContext context) {
    _ar = context.watch<LocaleProvider>().isArabic;

    return Scaffold(
      appBar: AppBar(title: Text(_t('طلبات بيع الزبائن', 'Sell Requests'))),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(_t('حصل خطأ', 'Something went wrong')),
                      const SizedBox(height: 12),
                      ElevatedButton(onPressed: _load, child: Text(_t('حاول تاني', 'Retry'))),
                    ],
                  ),
                )
              : _requests.isEmpty
                  ? Center(child: Text(_t('مفيش طلبات بيع لسه', 'No sell requests yet')))
                  : RefreshIndicator(
                      onRefresh: _load,
                      child: Center(
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: Responsive.maxContentWidth),
                          child: ListView.separated(
                            physics: const AlwaysScrollableScrollPhysics(),
                            padding: const EdgeInsets.all(16),
                            itemCount: _requests.length,
                            separatorBuilder: (_, __) => const SizedBox(height: 12),
                            itemBuilder: (context, i) => _card(_requests[i]),
                          ),
                        ),
                      ),
                    ),
    );
  }

  Widget _card(SellRequest r) {
    final egp = _t('ج.م', 'EGP');
    final range = r.estimateLow == r.estimateHigh
        ? '$egp ${_money.format(r.estimateHigh)}'
        : '$egp ${_money.format(r.estimateLow)} – ${_money.format(r.estimateHigh)}';

    return Container(
      decoration: BoxDecoration(border: Border.all(color: AppTheme.lightGray), borderRadius: BorderRadius.circular(14)),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          expandedCrossAxisAlignment: CrossAxisAlignment.start,
          title: Row(
            children: [
              Expanded(child: Text('${r.modelName} · ${r.storage}', style: const TextStyle(fontWeight: FontWeight.w700))),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                decoration: BoxDecoration(
                  color: _statusColor(r.status).withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(_statusLabel(r.status),
                    style: TextStyle(color: _statusColor(r.status), fontSize: 12, fontWeight: FontWeight.w700)),
              ),
            ],
          ),
          subtitle: Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(
              '${r.customerName ?? _t('عميل', 'Customer')}  •  $range  •  ${DateFormat('d MMM, h:mm a').format(r.createdAt.toLocal())}',
              style: const TextStyle(fontSize: 12.5),
            ),
          ),
          children: [
            if (r.customerPhone != null && r.customerPhone!.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Row(
                  children: [
                    const Icon(Icons.phone_outlined, size: 16, color: AppTheme.midGray),
                    const SizedBox(width: 6),
                    SelectableText(r.customerPhone!, style: const TextStyle(fontWeight: FontWeight.w600)),
                  ],
                ),
              ),
            Text('${_t('السعر الأساسي', 'Base price')}: $egp ${_money.format(r.basePrice)}',
                style: const TextStyle(color: AppTheme.deepGray)),
            const SizedBox(height: 10),
            for (final a in r.answers)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 3),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(flex: 5, child: Text(a.question, style: const TextStyle(color: AppTheme.deepGray, fontSize: 13))),
                    Expanded(flex: 3, child: Text(a.answer, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13))),
                    SizedBox(
                      width: 80,
                      child: Text(
                        a.deduction > 0 ? '− ${_money.format(a.deduction)}' : '—',
                        textAlign: TextAlign.end,
                        style: TextStyle(fontSize: 13, color: a.deduction > 0 ? AppTheme.errorColor : AppTheme.midGray),
                      ),
                    ),
                  ],
                ),
              ),
            if (r.adminNote != null) ...[
              const SizedBox(height: 10),
              Text('${_t('ملاحظة', 'Note')}: ${r.adminNote}', style: const TextStyle(fontStyle: FontStyle.italic)),
            ],
            if (r.isPending) ...[
              const SizedBox(height: 14),
              Row(
                children: [
                  ElevatedButton(onPressed: () => _handle(r, 'completed'), child: Text(_t('تم', 'Complete'))),
                  const SizedBox(width: 10),
                  OutlinedButton(onPressed: () => _handle(r, 'rejected'), child: Text(_t('رفض', 'Reject'))),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}
