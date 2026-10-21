import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../core/constants.dart';
import '../../core/theme.dart';
import '../../providers/locale_provider.dart';
import '../../services/inspection_service.dart';
import '../../models/inspection_request.dart';
import '../../widgets/visit_status_chip.dart';

/// مواعيد المعاينة في المحل (للأدمن): تأكيد، تعديل الميعاد، حجز التليفون للعميل، قفل الطلب.
class InspectionRequestsAdminScreen extends StatefulWidget {
  const InspectionRequestsAdminScreen({super.key});

  @override
  State<InspectionRequestsAdminScreen> createState() => _InspectionRequestsAdminScreenState();
}

class _InspectionRequestsAdminScreenState extends State<InspectionRequestsAdminScreen> {
  final _service = InspectionService();
  List<InspectionRequest> _requests = [];
  bool _isLoading = true;
  bool _hasError = false;
  bool _busy = false;

  bool get _ar => context.read<LocaleProvider>().isArabic;
  String _t(String ar, String en) => _ar ? ar : en;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _isLoading = true;
      _hasError = false;
    });
    try {
      await _service.releaseExpiredHolds(); // يفك أي حجز عدّى مدته قبل ما نعرض القايمة
      final requests = await _service.getAllRequests();
      if (mounted) setState(() => _requests = requests);
    } catch (_) {
      if (mounted) setState(() => _hasError = true);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  String _fmt(DateTime d) => DateFormat('EEE d MMM · h:mm a', _ar ? 'ar' : 'en').format(d);

  /// ينفذ إجراء ويعيد التحميل. أي خطأ بيظهر في Snackbar.
  Future<void> _run(Future<String?> Function() action) async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      final message = await action();
      await _load();
      if (mounted && message != null) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(_t('حصل خطأ، حاول تاني', 'Something went wrong, please try again'))),
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  // ---------- اختيار يوم ووقت (الأدمن حر في أي ميعاد) ----------

  Future<DateTime?> _pickDateTime(DateTime? initial) async {
    final now = DateTime.now();
    final firstDay = DateTime(now.year, now.month, now.day);
    var initialDay = initial == null ? firstDay : DateTime(initial.year, initial.month, initial.day);
    if (initialDay.isBefore(firstDay)) initialDay = firstDay;

    final date = await showDatePicker(
      context: context,
      initialDate: initialDay,
      firstDate: firstDay,
      lastDate: firstDay.add(const Duration(days: 90)),
    );
    if (date == null || !mounted) return null;

    final time = await showTimePicker(
      context: context,
      initialTime: initial != null ? TimeOfDay.fromDateTime(initial) : const TimeOfDay(hour: 17, minute: 0),
    );
    if (time == null) return null;
    return DateTime(date.year, date.month, date.day, time.hour, time.minute);
  }

  // ---------- الإجراءات ----------

  Future<void> _confirm(InspectionRequest r) async {
    // الطلبات القديمة (من غير ميعاد) لازم الأدمن يحدد ميعاد الأول
    var target = r;
    if (r.scheduledAt == null) {
      final picked = await _pickDateTime(null);
      if (picked == null) return;
      await _run(() async {
        await _service.rescheduleVisit(r, picked);
        return null;
      });
      if (!mounted) return;
      final fresh = _requests.where((e) => e.id == r.id);
      if (fresh.isEmpty) return;
      target = fresh.first;
    }

    // الحجز مدته محدودة (AppConstants.holdHours): ينفع لو التليفون متاح (أو محجوز بالفعل للطلب ده) والميعاد خلال مدة الحجز
    final inWindow = InspectionService.withinHoldWindow(target.scheduledAt);
    final canHold = (target.productHeld || target.productStatus == 'available') && inWindow;
    var hold = canHold && (target.holdRequested || target.productHeld);
    final noteController = TextEditingController(text: target.adminNote ?? '');

    final ok = await showDialog<bool>(
      context: context,
      builder: (c) => StatefulBuilder(
        builder: (c, setLocal) => AlertDialog(
          title: Text(_t('تأكيد الميعاد', 'Confirm visit')),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (target.scheduledAt != null) Text(_fmt(target.scheduledAt!), style: const TextStyle(fontWeight: FontWeight.w700)),
              const SizedBox(height: 8),
              CheckboxListTile(
                contentPadding: EdgeInsets.zero,
                controlAffinity: ListTileControlAffinity.leading,
                value: hold,
                onChanged: canHold ? (v) => setLocal(() => hold = v ?? false) : null,
                title: Text(_t('احجز التليفون للعميل', 'Hold the phone for the customer')),
                subtitle: Text(
                  !inWindow
                      ? _t('الحجز بيستمر ${AppConstants.holdHours} ساعة بس، والميعاد أبعد من كده', 'Holds last ${AppConstants.holdHours} hours only and this visit is later')
                      : !canHold
                          ? _t('التليفون مش متاح للحجز دلوقتي', 'Phone is not available to hold')
                          : '${target.holdRequested ? '${_t('العميل طلب الحجز', 'Customer asked for a hold')} • ' : ''}${_t('الحجز لمدة ${AppConstants.holdHours} ساعة', 'Hold lasts ${AppConstants.holdHours} hours')}',
                  style: const TextStyle(fontSize: 12),
                ),
              ),
              TextField(
                controller: noteController,
                maxLines: 2,
                decoration: InputDecoration(labelText: _t('ملاحظة للعميل (اختياري)', 'Note to customer (optional)')),
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(c, false), child: Text(_t('إلغاء', 'Cancel'))),
            ElevatedButton(onPressed: () => Navigator.pop(c, true), child: Text(_t('تأكيد', 'Confirm'))),
          ],
        ),
      ),
    );
    final note = noteController.text;
    if (ok != true) return;

    await _run(() async {
      final holdOk = await _service.confirmVisit(target, hold: hold, adminNote: note);
      return holdOk
          ? _t('تم تأكيد الميعاد', 'Visit confirmed')
          : _t('اتأكد الميعاد، لكن مقدرناش نحجز التليفون', 'Confirmed, but the phone could not be held');
    });
  }

  Future<void> _reschedule(InspectionRequest r) async {
    final picked = await _pickDateTime(r.scheduledAt);
    if (picked == null) return;
    await _run(() async {
      final released = await _service.rescheduleVisit(r, picked);
      return released
          ? _t('تم تعديل الميعاد واتفك حجز التليفون (الحجز ${AppConstants.holdHours} ساعة بس)', 'Rescheduled. The phone hold was released (holds last ${AppConstants.holdHours} hours)')
          : _t('تم تعديل الميعاد', 'Visit rescheduled');
    });
  }

  Future<void> _toggleHold(InspectionRequest r) async {
    await _run(() async {
      final ok = await _service.setHold(r, !r.productHeld);
      if (!ok) {
        return _t(
          'مينفعش الحجز: التليفون مش متاح أو الميعاد بعد أكتر من ${AppConstants.holdHours} ساعة',
          'Cannot hold: phone unavailable or the visit is more than ${AppConstants.holdHours} hours away',
        );
      }
      return r.productHeld ? _t('تم فك الحجز', 'Hold released') : _t('تم حجز التليفون لمدة ${AppConstants.holdHours} ساعة', 'Phone held for ${AppConstants.holdHours} hours');
    });
  }

  Future<void> _cancel(InspectionRequest r) async {
    final ok = await _confirmDialog(
      _t('إلغاء الميعاد؟', 'Cancel this visit?'),
      r.productHeld ? _t('التليفون هيتفك حجزه.', 'The phone will be released.') : null,
    );
    if (ok != true) return;
    await _run(() async {
      await _service.cancelVisit(r);
      return _t('تم إلغاء الميعاد', 'Visit cancelled');
    });
  }

  Future<void> _noShow(InspectionRequest r) async {
    final ok = await _confirmDialog(
      _t('العميل ماحضرش؟', 'Mark as no-show?'),
      r.productHeld ? _t('التليفون هيتفك حجزه.', 'The phone will be released.') : null,
    );
    if (ok != true) return;
    await _run(() async {
      await _service.markNoShow(r);
      return null;
    });
  }

  Future<void> _complete(InspectionRequest r) async {
    final reportController = TextEditingController(text: r.report ?? '');
    var keepHeld = false;

    final ok = await showDialog<bool>(
      context: context,
      builder: (c) => StatefulBuilder(
        builder: (c, setLocal) => AlertDialog(
          title: Text(_t('تمت المعاينة', 'Visit completed')),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: reportController,
                maxLines: 4,
                decoration: InputDecoration(labelText: _t('ملاحظات عن حالة الجهاز (اختياري)', 'Device condition notes (optional)')),
              ),
              if (r.productHeld)
                CheckboxListTile(
                  contentPadding: EdgeInsets.zero,
                  controlAffinity: ListTileControlAffinity.leading,
                  value: keepHeld,
                  onChanged: (v) => setLocal(() => keepHeld = v ?? false),
                  title: Text(_t('سيب التليفون محجوز (العميل هيشتريه)', 'Keep the phone reserved (customer is buying)')),
                ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(c, false), child: Text(_t('إلغاء', 'Cancel'))),
            ElevatedButton(onPressed: () => Navigator.pop(c, true), child: Text(_t('حفظ', 'Save'))),
          ],
        ),
      ),
    );
    final report = reportController.text;
    if (ok != true) return;

    await _run(() async {
      await _service.completeVisit(r, report: report, keepHeld: keepHeld);
      return null;
    });
  }

  Future<bool?> _confirmDialog(String title, String? body) {
    return showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: Text(title),
        content: body == null ? null : Text(body),
        actions: [
          TextButton(onPressed: () => Navigator.pop(c, false), child: Text(_t('لأ', 'No'))),
          TextButton(onPressed: () => Navigator.pop(c, true), child: Text(_t('أيوه', 'Yes'))),
        ],
      ),
    );
  }

  // ---------- قايمة الإجراءات لطلب معين ----------

  void _openActions(InspectionRequest r) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      constraints: const BoxConstraints(maxWidth: 560),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (sheet) {
        void act(VoidCallback fn) {
          Navigator.pop(sheet);
          fn();
        }

        return SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(8, 16, 8, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(r.productName(_ar), style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700)),
                    const SizedBox(height: 6),
                    SelectableText('${r.customerName ?? ''}${r.customerPhone != null ? ' • ${r.customerPhone}' : ''}'),
                    if (r.scheduledAt != null) ...[
                      const SizedBox(height: 4),
                      Text(_fmt(r.scheduledAt!), style: const TextStyle(fontWeight: FontWeight.w600)),
                    ],
                    if (r.customerNote != null) ...[
                      const SizedBox(height: 8),
                      Text('${_t('ملاحظة العميل', 'Customer note')}: ${r.customerNote}', style: const TextStyle(color: AppTheme.deepGray)),
                    ],
                    if (r.report != null) ...[
                      const SizedBox(height: 8),
                      Text(r.report!, style: const TextStyle(color: AppTheme.deepGray)),
                    ],
                  ],
                ),
              ),
              const Divider(height: 24),
              if (r.isPending) ...[
                _action(Icons.check_circle_outline, _t('تأكيد الميعاد', 'Confirm visit'), () => act(() => _confirm(r))),
                _action(Icons.edit_calendar_outlined, _t('تعديل الميعاد', 'Reschedule'), () => act(() => _reschedule(r))),
                _action(Icons.cancel_outlined, _t('رفض / إلغاء', 'Decline / cancel'), () => act(() => _cancel(r))),
              ],
              if (r.isConfirmed) ...[
                _action(Icons.task_alt, _t('تمت المعاينة', 'Mark completed'), () => act(() => _complete(r))),
                _action(Icons.edit_calendar_outlined, _t('تعديل الميعاد', 'Reschedule'), () => act(() => _reschedule(r))),
                _action(
                  r.productHeld ? Icons.lock_open_outlined : Icons.lock_outline,
                  r.productHeld ? _t('فك حجز التليفون', 'Release the phone') : _t('احجز التليفون للعميل', 'Hold the phone for the customer'),
                  () => act(() => _toggleHold(r)),
                ),
                _action(Icons.person_off_outlined, _t('العميل ماحضرش', 'No-show'), () => act(() => _noShow(r))),
                _action(Icons.cancel_outlined, _t('إلغاء الميعاد', 'Cancel visit'), () => act(() => _cancel(r))),
              ],
            ],
          ),
        );
      },
    );
  }

  Widget _action(IconData icon, String label, VoidCallback onTap) {
    return ListTile(leading: Icon(icon), title: Text(label), onTap: onTap);
  }

  // ---------- الشكل ----------

  @override
  Widget build(BuildContext context) {
    final isArabic = context.watch<LocaleProvider>().isArabic;

    int bySchedule(InspectionRequest a, InspectionRequest b) {
      final x = a.scheduledAt, y = b.scheduledAt;
      if (x == null && y == null) return a.createdAt.compareTo(b.createdAt);
      if (x == null) return 1;
      if (y == null) return -1;
      return x.compareTo(y);
    }

    final pending = _requests.where((r) => r.isPending).toList()..sort(bySchedule);
    final confirmed = _requests.where((r) => r.isConfirmed).toList()..sort(bySchedule);
    final history = _requests.where((r) => !r.isActive).toList()
      ..sort((a, b) => (b.scheduledAt ?? b.createdAt).compareTo(a.scheduledAt ?? a.createdAt));

    return Scaffold(
      appBar: AppBar(title: Text(isArabic ? 'مواعيد المعاينة' : 'Store Visits')),
      body: Stack(
        children: [
          RefreshIndicator(
            onRefresh: _load,
            child: _isLoading && _requests.isEmpty
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
                            Center(child: Text(isArabic ? 'مفيش مواعيد معاينة' : 'No store visits')),
                          ])
                        : ListView(
                            padding: const EdgeInsets.only(bottom: 24),
                            children: [
                              if (pending.isNotEmpty) _SectionHeader(isArabic ? 'مستني التأكيد (${pending.length})' : 'Awaiting confirmation (${pending.length})'),
                              ...pending.map((r) => _VisitTile(request: r, isArabic: isArabic, scheduleText: _scheduleText(r), onTap: () => _openActions(r))),
                              if (confirmed.isNotEmpty) _SectionHeader(isArabic ? 'مواعيد جاية (${confirmed.length})' : 'Upcoming (${confirmed.length})'),
                              ...confirmed.map((r) => _VisitTile(request: r, isArabic: isArabic, scheduleText: _scheduleText(r), onTap: () => _openActions(r))),
                              if (history.isNotEmpty) _SectionHeader(isArabic ? 'السجل (${history.length})' : 'History (${history.length})'),
                              ...history.map((r) => _VisitTile(request: r, isArabic: isArabic, scheduleText: _scheduleText(r), onTap: () => _openActions(r))),
                            ],
                          ),
          ),
          if (_busy) const Positioned.fill(child: ColoredBox(color: Color(0x33000000), child: Center(child: CircularProgressIndicator()))),
        ],
      ),
    );
  }

  String _scheduleText(InspectionRequest r) =>
      r.scheduledAt != null ? _fmt(r.scheduledAt!) : _t('من غير ميعاد', 'No time set');
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

