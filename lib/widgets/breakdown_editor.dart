import 'package:flutter/material.dart';
import '../models/condition_item.dart';

class BreakdownRowCtrl {
  final label = TextEditingController();
  final value = TextEditingController();
  void dispose() {
    label.dispose();
    value.dispose();
  }
}

/// بيمسك صفوف "تفاصيل الحالة" (Screen → Like New ...): الشاشة بتعمله load وبتاخد build() وقت الحفظ.
class BreakdownEditorController {
  final rows = <BreakdownRowCtrl>[];

  void load(List<ConditionItem> items) {
    // مبنعملش dispose للقديم هنا: الحقول ممكن لسه ظاهرة لحد ما تتعمل rebuild
    rows.clear();
    for (final i in items) {
      rows.add(BreakdownRowCtrl()
        ..label.text = i.label
        ..value.text = i.value);
    }
  }

  /// الصفوف الفاضية خالص بتتشال
  List<ConditionItem> build() => [
        for (final r in rows)
          if (r.label.text.trim().isNotEmpty || r.value.text.trim().isNotEmpty)
            ConditionItem(label: r.label.text.trim(), value: r.value.text.trim()),
      ];

  void dispose() {
    for (final r in rows) {
      r.dispose();
    }
  }
}

/// محرر تفاصيل الحالة للأدمن: صفوف (الجزء + حالته) بتضيف وتمسح براحتك.
class BreakdownEditor extends StatefulWidget {
  final BreakdownEditorController controller;
  final bool isArabic;
  const BreakdownEditor({super.key, required this.controller, required this.isArabic});

  @override
  State<BreakdownEditor> createState() => _BreakdownEditorState();
}

class _BreakdownEditorState extends State<BreakdownEditor> {
  BreakdownEditorController get c => widget.controller;
  bool get ar => widget.isArabic;

  void _add([String label = '']) => setState(() => c.rows.add(BreakdownRowCtrl()..label.text = label));

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          ar
              ? 'اختياري. بيظهر في قسم Condition breakdown في صفحة المنتج. صحة البطارية بتتضاف لوحدها للآيفون.'
              : 'Optional. Shown in the "Condition breakdown" section. Battery health is added automatically for iPhones.',
          style: const TextStyle(fontSize: 12),
        ),
        const SizedBox(height: 12),
        for (var i = 0; i < c.rows.length; i++)
          Padding(
            key: ObjectKey(c.rows[i]),
            padding: const EdgeInsets.only(bottom: 10),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  flex: 2,
                  child: TextFormField(
                    controller: c.rows[i].label,
                    decoration: InputDecoration(labelText: ar ? 'الجزء' : 'Part', hintText: 'Screen'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  flex: 3,
                  child: TextFormField(
                    controller: c.rows[i].value,
                    decoration: InputDecoration(labelText: ar ? 'الحالة' : 'Condition', hintText: 'Like New'),
                  ),
                ),
                IconButton(
                  tooltip: ar ? 'حذف' : 'Remove',
                  onPressed: () => setState(() => c.rows.removeAt(i)),
                  icon: const Icon(Icons.delete_outline),
                ),
              ],
            ),
          ),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            OutlinedButton.icon(
              onPressed: _add,
              icon: const Icon(Icons.add),
              label: Text(ar ? 'إضافة صف' : 'Add row'),
            ),
            for (final name in const ['Screen', 'Back', 'Sides'])
              ActionChip(label: Text('+ $name'), onPressed: () => _add(name)),
          ],
        ),
      ],
    );
  }
}
