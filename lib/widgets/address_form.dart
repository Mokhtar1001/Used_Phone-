import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../core/egypt_governorates.dart';
import '../core/theme.dart';
import '../models/address.dart';
import '../providers/auth_provider.dart';
import '../providers/locale_provider.dart';
import '../services/address_service.dart';
import 'auth_widgets.dart';

/// حقول العنوان (المحافظة، المنطقة، الشارع، العمارة، علامة مميزة، والاسم اختياريًا)
class AddressFieldsController {
  String? governorate;
  final label = TextEditingController(text: 'Home');
  final city = TextEditingController();
  final street = TextEditingController();
  final building = TextEditingController();
  final landmark = TextEditingController();

  /// هل العميل كتب أي حاجة؟ (للتسجيل: العنوان اختياري، بس لو بدأ يكتب لازم يكمّل الإجباري)
  bool get hasAny =>
      governorate != null ||
      city.text.trim().isNotEmpty ||
      street.text.trim().isNotEmpty ||
      building.text.trim().isNotEmpty ||
      landmark.text.trim().isNotEmpty;

  void load(Address a) {
    governorate = a.governorate.isEmpty ? null : a.governorate;
    label.text = a.label;
    city.text = a.city ?? '';
    street.text = a.street;
    building.text = a.building ?? '';
    landmark.text = a.landmark ?? '';
  }

  String? _clean(TextEditingController c) => c.text.trim().isEmpty ? null : c.text.trim();

  Address toAddress({String? id}) => Address(
        id: id,
        label: label.text.trim().isEmpty ? 'Home' : label.text.trim(),
        governorate: governorate ?? '',
        city: _clean(city),
        street: street.text.trim(),
        building: _clean(building),
        landmark: _clean(landmark),
      );

  void dispose() {
    label.dispose();
    city.dispose();
    street.dispose();
    building.dispose();
    landmark.dispose();
  }
}

class AddressFields extends StatefulWidget {
  final AddressFieldsController controller;
  final bool isArabic;

  /// true: المحافظة والشارع إجباريين دايمًا. false (التسجيل): إجباريين بس لو العميل كتب أي حاجة في العنوان.
  final bool requiredFields;
  final bool showLabel;

  const AddressFields({
    super.key,
    required this.controller,
    required this.isArabic,
    this.requiredFields = true,
    this.showLabel = true,
  });

  @override
  State<AddressFields> createState() => _AddressFieldsState();
}

class _AddressFieldsState extends State<AddressFields> {
  AddressFieldsController get c => widget.controller;
  bool get ar => widget.isArabic;

  bool get _mustFill => widget.requiredFields || c.hasAny;

  @override
  Widget build(BuildContext context) {
    final requiredMsg = ar ? 'مطلوب' : 'Required';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (widget.showLabel)
          authField(
            label: ar ? 'اسم العنوان' : 'Address name',
            bottom: 14,
            child: TextFormField(controller: c.label, decoration: authInputDecoration(ar ? 'البيت، الشغل...' : 'Home, Work...')),
          ),
        authField(
          label: ar ? 'المحافظة' : 'Governorate',
          bottom: 14,
          child: DropdownButtonFormField<String>(
            value: c.governorate,
            isExpanded: true,
            decoration: authInputDecoration(ar ? 'اختار المحافظة' : 'Select governorate'),
            items: [
              for (final g in egyptGovernorates) DropdownMenuItem(value: g.en, child: Text(ar ? g.ar : g.en)),
            ],
            onChanged: (v) => setState(() => c.governorate = v),
            validator: (v) => (_mustFill && v == null) ? requiredMsg : null,
          ),
        ),
        authField(
          label: ar ? 'المدينة / المنطقة' : 'City / area',
          bottom: 14,
          child: TextFormField(
            controller: c.city,
            textInputAction: TextInputAction.next,
            decoration: authInputDecoration(ar ? 'مثال: مدينة نصر' : 'e.g. Nasr City'),
          ),
        ),
        authField(
          label: ar ? 'الشارع' : 'Street',
          bottom: 14,
          child: TextFormField(
            controller: c.street,
            textInputAction: TextInputAction.next,
            decoration: authInputDecoration(ar ? 'اسم الشارع' : 'Street name'),
            validator: (v) => (_mustFill && (v == null || v.trim().isEmpty)) ? requiredMsg : null,
          ),
        ),
        authField(
          label: ar ? 'عمارة / دور / شقة' : 'Building / floor / apartment',
          bottom: 14,
          child: TextFormField(
            controller: c.building,
            textInputAction: TextInputAction.next,
            decoration: authInputDecoration(ar ? 'رقم العمارة، الدور، الشقة' : 'Building no., floor, apt.'),
          ),
        ),
        authField(
          label: ar ? 'علامة مميزة (اختياري)' : 'Landmark (optional)',
          bottom: 4,
          child: TextFormField(controller: c.landmark, decoration: authInputDecoration(ar ? 'جنب...' : 'Near...')),
        ),
      ],
    );
  }
}