class _VisitTile extends StatelessWidget {
  final InspectionRequest request;
  final bool isArabic;
  final String scheduleText;
  final VoidCallback onTap;
  const _VisitTile({required this.request, required this.isArabic, required this.scheduleText, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final r = request;
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(child: Text(r.productName(isArabic), style: const TextStyle(fontWeight: FontWeight.w700))),
                  const SizedBox(width: 8),
                  VisitStatusChip(request: r, isArabic: isArabic),
                ],
              ),
              const SizedBox(height: 6),
              Text('${r.customerName ?? ''}${r.customerPhone != null ? ' • ${r.customerPhone}' : ''}',
                  style: const TextStyle(color: AppTheme.deepGray)),
              const SizedBox(height: 6),
              Row(
                children: [
                  const Icon(Icons.event_outlined, size: 16, color: AppTheme.midGray),
                  const SizedBox(width: 6),
                  Expanded(child: Text(scheduleText, style: const TextStyle(fontSize: 13))),
                ],
              ),
              if (r.isActive && (r.productHeld || r.holdRequested)) ...[
                const SizedBox(height: 8),
                r.productHeld
                    ? VisitPill(
                        label: r.holdExpiresAt != null
                            ? (isArabic
                                ? 'محجوز لحد ${DateFormat('EEE h:mm a', 'ar').format(r.holdExpiresAt!)}'
                                : 'Held until ${DateFormat('EEE h:mm a', 'en').format(r.holdExpiresAt!)}')
                            : (isArabic ? 'التليفون محجوز' : 'Phone held'),
                        color: AppTheme.gold,
                        icon: Icons.lock_outline,
                      )
                    : VisitPill(
                        label: isArabic ? 'العميل طلب حجز' : 'Hold requested',
                        color: AppTheme.warningColor,
                        icon: Icons.bookmark_border,
                      ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
