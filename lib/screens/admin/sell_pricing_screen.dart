import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../core/responsive.dart';
import '../../core/theme.dart';
import '../../models/sell_models.dart';
import '../../providers/locale_provider.dart';
import '../../services/sell_service.dart';
import '../customer/sell_model_edit_screen.dart';
import '../customer/sell_question_edit_screen.dart';

/// لوحة "تسعير البيع" - للسوبر أدمن بس:
/// موديلات الأيفون وأسعارها + الأسئلة وخصوماتها + هامش الرينج.
class SellPricingScreen extends StatefulWidget {
  const SellPricingScreen({super.key});

  @override
  State<SellPricingScreen> createState() => _SellPricingScreenState();
}

class _SellPricingScreenState extends State<SellPricingScreen> with SingleTickerProviderStateMixin {
  final _service = SellService();
  final _money = NumberFormat('#,##0');
  late final TabController _tabs = TabController(length: 3, vsync: this);
  final _spreadController = TextEditingController();

  bool _loading = true;
  bool _savingSpread = false;
  List<SellModel> _models = [];
  List<SellQuestion> _questions = [];
  double _spread = 5;
  bool _ar = false;

  String _t(String ar, String en) => sellTr(_ar, ar, en);

  @override
  void initState() {
    super.initState();
    _tabs.addListener(() {
      if (!_tabs.indexIsChanging) setState(() {});
    });
    _load();
  }