/// نتيجة بوب أب العنوان: [saved] لو اتحفظ/اتعدّل، [deleted] لو اتمسح. null = العميل قفل من غير ما يعمل حاجة.
typedef AddressDialogResult = ({Address? saved, bool deleted});

/// بوب أب إضافة/تعديل عنوان. بيحفظ في الداتابيز بنفسه.
Future<AddressDialogResult?> showAddressFormDialog(
  BuildContext context, {
  Address? existing,
  String defaultLabel = 'Home',
}) {
  return showDialog<AddressDialogResult>(
    context: context,
    builder: (_) => _AddressDialog(existing: existing, defaultLabel: defaultLabel),
  );
}

class _AddressDialog extends StatefulWidget {
  final Address? existing;
  final String defaultLabel;
  const _AddressDialog({this.existing, required this.defaultLabel});

  @override
  State<_AddressDialog> createState() => _AddressDialogState();
}

class _AddressDialogState extends State<_AddressDialog> {
  final _formKey = GlobalKey<FormState>();
  final _fields = AddressFieldsController();
  final _service = AddressService();
  bool _busy = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    if (widget.existing != null) {
      _fields.load(widget.existing!);
    } else {
      _fields.label.text = widget.defaultLabel;
    }
  }

  @override
  void dispose() {
    _fields.dispose();
    super.dispose();
  }

  Future<void> _save(bool isArabic) async {
    if (!_formKey.currentState!.validate()) return;
    final userId = context.read<AuthProvider>().profile?.id;
    if (userId == null) return;

    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final saved = await _service.save(userId, _fields.toAddress(id: widget.existing?.id));
      if (mounted) Navigator.pop(context, (saved: saved, deleted: false));
    } on PostgrestException catch (e) {
      if (!mounted) return;
      setState(() {
        _busy = false;
        _error = e.message.contains('address_limit')
            ? (isArabic ? 'ينفع تحفظ عنوانين بس' : 'You can save up to 2 addresses')
            : (isArabic ? 'حصل خطأ، حاول تاني' : 'Something went wrong, please try again');
      });
    } catch (_) {
      if (mounted) {
        setState(() {
          _busy = false;
          _error = isArabic ? 'حصل خطأ، حاول تاني' : 'Something went wrong, please try again';
        });
      }
    }
  }

  Future<void> _delete(bool isArabic) async {
    final id = widget.existing?.id;
    if (id == null) return;
    setState(() => _busy = true);
    try {
      await _service.delete(id);
      if (mounted) Navigator.pop(context, (saved: null, deleted: true));
    } catch (_) {
      if (mounted) {
        setState(() {
          _busy = false;
          _error = isArabic ? 'مقدرناش نمسح العنوان' : "Couldn't delete the address";
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isArabic = context.watch<LocaleProvider>().isArabic;
    final editing = widget.existing != null;

    return Dialog(
      backgroundColor: AppTheme.pureWhite,
      surfaceTintColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 440),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  editing ? (isArabic ? 'تعديل العنوان' : 'Edit address') : (isArabic ? 'إضافة عنوان توصيل' : 'Add delivery address'),
                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 18),
                AddressFields(controller: _fields, isArabic: isArabic),
                if (_error != null) ...[
                  const SizedBox(height: 12),
                  Text(_error!, style: const TextStyle(color: AppTheme.errorColor, fontSize: 13)),
                ],
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: _busy ? null : () => _save(isArabic),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.charcoal,
                    foregroundColor: AppTheme.pureWhite,
                    elevation: 0,
                    minimumSize: const Size.fromHeight(50),
                    shape: const StadiumBorder(),
                    textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                  ),
                  child: _busy
                      ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : Text(isArabic ? 'حفظ العنوان' : 'Save address'),
                ),
                const SizedBox(height: 6),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    TextButton(
                      onPressed: _busy ? null : () => Navigator.pop(context),
                      child: Text(isArabic ? 'إلغاء' : 'Cancel'),
                    ),
                    if (editing)
                      TextButton(
                        onPressed: _busy ? null : () => _delete(isArabic),
                        style: TextButton.styleFrom(foregroundColor: AppTheme.errorColor),
                        child: Text(isArabic ? 'مسح العنوان' : 'Delete'),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
