/// عنصر في "Condition breakdown": اسم الجزء + حالته. مثال: Screen → Like New.
class ConditionItem {
  final String label;
  final String value;
  const ConditionItem({required this.label, required this.value});

  factory ConditionItem.fromJson(Map<String, dynamic> json) => ConditionItem(
        label: (json['k'] ?? '').toString(),
        value: (json['v'] ?? '').toString(),
      );

  Map<String, dynamic> toJson() => {'k': label, 'v': value};

  /// بيقرا جيسون عمود condition_breakdown (قايمة) بأمان
  static List<ConditionItem> listFromJson(dynamic json) {
    if (json is! List) return const [];
    return json
        .whereType<Map>()
        .map((e) => ConditionItem.fromJson(Map<String, dynamic>.from(e)))
        .where((e) => e.label.isNotEmpty || e.value.isNotEmpty)
        .toList();
  }
}
