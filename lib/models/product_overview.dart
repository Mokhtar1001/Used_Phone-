/// قسم واحد في الـ Overview (عنوان + فقرة). مثال: "iPhone 15 Pro Max Camera" + وصف الكاميرا.
class OverviewSection {
  final String title;
  final String body;
  const OverviewSection({required this.title, required this.body});

  factory OverviewSection.fromJson(Map<String, dynamic> json) => OverviewSection(
        title: (json['title'] ?? '').toString(),
        body: (json['body'] ?? '').toString(),
      );

  Map<String, dynamic> toJson() => {'title': title, 'body': body};
}

/// سؤال وجواب
class OverviewFaq {
  final String question;
  final String answer;
  const OverviewFaq({required this.question, required this.answer});

  factory OverviewFaq.fromJson(Map<String, dynamic> json) => OverviewFaq(
        question: (json['q'] ?? '').toString(),
        answer: (json['a'] ?? '').toString(),
      );

  Map<String, dynamic> toJson() => {'q': question, 'a': answer};
}

/// الـ Overview اللي الأدمن بيكتبه لكل منتج (مش ثابت): عنوان + مقدمة + أقسام + أسئلة شائعة.
/// بيتخزن في عمود products.overview (jsonb). كله اختياري، ولو فاضي الصفحة مبتعرضش الجزء ده.
class ProductOverview {
  final String title;
  final String intro;
  final List<OverviewSection> sections;
  final String faqTitle;
  final List<OverviewFaq> faqs;

  const ProductOverview({
    this.title = '',
    this.intro = '',
    this.sections = const [],
    this.faqTitle = '',
    this.faqs = const [],
  });

  bool get isEmpty => title.isEmpty && intro.isEmpty && sections.isEmpty && faqs.isEmpty;

  /// بيرجّع null لو مفيش overview أو لو فاضي
  static ProductOverview? fromJson(dynamic json) {
    if (json is! Map) return null;
    final map = Map<String, dynamic>.from(json);

    List<T> parseList<T>(dynamic value, T Function(Map<String, dynamic>) build) {
      if (value is! List) return <T>[];
      return value.whereType<Map>().map((e) => build(Map<String, dynamic>.from(e))).toList();
    }

    final overview = ProductOverview(
      title: (map['title'] ?? '').toString(),
      intro: (map['intro'] ?? '').toString(),
      sections: parseList(map['sections'], OverviewSection.fromJson),
      faqTitle: (map['faq_title'] ?? '').toString(),
      faqs: parseList(map['faqs'], OverviewFaq.fromJson),
    );
    return overview.isEmpty ? null : overview;
  }

  Map<String, dynamic> toJson() => {
        'title': title,
        'intro': intro,
        'sections': sections.map((e) => e.toJson()).toList(),
        'faq_title': faqTitle,
        'faqs': faqs.map((e) => e.toJson()).toList(),
      };
}
