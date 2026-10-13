import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/constants.dart';
import '../../core/theme.dart';
import '../../models/product.dart';
import '../../providers/locale_provider.dart';
import '../../services/inspection_service.dart';

/// بوتوم شيت حجز ميعاد معاينة في المحل: يوم + وقت + (اختياري) حجز التليفون + ملاحظة.
/// بيرجّع الميعاد اللي اتحجز (وهل العميل طلب حجز التليفون)، أو null لو العميل قفل من غير ما يحجز.
Future<({DateTime at, bool hold})?> showBookStoreVisitSheet(BuildContext context, Product product) {
  return showModalBottomSheet<({DateTime at, bool hold})>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    constraints: const BoxConstraints(maxWidth: 560),
    shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
    builder: (_) => _BookVisitSheet(product: product),
  );
}

class _BookVisitSheet extends StatefulWidget {
  final Product product;
  const _BookVisitSheet({required this.product});

  @override
  State<_BookVisitSheet> createState() => _BookVisitSheetState();
}

class _BookVisitSheetState extends State<_BookVisitSheet> {
  final _service = InspectionService();
  final _noteController = TextEditingController();

  DateTime? _selectedDay;
  DateTime? _selectedSlot;
  bool _hold = false;
  bool _saving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    final days = _visibleDays();
    if (days.isNotEmpty) _selectedDay = days.first;
  }

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  // ---------- المواعيد ----------

  /// كل مواعيد اليوم ده من أول فتح المحل لحد قبل الإقفال
  List<DateTime> _slotsFor(DateTime day) {
    final slots = <DateTime>[];
    for (var m = AppConstants.storeOpenHour * 60; m < AppConstants.storeCloseHour * 60; m += AppConstants.visitSlotMinutes) {
      slots.add(DateTime(day.year, day.month, day.day, 0, m));
    }
    return slots;
  }

  /// الميعاد لازم يبقى بعد أقل مدة مسموحة، ولو العميل عايز نحجزله التليفون
  /// لازم يكون خلال [AppConstants.holdHours] ساعة (التليفون ممكن يتباع في المحل).
  bool _isBookable(DateTime slot) {
    final now = DateTime.now();
    if (!slot.isAfter(now.add(const Duration(hours: AppConstants.visitMinLeadHours)))) return false;
    if (_hold && slot.isAfter(now.add(const Duration(hours: AppConstants.holdHours)))) return false;
    return true;
  }

  /// الأيام اللي فيها ميعاد واحد على الأقل متاح (من غير أيام الإجازة)
  List<DateTime> _visibleDays() {
    final now = DateTime.now();
    final days = <DateTime>[];
    for (var i = 0; i <= AppConstants.visitMaxDaysAhead; i++) {
      final d = DateTime(now.year, now.month, now.day + i);
      if (AppConstants.storeClosedWeekdays.contains(d.weekday)) continue;
      if (_slotsFor(d).any(_isBookable)) days.add(d);
    }
    return days;
  }

  /// لما العميل يشغّل/يقفل الحجز، بنظبط اليوم والميعاد المختارين عشان يفضلوا صالحين
  void _setHold(bool value) {
    setState(() {
      _hold = value;
      final days = _visibleDays();
      if (_selectedDay == null || !days.contains(_selectedDay)) {
        _selectedDay = days.isEmpty ? null : days.first;
        _selectedSlot = null;
      }
      if (_selectedSlot != null && !_isBookable(_selectedSlot!)) _selectedSlot = null;
    });
  }

  // ---------- الحجز ----------

  Future<void> _submit(bool isArabic) async {
    final slot = _selectedSlot;
    if (slot == null) return;

    setState(() {
      _saving = true;
      _error = null;
    });

    try {
      await _service.bookVisit(
        productId: widget.product.id,
        scheduledAt: slot,
        holdRequested: _hold,
        note: _noteController.text,
      );
      if (mounted) Navigator.pop(context, (at: slot, hold: _hold));
    } on PostgrestException catch (e) {
      if (!mounted) return;
      setState(() => _error = _errorText(e.message, isArabic));
    } catch (_) {
      if (!mounted) return;
      setState(() => _error = isArabic ? 'حصل خطأ، حاول تاني' : 'Something went wrong, please try again');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  String _errorText(String message, bool isArabic) {
    if (message.contains('active_visit_exists')) {
      return isArabic ? 'عندك ميعاد معاينة لسه شغال للتليفون ده' : 'You already have an active visit booked for this phone';
    }
    if (message.contains('product_sold')) {
      return isArabic ? 'التليفون ده اتباع' : 'This phone has been sold';
    }
    if (message.contains('hold_too_far')) {
      return isArabic
          ? 'الحجز بيستمر ${AppConstants.holdHours} ساعة بس، اختار ميعاد خلال ${AppConstants.holdHours} ساعة أو اقفل خيار الحجز'
          : 'A hold lasts ${AppConstants.holdHours} hours only. Pick a time within ${AppConstants.holdHours} hours or turn off the hold';
    }
    if (message.contains('invalid_time')) {
      return isArabic ? 'الميعاد ده مش متاح، اختار ميعاد تاني' : 'That time is not available, please pick another';
    }
    return isArabic ? 'حصل خطأ، حاول تاني' : 'Something went wrong, please try again';
  }

  // ---------- الشكل ----------

  @override
  Widget build(BuildContext context) {
    final isArabic = context.watch<LocaleProvider>().isArabic;
    final locale = isArabic ? 'ar' : 'en';
    final day = _selectedDay;
    final days = _visibleDays();
    final canHold = widget.product.status == 'available';

    return SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(20, 20, 20, 20 + MediaQuery.viewInsetsOf(context).bottom),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            isArabic ? 'احجز معاينة في المحل' : 'Book a store visit',
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 4),
          Text(widget.product.name(isArabic), style: const TextStyle(color: AppTheme.midGray)),
          const SizedBox(height: 18),
          if (canHold)
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              value: _hold,
              onChanged: _setHold,
              title: Text(isArabic ? 'احجزلي التليفون لحد ما أجي' : 'Hold this phone for me until my visit'),
              subtitle: Text(
                isArabic
                    ? 'الحجز بيستمر ${AppConstants.holdHours} ساعة بس لأن التليفون ممكن يتباع في المحل، فالميعاد لازم يكون خلال ${AppConstants.holdHours} ساعة. هنأكدلك لو قدرنا نحجزه.'
                    : 'A hold lasts ${AppConstants.holdHours} hours only since the phone may be sold in store, so your visit must be within ${AppConstants.holdHours} hours. We\'ll confirm if we can hold it.',
                style: const TextStyle(fontSize: 12),
              ),
            ),
          if (days.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Text(
                _hold
                    ? (isArabic ? 'مفيش مواعيد متاحة خلال ${AppConstants.holdHours} ساعة. اقفل خيار الحجز عشان تشوف مواعيد أبعد.' : 'No slots within ${AppConstants.holdHours} hours. Turn off the hold to see later times.')
                    : (isArabic ? 'مفيش مواعيد متاحة حاليًا' : 'No time slots are available right now'),
              ),
            )
          else ...[
            const SizedBox(height: 8),
            Text(isArabic ? 'اختار اليوم' : 'Pick a day', style: const TextStyle(fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            SizedBox(
              height: 64,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: days.length,
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemBuilder: (_, i) {
                  final d = days[i];
                  final selected = day != null && d == day;
                  return ChoiceChip(
                    selected: selected,
                    showCheckmark: false,
                    onSelected: (_) => setState(() {
                      _selectedDay = d;
                      _selectedSlot = null;
                    }),
                    label: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(DateFormat('EEE', locale).format(d), style: const TextStyle(fontSize: 11)),
                        Text(DateFormat('d MMM', locale).format(d), style: const TextStyle(fontWeight: FontWeight.w700)),
                      ],
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 16),
            Text(isArabic ? 'اختار الوقت' : 'Pick a time', style: const TextStyle(fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            if (day != null)
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final slot in _slotsFor(day))
                    ChoiceChip(
                      label: Text(DateFormat.jm(locale).format(slot)),
                      selected: _selectedSlot == slot,
                      showCheckmark: false,
                      onSelected: _isBookable(slot) ? (_) => setState(() => _selectedSlot = slot) : null,
                    ),
                ],
              ),
            const SizedBox(height: 16),
            TextField(
              controller: _noteController,
              maxLines: 2,
              maxLength: 200,
              decoration: InputDecoration(
                labelText: isArabic ? 'ملاحظة (اختياري)' : 'Note (optional)',
              ),
            ),
            if (_error != null) ...[
              const SizedBox(height: 4),
              Text(_error!, style: const TextStyle(color: AppTheme.errorColor, fontSize: 13)),
            ],
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: (_selectedSlot == null || _saving) ? null : () => _submit(isArabic),
              child: _saving
                  ? const SizedBox(height: 18, width: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : Text(
                      _selectedSlot == null
                          ? (isArabic ? 'اختار ميعاد' : 'Pick a time')
                          : (isArabic ? 'تأكيد الحجز' : 'Confirm booking'),
                    ),
            ),
          ],
        ],
      ),
    );
  }
}
