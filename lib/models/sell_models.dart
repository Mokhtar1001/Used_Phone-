/// موديلات خدمة "بيع موبايلك" (iPhone فقط).

/// اختصار للنصوص ثنائية اللغة.
String sellTr(bool isArabic, String ar, String en) => isArabic ? ar : en;

double _num(dynamic v) => (v as num?)?.toDouble() ?? 0;

/// مساحة تخزين لموديل + سعرها الأساسي (مستعمل بأحسن حالة)
class SellStorage {
  final String id;
  final String storage;
  final double basePrice;
  final int sortOrder;

  const SellStorage({this.id = '', required this.storage, required this.basePrice, this.sortOrder = 0});

  factory SellStorage.fromJson(Map<String, dynamic> json) => SellStorage(
        id: json['id'],
        storage: json['storage'],
        basePrice: _num(json['base_price']),
        sortOrder: json['sort_order'] ?? 0,
      );
}

class SellModel {
  final String id;
  final String name;
  final String? imageUrl;
  final bool isActive;
  final int sortOrder;
  final List<SellStorage> storages;

  const SellModel({
    required this.id,
    required this.name,
    this.imageUrl,
    this.isActive = true,
    this.sortOrder = 0,
    this.storages = const [],
  });

  factory SellModel.fromJson(Map<String, dynamic> json) {
    final storages = ((json['sell_model_storages'] as List?) ?? [])
        .map((e) => SellStorage.fromJson(Map<String, dynamic>.from(e)))
        .toList()
      ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
    return SellModel(
      id: json['id'],
      name: json['name'],
      imageUrl: json['image_url'],
      isActive: json['is_active'] ?? true,
      sortOrder: json['sort_order'] ?? 0,
      storages: storages,
    );
  }
}

/// اختيار داخل سؤال + الخصم المرتبط بيه
class SellOption {
  static const percent = 'percent';
  static const fixed = 'fixed';

  final String id;
  final String labelEn;
  final String? labelAr;
  final String deductionType; // percent | fixed
  final double deductionValue;
  final int? rangeMin; // للبطارية فقط
  final int? rangeMax; // للبطارية فقط
  final int sortOrder;

  const SellOption({
    this.id = '',
    required this.labelEn,
    this.labelAr,
    this.deductionType = percent,
    this.deductionValue = 0,
    this.rangeMin,
    this.rangeMax,
    this.sortOrder = 0,
  });

  bool get isPercent => deductionType == percent;

  String label(bool isArabic) => (isArabic && labelAr != null && labelAr!.trim().isNotEmpty) ? labelAr! : labelEn;

  /// قيمة الخصم بالجنيه على سعر أساسي معيّن
  double amountFor(double basePrice) => isPercent ? basePrice * deductionValue / 100 : deductionValue;

  factory SellOption.fromJson(Map<String, dynamic> json) => SellOption(
        id: json['id'],
        labelEn: json['label_en'],
        labelAr: json['label_ar'],
        deductionType: json['deduction_type'] ?? percent,
        deductionValue: _num(json['deduction_value']),
        rangeMin: json['range_min'],
        rangeMax: json['range_max'],
        sortOrder: json['sort_order'] ?? 0,
      );

  Map<String, dynamic> toInsert(String questionId, int sort) => {
        'question_id': questionId,
        'label_en': labelEn,
        'label_ar': (labelAr == null || labelAr!.trim().isEmpty) ? null : labelAr!.trim(),
        'deduction_type': deductionType,
        'deduction_value': deductionValue,
        'range_min': rangeMin,
        'range_max': rangeMax,
        'sort_order': sort,
      };
}

class SellQuestion {
  static const typeSingle = 'single';
  static const typeMulti = 'multi';
  static const typeBattery = 'battery';

  final String id;
  final String textEn;
  final String? textAr;
  final String type;
  final int sortOrder;
  final bool isActive;
  final List<SellOption> options;

  const SellQuestion({
    required this.id,
    required this.textEn,
    this.textAr,
    required this.type,
    this.sortOrder = 0,
    this.isActive = true,
    this.options = const [],
  });

  bool get isMulti => type == typeMulti;
  bool get isBattery => type == typeBattery;

  String text(bool isArabic) => (isArabic && textAr != null && textAr!.trim().isNotEmpty) ? textAr! : textEn;

  factory SellQuestion.fromJson(Map<String, dynamic> json) {
    final options = ((json['sell_question_options'] as List?) ?? [])
        .map((e) => SellOption.fromJson(Map<String, dynamic>.from(e)))
        .toList()
      ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
    return SellQuestion(
      id: json['id'],
      textEn: json['text_en'],
      textAr: json['text_ar'],
      type: json['type'],
      sortOrder: json['sort_order'] ?? 0,
      isActive: json['is_active'] ?? true,
      options: options,
    );
  }
}

class SellSettings {
  final double rangeSpreadPercent;
  const SellSettings({this.rangeSpreadPercent = 5});

  factory SellSettings.fromJson(Map<String, dynamic> json) =>
      SellSettings(rangeSpreadPercent: _num(json['range_spread_percent']));
}

/// سطر إجابة محفوظ جوه طلب البيع (بالإنجليزي عشان الأدمن)
class SellAnswerLine {
  final String question;
  final String answer;
  final double deduction;

  const SellAnswerLine({required this.question, required this.answer, required this.deduction});

  factory SellAnswerLine.fromJson(Map<String, dynamic> json) => SellAnswerLine(
        question: json['question'] ?? '',
        answer: json['answer'] ?? '',
        deduction: _num(json['deduction']),
      );

  Map<String, dynamic> toJson() => {'question': question, 'answer': answer, 'deduction': deduction};
}

class SellRequest {
  final String id;
  final String customerId;
  final String modelName;
  final String storage;
  final double basePrice;
  final List<SellAnswerLine> answers;
  final double estimateLow;
  final double estimateHigh;
  final String status; // pending / completed / rejected
  final String? adminNote;
  final DateTime createdAt;
  final String? customerName;
  final String? customerPhone;

  const SellRequest({
    required this.id,
    required this.customerId,
    required this.modelName,
    required this.storage,
    required this.basePrice,
    required this.answers,
    required this.estimateLow,
    required this.estimateHigh,
    required this.status,
    this.adminNote,
    required this.createdAt,
    this.customerName,
    this.customerPhone,
  });

  bool get isPending => status == 'pending';

  factory SellRequest.fromJson(Map<String, dynamic> json) {
    final profile = json['profiles'] as Map<String, dynamic>?;
    return SellRequest(
      id: json['id'],
      customerId: json['customer_id'],
      modelName: json['model_name'],
      storage: json['storage'],
      basePrice: _num(json['base_price']),
      answers: ((json['answers'] as List?) ?? [])
          .map((e) => SellAnswerLine.fromJson(Map<String, dynamic>.from(e)))
          .toList(),
      estimateLow: _num(json['estimate_low']),
      estimateHigh: _num(json['estimate_high']),
      status: json['status'] ?? 'pending',
      adminNote: json['admin_note'],
      createdAt: DateTime.parse(json['created_at']),
      customerName: profile?['full_name'],
      customerPhone: profile?['phone'],
    );
  }
}
