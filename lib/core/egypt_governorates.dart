/// محافظات مصر (الاسم الإنجليزي هو القيمة المخزّنة، والعربي للعرض)
const List<({String en, String ar})> egyptGovernorates = [
  (en: 'Cairo', ar: 'القاهرة'),
  (en: 'Giza', ar: 'الجيزة'),
];

String governorateLabel(String en, bool isArabic) {
  if (!isArabic) return en;
  for (final g in egyptGovernorates) {
    if (g.en == en) return g.ar;
  }
  return en;
}
