import 'package:flutter/material.dart';
import '../models/product_overview.dart';

/// حقول قسم واحد في محرر الـ Overview
class OverviewSectionCtrl {
  final title = TextEditingController();
  final body = TextEditingController();
  void dispose() {
    title.dispose();
    body.dispose();
  }
}

/// حقول سؤال/جواب واحد
class OverviewFaqCtrl {
  final question = TextEditingController();
  final answer = TextEditingController();
  void dispose() {
    question.dispose();
    answer.dispose();
  }
}

/// بيمسك كل حقول الـ Overview: الشاشة بتعمله load من المنتج وتاخد منه build() وقت الحفظ.
class OverviewEditorController {
  final title = TextEditingController();
  final intro = TextEditingController();
  final faqTitle = TextEditingController();
  final sections = <OverviewSectionCtrl>[];
  final faqs = <OverviewFaqCtrl>[];

  /// يملا المحرر من overview موجود (أو يفضّيه لو null)
  void load(ProductOverview? overview) {
    // مبنعملش dispose للقديم هنا: الحقول ممكن لسه ظاهرة في الشاشة لحد ما تتعمل rebuild
    sections.clear();
    faqs.clear();

    title.text = overview?.title ?? '';
    intro.text = overview?.intro ?? '';
    faqTitle.text = overview?.faqTitle ?? '';
    for (final s in overview?.sections ?? const <OverviewSection>[]) {
      sections.add(OverviewSectionCtrl()
        ..title.text = s.title
        ..body.text = s.body);
    }
    for (final f in overview?.faqs ?? const <OverviewFaq>[]) {
      faqs.add(OverviewFaqCtrl()
        ..question.text = f.question
        ..answer.text = f.answer);
    }
  }

  /// بيرجّع الـ Overview الجاهز للحفظ، أو null لو كل حاجة فاضية.
  /// الأقسام/الأسئلة الفاضية خالص بتتشال.
  ProductOverview? build() {
    final overview = ProductOverview(
      title: title.text.trim(),
      intro: intro.text.trim(),
      sections: [
        for (final s in sections)
          if (s.title.text.trim().isNotEmpty || s.body.text.trim().isNotEmpty)
            OverviewSection(title: s.title.text.trim(), body: s.body.text.trim()),
      ],
      faqTitle: faqTitle.text.trim(),
      faqs: [
        for (final f in faqs)
          if (f.question.text.trim().isNotEmpty || f.answer.text.trim().isNotEmpty)
            OverviewFaq(question: f.question.text.trim(), answer: f.answer.text.trim()),
      ],
    );
    return overview.isEmpty ? null : overview;
  }

  void dispose() {
    title.dispose();
    intro.dispose();
    faqTitle.dispose();
    for (final s in sections) {
      s.dispose();
    }
    for (final f in faqs) {
      f.dispose();
    }
  }
}

/// محرر الـ Overview للأدمن: عنوان + مقدمة + أقسام (بتضيف وتمسح براحتك) + أسئلة شائعة.
class OverviewEditor extends StatefulWidget {
  final OverviewEditorController controller;
  final bool isArabic;
  const OverviewEditor({super.key, required this.controller, required this.isArabic});

  @override
  State<OverviewEditor> createState() => _OverviewEditorState();
}

class _OverviewEditorState extends State<OverviewEditor> {
  OverviewEditorController get c => widget.controller;
  bool get ar => widget.isArabic;

  Widget _entryCard({required Key key, required String heading, required VoidCallback onRemove, required List<Widget> children}) {
    return Container(
      key: key,
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.fromLTRB(12, 4, 4, 12),
      decoration: BoxDecoration(
        border: Border.all(color: Theme.of(context).dividerColor),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(child: Text(heading, style: const TextStyle(fontWeight: FontWeight.w600))),
              IconButton(
                tooltip: ar ? 'حذف' : 'Remove',
                onPressed: onRemove,
                icon: const Icon(Icons.delete_outline),
              ),
            ],
          ),
          Padding(
            padding: const EdgeInsetsDirectional.only(end: 8),
            child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: children),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          ar
              ? 'اختياري. بيظهر في صفحة المنتج على الجنب. اكتب براحتك، وكل منتج له Overview مختلف. لو سبته فاضي مفيش حاجة هتظهر.'
              : 'Optional. Shown beside the product on its page. Each product can have a different overview. Leave empty to hide it.',
          style: const TextStyle(fontSize: 12),
        ),
        const SizedBox(height: 12),
        TextFormField(
          controller: c.title,
          decoration: InputDecoration(
            labelText: ar ? 'العنوان' : 'Title',
            hintText: 'Apple iPhone 15 Pro Max Specifications',
          ),
        ),
        const SizedBox(height: 12),
        TextFormField(
          controller: c.intro,
          maxLines: 2,
          decoration: InputDecoration(labelText: ar ? 'مقدمة قصيرة' : 'Short intro'),
        ),
        const SizedBox(height: 16),
        Text(ar ? 'الأقسام' : 'Sections', style: const TextStyle(fontWeight: FontWeight.w700)),
        const SizedBox(height: 8),
        for (var i = 0; i < c.sections.length; i++)
          _entryCard(
            key: ObjectKey(c.sections[i]),
            heading: '${ar ? 'قسم' : 'Section'} ${i + 1}',
            onRemove: () => setState(() => c.sections.removeAt(i)),
            children: [
              TextFormField(
                controller: c.sections[i].title,
                decoration: InputDecoration(
                  labelText: ar ? 'عنوان القسم' : 'Section title',
                  hintText: 'iPhone 15 Pro Max Camera',
                ),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: c.sections[i].body,
                maxLines: 4,
                decoration: InputDecoration(labelText: ar ? 'النص' : 'Text'),
              ),
            ],
          ),
        OutlinedButton.icon(
          onPressed: () => setState(() => c.sections.add(OverviewSectionCtrl())),
          icon: const Icon(Icons.add),
          label: Text(ar ? 'إضافة قسم' : 'Add section'),
        ),
        const SizedBox(height: 20),
        Text(ar ? 'الأسئلة الشائعة' : 'FAQs', style: const TextStyle(fontWeight: FontWeight.w700)),
        const SizedBox(height: 8),
        TextFormField(
          controller: c.faqTitle,
          decoration: InputDecoration(
            labelText: ar ? 'عنوان الأسئلة (اختياري)' : 'FAQ heading (optional)',
            hintText: 'FAQs: Apple iPhone 15 Pro Max Refurbished',
          ),
        ),
        const SizedBox(height: 12),
        for (var i = 0; i < c.faqs.length; i++)
          _entryCard(
            key: ObjectKey(c.faqs[i]),
            heading: '${ar ? 'سؤال' : 'Question'} ${i + 1}',
            onRemove: () => setState(() => c.faqs.removeAt(i)),
            children: [
              TextFormField(
                controller: c.faqs[i].question,
                decoration: InputDecoration(labelText: ar ? 'السؤال' : 'Question'),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: c.faqs[i].answer,
                maxLines: 3,
                decoration: InputDecoration(labelText: ar ? 'الإجابة' : 'Answer'),
              ),
            ],
          ),
        OutlinedButton.icon(
          onPressed: () => setState(() => c.faqs.add(OverviewFaqCtrl())),
          icon: const Icon(Icons.add),
          label: Text(ar ? 'إضافة سؤال' : 'Add question'),
        ),
      ],
    );
  }
}
