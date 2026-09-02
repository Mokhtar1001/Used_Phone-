import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../providers/locale_provider.dart';
import '../../services/inspection_service.dart';
import '../../models/inspection_request.dart';

class InspectionRequestsAdminScreen extends StatefulWidget {
  const InspectionRequestsAdminScreen({super.key});

  @override
  State<InspectionRequestsAdminScreen> createState() => _InspectionRequestsAdminScreenState();
}

class _InspectionRequestsAdminScreenState extends State<InspectionRequestsAdminScreen> {
  final _service = InspectionService();
  List<InspectionRequest> _requests = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _isLoading = true);
    final requests = await _service.getAllRequests();
    if (mounted) setState(() { _requests = requests; _isLoading = false; });
  }

  void _openReportDialog(InspectionRequest request, bool isArabic) {
    final controller = TextEditingController(text: request.report ?? '');
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(isArabic ? 'تقرير حالة الجهاز' : 'Device inspection report'),
        content: TextField(
          controller: controller,
          maxLines: 5,
          decoration: InputDecoration(hintText: isArabic ? 'اكتب حالة الجهاز بالتفصيل...' : 'Describe the device condition...'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: Text(isArabic ? 'إلغاء' : 'Cancel')),
          ElevatedButton(
            onPressed: () async {
              if (controller.text.trim().isEmpty) return;
              await _service.submitReport(requestId: request.id, report: controller.text.trim());
              if (context.mounted) {
                Navigator.pop(context);
                _load();
              }
            },
            child: Text(isArabic ? 'إرسال' : 'Send'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isArabic = context.watch<LocaleProvider>().isArabic;
    final pending = _requests.where((r) => !r.isCompleted).toList();
    final completed = _requests.where((r) => r.isCompleted).toList();

    return Scaffold(
      appBar: AppBar(title: Text(isArabic ? 'طلبات الفحص الفني' : 'Inspection Requests')),
      body: RefreshIndicator(
        onRefresh: _load,
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _requests.isEmpty
                ? Center(child: Text(isArabic ? 'لا يوجد طلبات فحص' : 'No inspection requests'))
                : ListView(
                    children: [
                      if (pending.isNotEmpty) _SectionHeader(isArabic ? 'في الانتظار (${pending.length})' : 'Pending (${pending.length})'),
                      ...pending.map((r) => _RequestTile(request: r, isArabic: isArabic, onTap: () => _openReportDialog(r, isArabic))),
                      if (completed.isNotEmpty) _SectionHeader(isArabic ? 'مكتملة (${completed.length})' : 'Completed (${completed.length})'),
                      ...completed.map((r) => _RequestTile(request: r, isArabic: isArabic, onTap: () => _openReportDialog(r, isArabic))),
                    ],
                  ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader(this.title);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
    );
  }
}

class _RequestTile extends StatelessWidget {
  final InspectionRequest request;
  final bool isArabic;
  final VoidCallback onTap;
  const _RequestTile({required this.request, required this.isArabic, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: ListTile(
        onTap: onTap,
        leading: Icon(request.isCompleted ? Icons.fact_check : Icons.hourglass_top, color: request.isCompleted ? Colors.green : Colors.orange),
        title: Text(request.productName(isArabic), style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Text('${request.customerName ?? ''} • ${DateFormat.yMd(isArabic ? 'ar' : 'en').format(request.createdAt)}'),
        trailing: Icon(request.isCompleted ? Icons.edit_note : Icons.reply, color: Colors.grey.shade500),
      ),
    );
  }
}
