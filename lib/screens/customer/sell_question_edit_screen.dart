import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../core/theme.dart';
import '../../models/sell_models.dart';
import '../../providers/locale_provider.dart';
import '../../services/sell_service.dart';

class _OptionRow {
  final TextEditingController labelEn;
  final TextEditingController labelAr;
  final TextEditingController value;
  final TextEditingController min;
  final TextEditingController max;
  String deductionType;

  _OptionRow({SellOption? option})
      : labelEn = TextEditingController(text: option?.labelEn ?? ''),
        labelAr = TextEditingController(text: option?.labelAr ?? ''),
        value = TextEditingController(
            text: option == null ? '0' : option.deductionValue.toStringAsFixed(option.deductionValue % 1 == 0 ? 0 : 2)),
        min = TextEditingController(text: option?.rangeMin?.toString() ?? ''),
        max = TextEditingController(text: option?.rangeMax?.toString() ?? ''),
        deductionType = option?.deductionType ?? SellOption.percent;

  void dispose() {
    labelEn.dispose();
    labelAr.dispose();
    value.dispose();
    min.dispose();
    max.dispose();
  }
}

/// إضافة / تعديل سؤال: نصه + نوعه + الاختيارات، وكل اختيار ليه خصم (نسبة % أو مبلغ ثابت).
/// أمثلة: الشاشة (سليمة 0% / خدوش خفيفة 5% / متخربشة جامد 15%)،
/// البطارية (رينجات: 95–100 = 0%، 90–94 = 4% ...)، اتفتح/اتصلّح، العلبة، البرشامة، قطع متغيرة...
class SellQuestionEditScreen extends StatefulWidget {
  final SellQuestion? question;
  const SellQuestionEditScreen({super.key, this.question});

  @override
  State<SellQuestionEditScreen> createState() => _SellQuestionEditScreenState();
}

class _SellQuestionEditScreenState extends State<SellQuestionEditScreen> {
  final _service = SellService();
  final _textEn = TextEditingController();
  final _textAr = TextEditingController();
  final List<_OptionRow> _rows = [];

  String _type = SellQuestion.typeSingle;
  bool _isActive = true;
  bool _saving = false;
  bool _ar = false;

  bool get _isEditing => widget.question != null;
  bool get _isBattery => _type == SellQuestion.typeBattery;
  String _t(String ar, String en) => sellTr(_ar, ar, en);

  @override
  void initState() {
    super.initState();
    final q = widget.question;
    if (q != null) {
      _textEn.text = q.textEn;
      _textAr.text = q.textAr ?? '';
      _type = q.type;
      _isActive = q.isActive;
      for (final o in q.options) {
        _rows.add(_OptionRow(option: o));
      }
    }
    if (_rows.isEmpty) _rows.add(_OptionRow());
  }

  @override
  void dispose() {
    _textEn.dispose();
    _textAr.dispose();
    for (final r in _rows) {
      r.dispose();
    }
    super.dispose();
  }

