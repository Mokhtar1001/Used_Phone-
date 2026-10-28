/// نصوص الدرجة (A/B/C) المشتركة بين السلة وباقي الصفحات
String gradeName(String letter, bool ar) {
  switch (letter) {
    case 'A':
      return ar ? 'ممتازة' : 'Excellent';
    case 'B':
      return ar ? 'جيدة' : 'Good';
    default:
      return ar ? 'مقبولة' : 'Fair';
  }
}

/// "Grade A — Excellent condition"
String gradeLabel(String letter, bool ar) =>
    ar ? 'الدرجة $letter — حالة ${gradeName(letter, true)}' : 'Grade $letter — ${gradeName(letter, false)} condition';
