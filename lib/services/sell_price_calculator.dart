import '../models/sell_models.dart';

/// إجابة الزبون على سؤال واحد (option = null لما سؤال multi يتسجل "ولا حاجة").
class SellPick {
  final SellQuestion question;
  final SellOption? option;

  /// النص الإنجليزي اللي بيتخزن في طلب البيع (للبطارية بيكون مثلًا "92%")
  final String answerText;

  const SellPick({required this.question, required this.option, required this.answerText});
}

class SellQuote {
  final double basePrice;
  final double totalDeduction;
  final double estimate; // السعر بعد الخصومات
  final double low; // أقل السعر في الرينج
  final double high; // أعلى السعر في الرينج
  final List<SellAnswerLine> lines;

  const SellQuote({
    required this.basePrice,
    required this.totalDeduction,
    required this.estimate,
    required this.low,
    required this.high,
    required this.lines,
  });
}

/// حساب السعر. كل المنطق في مكان واحد عشان أي تعديل مستقبلي يبقى سهل.
///
///  السعر التقديري = السعر الأساسي للمساحة − مجموع الخصومات (بتتجمع على بعض)
///  الرينج = من (التقديري × (1 − الهامش%)) إلى التقديري
class SellPriceCalculator {
  /// اختيار رينج البطارية المناسب لقيمة صحة البطارية:
  /// الرينج اللي القيمة جواه، ولو القيمة بين رينجين ياخد أقرب رينج أقل منها،
  /// ولو أقل من كل الرينجات ياخد أقل رينج.
  static SellOption? matchBattery(List<SellOption> options, int value) {
    final ranged = options.where((o) => o.rangeMin != null && o.rangeMax != null).toList()
      ..sort((a, b) => a.rangeMin!.compareTo(b.rangeMin!));
    if (ranged.isEmpty) return null;

    for (final o in ranged) {
      if (value >= o.rangeMin! && value <= o.rangeMax!) return o;
    }
    SellOption? floor;
    for (final o in ranged) {
      if (o.rangeMin! <= value) floor = o;
    }
    return floor ?? ranged.first;
  }

  static SellQuote calculate({
    required double basePrice,
    required List<SellPick> picks,
    required double spreadPercent,
  }) {
    var total = 0.0;
    final lines = <SellAnswerLine>[];

    for (final p in picks) {
      final amount = p.option?.amountFor(basePrice) ?? 0;
      total += amount;
      lines.add(SellAnswerLine(question: p.question.textEn, answer: p.answerText, deduction: amount));
    }

    final estimate = (basePrice - total).clamp(0, double.infinity).toDouble();
    final high = estimate.roundToDouble();
    final low = (estimate * (1 - spreadPercent / 100)).roundToDouble();

    return SellQuote(
      basePrice: basePrice,
      totalDeduction: total,
      estimate: estimate,
      low: low,
      high: high,
      lines: lines,
    );
  }
}