  void _snack(String msg) => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));

  Future<void> _save() async {
    final textEn = _textEn.text.trim();
    if (textEn.isEmpty) {
      _snack(_t('اكتب نص السؤال (إنجليزي)', 'Enter the question text (English)'));
      return;
    }

    final options = <SellOption>[];
    for (final r in _rows) {
      final value = double.tryParse(r.value.text.trim());
      if (value == null || value < 0) {
        _snack(_t('قيمة الخصم لازم تكون رقم صفر أو أكتر', 'Deduction must be a number, zero or more'));
        return;
      }
      if (r.deductionType == SellOption.percent && value > 100) {
        _snack(_t('النسبة لازم تكون من 0 لـ 100', 'Percentage must be between 0 and 100'));
        return;
      }

      int? min;
      int? max;
      var labelEn = r.labelEn.text.trim();

      if (_isBattery) {
        min = int.tryParse(r.min.text.trim());
        max = int.tryParse(r.max.text.trim());
        if (min == null || max == null || min < 0 || max > 100 || min > max) {
          _snack(_t('رينج البطارية لازم يكون من 0 لـ 100 والأقل قبل الأعلى', 'Battery range must be within 0–100, from lower to higher'));
          return;
        }
        if (labelEn.isEmpty) labelEn = '$min–$max%';
      } else if (labelEn.isEmpty) {
        _snack(_t('كل اختيار لازم يكون له اسم (إنجليزي)', 'Every option needs a name (English)'));
        return;
      }

      options.add(SellOption(
        labelEn: labelEn,
        labelAr: r.labelAr.text.trim(),
        deductionType: r.deductionType,
        deductionValue: value,
        rangeMin: min,
        rangeMax: max,
      ));
    }

    if (options.isEmpty) {
      _snack(_t('أضف اختيار واحد على الأقل', 'Add at least one option'));
      return;
    }

    setState(() => _saving = true);
    try {
      await _service.saveQuestion(
        id: widget.question?.id,
        textEn: textEn,
        textAr: _textAr.text,
        type: _type,
        isActive: _isActive,
        options: options,
      );
      if (mounted) Navigator.pop(context);
    } catch (_) {
      _snack(_t('حصل خطأ أثناء الحفظ', 'Something went wrong while saving'));
      if (mounted) setState(() => _saving = false);
    }
  }

  Widget _typeChip(String type, String label) {
    return ChoiceChip(
      label: Text(label),
      selected: _type == type,
      showCheckmark: false,
      selectedColor: AppTheme.charcoal,
      labelStyle: TextStyle(color: _type == type ? AppTheme.pureWhite : AppTheme.charcoal),
      onSelected: (_) => setState(() => _type = type),
    );
  }

  @override
  Widget build(BuildContext context) {
    _ar = context.watch<LocaleProvider>().isArabic;

    return Scaffold(
      appBar: AppBar(title: Text(_isEditing ? _t('تعديل سؤال', 'Edit question') : _t('إضافة سؤال', 'Add question'))),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 720),
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              TextField(
                controller: _textEn,
                decoration: InputDecoration(
                  labelText: _t('نص السؤال (إنجليزي)', 'Question text (English)'),
                  hintText: 'How is the screen?',
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _textAr,
                decoration: InputDecoration(labelText: _t('نص السؤال (عربي - اختياري)', 'Question text (Arabic - optional)')),
              ),
              const SizedBox(height: 16),
              Text(_t('نوع السؤال', 'Question type'), style: const TextStyle(fontWeight: FontWeight.w700)),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _typeChip(SellQuestion.typeSingle, _t('اختيار واحد', 'Single answer')),
                  _typeChip(SellQuestion.typeMulti, _t('أكتر من اختيار (قطع متغيرة...)', 'Multiple answers (replaced parts...)')),
                  _typeChip(SellQuestion.typeBattery, _t('صحة البطارية (رينجات)', 'Battery health (ranges)')),
                ],
              ),
              if (_isBattery)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                    _t(
                      'الزبون بيكتب نسبة صحة البطارية، والنظام بيختار الرينج المناسب. لو النسبة بين رينجين بياخد أقرب رينج أقل منها.',
                      'The customer types the battery health %, and the matching range is used. If the value falls between two ranges, the nearest lower range applies.',
                    ),
                    style: const TextStyle(fontSize: 12.5, color: AppTheme.deepGray, height: 1.5),
                  ),
                ),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(_t('ظاهر للزبائن', 'Visible to customers')),
                value: _isActive,
                onChanged: (v) => setState(() => _isActive = v),
              ),
              const Divider(),
              const SizedBox(height: 4),
              Text(_isBattery ? _t('الرينجات والخصم', 'Ranges & deductions') : _t('الاختيارات والخصم', 'Options & deductions'),
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
              const SizedBox(height: 10),
              for (var i = 0; i < _rows.length; i++) _optionCard(i),
              Align(
                alignment: AlignmentDirectional.centerStart,
                child: TextButton.icon(
                  onPressed: () => setState(() => _rows.add(_OptionRow())),
                  icon: const Icon(Icons.add, size: 18),
                  label: Text(_isBattery ? _t('رينج تاني', 'Add range') : _t('اختيار تاني', 'Add option')),
                ),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _saving ? null : _save,
                child: _saving
                    ? const SizedBox(height: 18, width: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : Text(_t('حفظ', 'Save')),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _optionCard(int i) {
    final r = _rows[i];
    final isPercent = r.deductionType == SellOption.percent;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.offWhite,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.lightGray),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (_isBattery)
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: r.min,
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(3)],
                    decoration: InputDecoration(labelText: _t('من %', 'From %')),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: TextField(
                    controller: r.max,
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(3)],
                    decoration: InputDecoration(labelText: _t('إلى %', 'To %')),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close, size: 20),
                  onPressed: _rows.length == 1 ? null : () => setState(() => _rows.removeAt(i).dispose()),
                ),
              ],
            )
          else ...[
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: r.labelEn,
                    decoration: InputDecoration(labelText: _t('الاختيار (إنجليزي)', 'Option (English)'), hintText: 'Light scratches'),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close, size: 20),
                  onPressed: _rows.length == 1 ? null : () => setState(() => _rows.removeAt(i).dispose()),
                ),
              ],
            ),
            const SizedBox(height: 10),
            TextField(
              controller: r.labelAr,
              decoration: InputDecoration(labelText: _t('الاختيار (عربي - اختياري)', 'Option (Arabic - optional)')),
            ),
          ],
          const SizedBox(height: 12),
          Row(
            children: [
              Wrap(
                spacing: 6,
                children: [
                  ChoiceChip(
                    label: const Text('%'),
                    selected: isPercent,
                    showCheckmark: false,
                    selectedColor: AppTheme.charcoal,
                    labelStyle: TextStyle(color: isPercent ? AppTheme.pureWhite : AppTheme.charcoal),
                    onSelected: (_) => setState(() => r.deductionType = SellOption.percent),
                  ),
                  ChoiceChip(
                    label: Text(_t('ج.م', 'EGP')),
                    selected: !isPercent,
                    showCheckmark: false,
                    selectedColor: AppTheme.charcoal,
                    labelStyle: TextStyle(color: !isPercent ? AppTheme.pureWhite : AppTheme.charcoal),
                    onSelected: (_) => setState(() => r.deductionType = SellOption.fixed),
                  ),
                ],
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextField(
                  controller: r.value,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9.]'))],
                  decoration: InputDecoration(
                    labelText: _t('الخصم', 'Deduction'),
                    suffixText: isPercent ? '%' : _t('ج.م', 'EGP'),
                    helperText: _t('0 = من غير خصم', '0 = no deduction'),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
