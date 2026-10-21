import 'package:flutter/material.dart';
import '../core/theme.dart';

class OverviewSection {
  final String title, body;
  const OverviewSection(this.title, this.body);
}

class FaqItem {
  final String q, a;
  const FaqItem(this.q, this.a);
}

class ProductOverview {
  final String? title, intro;
  final List<OverviewSection> sections;
  final List<FaqItem> faqs;

  const ProductOverview({this.title, this.intro, this.sections = const [], this.faqs = const []});

  /// raw شكله: {"en": {...}, "ar": {...}}  (لو لغة ناقصة بيستخدم التانية)
  static ProductOverview? fromJson(Map<String, dynamic>? raw, bool isArabic) {
    if (raw == null) return null;
    final data = raw[isArabic ? 'ar' : 'en'] ?? raw['en'] ?? raw['ar'];
    if (data is! Map) return null;

    final sections = ((data['sections'] ?? []) as List)
        .map((e) => OverviewSection('${e['title'] ?? ''}', '${e['body'] ?? ''}'))
        .toList();
    final faqs = ((data['faqs'] ?? []) as List)
        .map((e) => FaqItem('${e['q'] ?? ''}', '${e['a'] ?? ''}'))
        .toList();

    final o = ProductOverview(
      title: data['title'] as String?,
      intro: data['intro'] as String?,
      sections: sections,
      faqs: faqs,
    );
    return (o.title == null && o.intro == null && sections.isEmpty && faqs.isEmpty) ? null : o;
  }
}

class OverviewPanel extends StatelessWidget {
  final ProductOverview overview;
  final bool isArabic;
  const OverviewPanel({super.key, required this.overview, required this.isArabic});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.offWhite,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.lightGray),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(isArabic ? 'نظرة عامة' : 'Overview',
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
          if (overview.title != null) ...[
            const SizedBox(height: 14),
            Text(overview.title!, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
          ],
          if (overview.intro != null) ...[
            const SizedBox(height: 6),
            Text(overview.intro!, style: const TextStyle(height: 1.5)),
          ],
          for (final s in overview.sections) ...[
            const SizedBox(height: 20),
            Text(s.title, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
            const SizedBox(height: 6),
            Text(s.body, style: const TextStyle(height: 1.55)),
          ],
          if (overview.faqs.isNotEmpty) ...[
            const SizedBox(height: 24),
            Text(isArabic ? 'الأسئلة الشائعة' : 'FAQs',
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            Theme(
              data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
              child: Column(
                children: [
                  for (var i = 0; i < overview.faqs.length; i++)
                    ExpansionTile(
                      tilePadding: EdgeInsets.zero,
                      childrenPadding: const EdgeInsets.only(bottom: 12),
                      expandedCrossAxisAlignment: CrossAxisAlignment.start,
                      title: Text('${i + 1}. ${overview.faqs[i].q}',
                          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                      children: [Text(overview.faqs[i].a, style: const TextStyle(height: 1.5))],
                    ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}