  @override
  void dispose() {
    _tabs.dispose();
    _spreadController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final results = await Future.wait([
        _service.getModels(includeInactive: true),
        _service.getQuestions(includeInactive: true),
        _service.getSettings(),
      ]);
      if (!mounted) return;
      setState(() {
        _models = results[0] as List<SellModel>;
        _questions = results[1] as List<SellQuestion>;
        _spread = (results[2] as SellSettings).rangeSpreadPercent;
        _spreadController.text = _spread.toString().replaceAll(RegExp(r'\.0+$'), '');
        _loading = false;
      });
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _snack(String msg) => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));

  Future<bool> _confirm(String text) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        content: Text(text),
        actions: [
          TextButton(onPressed: () => Navigator.pop(c, false), child: Text(_t('إلغاء', 'Cancel'))),
          TextButton(
            onPressed: () => Navigator.pop(c, true),
            child: Text(_t('حذف', 'Delete'), style: const TextStyle(color: AppTheme.errorColor)),
          ),
        ],
      ),
    );
    return ok == true;
  }

  Future<void> _openModel([SellModel? model]) async {
    await Navigator.push(context, MaterialPageRoute(builder: (_) => SellModelEditScreen(model: model)));
    if (mounted) _load();
  }

  Future<void> _openQuestion([SellQuestion? question]) async {
    await Navigator.push(context, MaterialPageRoute(builder: (_) => SellQuestionEditScreen(question: question)));
    if (mounted) _load();
  }

  Future<void> _deleteModel(SellModel m) async {
    if (!await _confirm(_t('حذف "${m.name}"؟', 'Delete "${m.name}"?'))) return;
    try {
      await _service.deleteModel(m.id);
    } catch (_) {
      _snack(_t('حصل خطأ', 'Something went wrong'));
    }
    if (mounted) _load();
  }

  Future<void> _deleteQuestion(SellQuestion q) async {
    if (!await _confirm(_t('حذف السؤال ده؟', 'Delete this question?'))) return;
    try {
      await _service.deleteQuestion(q.id);
    } catch (_) {
      _snack(_t('حصل خطأ', 'Something went wrong'));
    }
    if (mounted) _load();
  }

  Future<void> _move(int index, int delta) async {
    final target = index + delta;
    if (target < 0 || target >= _questions.length) return;
    setState(() {
      final q = _questions.removeAt(index);
      _questions.insert(target, q);
    });
    try {
      await _service.reorderQuestions(_questions.map((e) => e.id).toList());
    } catch (_) {
      _snack(_t('حصل خطأ في الترتيب', 'Could not save the order'));
      if (mounted) _load();
    }
  }

  Future<void> _saveSpread() async {
    final v = double.tryParse(_spreadController.text.trim());
    if (v == null || v < 0 || v > 50) {
      _snack(_t('اكتب نسبة من 0 لـ 50', 'Enter a percentage between 0 and 50'));
      return;
    }
    setState(() => _savingSpread = true);
    try {
      await _service.updateSpread(v);
      if (mounted) setState(() => _spread = v);
      _snack(_t('تم الحفظ', 'Saved'));
    } catch (_) {
      _snack(_t('حصل خطأ', 'Something went wrong'));
    } finally {
      if (mounted) setState(() => _savingSpread = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    _ar = context.watch<LocaleProvider>().isArabic;
    final tab = _tabs.index;

    return Scaffold(
      appBar: AppBar(
        title: Text(_t('تسعير البيع', 'Sell Pricing')),
        bottom: TabBar(
          controller: _tabs,
          tabs: [
            Tab(text: _t('الموديلات', 'Models')),
            Tab(text: _t('الأسئلة', 'Questions')),
            Tab(text: _t('الرينج', 'Price range')),
          ],
        ),
      ),
      floatingActionButton: tab == 0
          ? FloatingActionButton.extended(
              onPressed: () => _openModel(),
              icon: const Icon(Icons.add),
              label: Text(_t('إضافة موديل', 'Add model')),
            )
          : tab == 1
              ? FloatingActionButton.extended(
                  onPressed: () => _openQuestion(),
                  icon: const Icon(Icons.add),
                  label: Text(_t('إضافة سؤال', 'Add question')),
                )
              : null,
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: Responsive.maxContentWidth),
                child: TabBarView(
                  controller: _tabs,
                  children: [_modelsTab(), _questionsTab(), _rangeTab()],
                ),
              ),
            ),
    );
  }

  // ───────────────────────── الموديلات ─────────────────────────

  Widget _modelsTab() {
    if (_models.isEmpty) {
      return Center(child: Text(_t('لسه مفيش موديلات. دوس "إضافة موديل".', 'No models yet. Tap "Add model".')));
    }
    return RefreshIndicator(
      onRefresh: _load,
      child: ListView.separated(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
        itemCount: _models.length,
        separatorBuilder: (_, __) => const SizedBox(height: 10),
        itemBuilder: (context, i) {
          final m = _models[i];
          return Container(
            decoration: BoxDecoration(
              border: Border.all(color: AppTheme.lightGray),
              borderRadius: BorderRadius.circular(14),
            ),
            child: ListTile(
              onTap: () => _openModel(m),
              leading: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  width: 52,
                  height: 52,
                  color: AppTheme.offWhite,
                  child: m.imageUrl == null
                      ? const Icon(Icons.phone_iphone, color: AppTheme.midGray)
                      : CachedNetworkImage(imageUrl: m.imageUrl!, fit: BoxFit.cover),
                ),
              ),
              title: Row(
                children: [
                  Flexible(child: Text(m.name, style: const TextStyle(fontWeight: FontWeight.w600))),
                  if (!m.isActive) ...[
                    const SizedBox(width: 8),
                    Text(_t('(مخفي)', '(hidden)'), style: const TextStyle(color: AppTheme.midGray, fontSize: 12)),
                  ],
                ],
              ),
              subtitle: Text(
                m.storages.isEmpty
                    ? _t('⚠️ مفيش مساحات', '⚠️ No storage options')
                    : m.storages.map((s) => '${s.storage}: ${_money.format(s.basePrice)}').join('  •  '),
                style: const TextStyle(fontSize: 12),
              ),
              trailing: IconButton(
                icon: const Icon(Icons.delete_outline, color: AppTheme.errorColor),
                onPressed: () => _deleteModel(m),
              ),
            ),
          );
        },
      ),
    );
  }

  // ───────────────────────── الأسئلة ─────────────────────────

  String _typeLabel(SellQuestion q) {
    if (q.isBattery) return _t('صحة البطارية (رينجات)', 'Battery health (ranges)');
    if (q.isMulti) return _t('أكتر من اختيار', 'Multiple answers');
    return _t('اختيار واحد', 'Single answer');
  }

  Widget _questionsTab() {
    return RefreshIndicator(
      onRefresh: _load,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
        children: [
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(color: AppTheme.offWhite, borderRadius: BorderRadius.circular(12)),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.info_outline, size: 18, color: AppTheme.gold),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    _t(
                      'الموديل والمساحة (Storage) بيتسألوا للزبون تلقائيًا في أول خطوتين، وسعر كل مساحة بتحدده وانت بتضيف الموديل. الأسئلة اللي تحت بتتسأل بعدهم بنفس الترتيب.',
                      'Model and storage are always asked first. Each storage price is set when you add the model. The questions below are asked after them, in this order.',
                    ),
                    style: const TextStyle(fontSize: 13, height: 1.5, color: AppTheme.deepGray),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          if (_questions.isEmpty)
            Padding(
              padding: const EdgeInsets.all(24),
              child: Center(child: Text(_t('لسه مفيش أسئلة. دوس "إضافة سؤال".', 'No questions yet. Tap "Add question".'))),
            ),
          for (var i = 0; i < _questions.length; i++) ...[
            _questionCard(i),
            const SizedBox(height: 10),
          ],
        ],
      ),
    );
  }

  Widget _questionCard(int i) {
    final q = _questions[i];
    return Container(
      decoration: BoxDecoration(border: Border.all(color: AppTheme.lightGray), borderRadius: BorderRadius.circular(14)),
      child: ListTile(
        onTap: () => _openQuestion(q),
        leading: CircleAvatar(
          backgroundColor: AppTheme.charcoal,
          radius: 15,
          child: Text('${i + 1}', style: const TextStyle(color: AppTheme.pureWhite, fontSize: 12, fontWeight: FontWeight.w700)),
        ),
        title: Text(q.text(_ar), style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Text(
          '${_typeLabel(q)} • ${q.options.length} ${_t('اختيارات', 'options')}${q.isActive ? '' : _t(' • مخفي', ' • hidden')}',
          style: const TextStyle(fontSize: 12),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              tooltip: _t('فوق', 'Move up'),
              icon: const Icon(Icons.arrow_upward, size: 20),
              onPressed: i == 0 ? null : () => _move(i, -1),
            ),
            IconButton(
              tooltip: _t('تحت', 'Move down'),
              icon: const Icon(Icons.arrow_downward, size: 20),
              onPressed: i == _questions.length - 1 ? null : () => _move(i, 1),
            ),
            IconButton(
              icon: const Icon(Icons.delete_outline, color: AppTheme.errorColor, size: 22),
              onPressed: () => _deleteQuestion(q),
            ),
          ],
        ),
      ),
    );
  }

  // ───────────────────────── الرينج ─────────────────────────

  Widget _rangeTab() {
    final typed = double.tryParse(_spreadController.text.trim()) ?? _spread;
    final example = 20000.0;
    final low = (example * (1 - typed / 100)).roundToDouble();

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text(_t('هامش الرينج (%)', 'Price range margin (%)'), style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
        const SizedBox(height: 6),
        Text(
          _t(
            'الزبون بيشوف سعر "من – إلى" بدل رقم واحد. الـ "إلى" هو السعر بعد الخصومات، والـ "من" بينزل عنه بالنسبة دي.',
            'The customer sees a "from – to" price instead of one number. "To" is the price after deductions, and "from" is lower by this percentage.',
          ),
          style: const TextStyle(color: AppTheme.deepGray, height: 1.5),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            SizedBox(
              width: 140,
              child: TextField(
                controller: _spreadController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9.]'))],
                decoration: const InputDecoration(suffixText: '%'),
                onChanged: (_) => setState(() {}),
              ),
            ),
            const SizedBox(width: 12),
            ElevatedButton(
              onPressed: _savingSpread ? null : _saveSpread,
              child: _savingSpread
                  ? const SizedBox(height: 16, width: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : Text(_t('حفظ', 'Save')),
            ),
          ],
        ),
        const SizedBox(height: 20),
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(color: AppTheme.offWhite, borderRadius: BorderRadius.circular(12)),
          child: Text(
            _t(
              'مثال: لو السعر بعد الخصومات ${_money.format(example)} ج.م هيظهر للزبون ${_money.format(low)} – ${_money.format(example)} ج.م',
              'Example: if the price after deductions is EGP ${_money.format(example)}, the customer sees EGP ${_money.format(low)} – ${_money.format(example)}',
            ),
            style: const TextStyle(height: 1.5),
          ),
        ),
      ],
    );
  }
}
