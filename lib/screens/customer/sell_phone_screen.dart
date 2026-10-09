import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../core/responsive.dart';
import '../../core/theme.dart';
import '../../models/sell_models.dart';
import '../../providers/auth_provider.dart';
import '../../providers/locale_provider.dart';
import '../../services/sell_price_calculator.dart';
import '../../services/sell_service.dart';
import '../../widgets/customer_nav_actions.dart';
import '../../widgets/desktop_top_nav.dart';
import '../../widgets/guest_guard.dart';

/// رحلة "بيع موبايلك" (iPhone فقط):
/// اختيار الموديل ← المساحة ← الأسئلة (بالترتيب اللي حدده السوبر أدمن) ← السعر التقديري (من–إلى)
/// ← إرسال طلب بيع (محتاج تسجيل دخول). مشاهدة السعر نفسها مفتوحة للزوار.
class SellPhoneScreen extends StatefulWidget {
  const SellPhoneScreen({super.key});

  @override
  State<SellPhoneScreen> createState() => _SellPhoneScreenState();
}

class _SellPhoneScreenState extends State<SellPhoneScreen> {
  final _service = SellService();
  final _money = NumberFormat('#,##0');

  bool _loading = true;
  bool _error = false;
  List<SellModel> _models = [];
  List<SellQuestion> _questions = [];
  SellSettings _settings = const SellSettings();

  // الخطوات: 0 موديل | 1 مساحة | 2..(1+عدد الأسئلة) أسئلة | بعدها النتيجة
  int _step = 0;
  SellModel? _model;
  SellStorage? _storage;
  final Map<String, Set<String>> _picked = {}; // questionId -> optionIds
  final Map<String, int> _battery = {}; // questionId -> صحة البطارية %

  bool _submitting = false;
  bool _submitted = false;
  bool _ar = false;

  String _t(String ar, String en) => sellTr(_ar, ar, en);

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = false;
    });
    try {
      final results = await Future.wait([
        _service.getModels(),
        _service.getQuestions(),
        _service.getSettings(),
      ]);
      if (!mounted) return;
      setState(() {
        // الموديل لازم يكون له مساحة واحدة على الأقل، والسؤال لازم له اختيارات
        _models = (results[0] as List<SellModel>).where((m) => m.storages.isNotEmpty).toList();
        _questions = (results[1] as List<SellQuestion>).where((q) => q.options.isNotEmpty).toList();
        _settings = results[2] as SellSettings;
        _loading = false;
      });
    } catch (_) {
      if (mounted) {
        setState(() {
          _loading = false;
          _error = true;
        });
      }
    }
  }

  int get _resultStep => 2 + _questions.length;
  bool get _isResult => _step >= _resultStep;

  bool _canNext() {
    if (_step == 0) return _model != null;
    if (_step == 1) return _storage != null;
    final q = _questions[_step - 2];
    if (q.isMulti) return true; // ولا اختيار = ولا مشكلة
    if (q.isBattery) {
      final v = _battery[q.id];
      return v != null && v >= 1 && v <= 100;
    }
    return (_picked[q.id] ?? {}).isNotEmpty;
  }

  void _next() {
    if (_canNext()) setState(() => _step++);
  }

  void _back() {
    if (_step > 0) setState(() => _step--);
  }

  void _restart() {
    setState(() {
      _step = 0;
      _model = null;
      _storage = null;
      _picked.clear();
      _battery.clear();
      _submitted = false;
    });
  }

  List<SellPick> _buildPicks() {
    final picks = <SellPick>[];
    for (final q in _questions) {
      if (q.isBattery) {
        final v = _battery[q.id];
        if (v == null) continue;
        picks.add(SellPick(question: q, option: SellPriceCalculator.matchBattery(q.options, v), answerText: '$v%'));
      } else {
        final chosen = q.options.where((o) => (_picked[q.id] ?? {}).contains(o.id)).toList();
        if (chosen.isEmpty) {
          picks.add(SellPick(question: q, option: null, answerText: 'None'));
        } else {
          for (final o in chosen) {
            picks.add(SellPick(question: q, option: o, answerText: o.labelEn));
          }
        }
      }
    }
    return picks;
  }

  Future<void> _submit(SellQuote quote) async {
    final ok = await requireLogin(
      context,
      messageAr: 'سجّل دخولك عشان نقدر نتواصل معاك بخصوص طلب البيع',
      messageEn: 'Sign in so we can contact you about your sell request',
    );
    if (!ok || !mounted) return;

    final profile = context.read<AuthProvider>().profile;
    if (profile == null || _model == null || _storage == null) return;

    setState(() => _submitting = true);
    try {
      await _service.createRequest(
        customerId: profile.id,
        model: _model!,
        storage: _storage!,
        lines: quote.lines,
        low: quote.low,
        high: quote.high,
      );
      if (mounted) setState(() => _submitted = true);
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(_t('حصل خطأ، حاول تاني', 'Something went wrong, please try again'))),
        );
      }
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    _ar = context.watch<LocaleProvider>().isArabic;

    // نفس الجزء العلوي بتاع الهوم بيج على الديسكتوب/الويب (لوجو + إشعارات + مفضلة + بروفايل)
    final PreferredSizeWidget appBar = Responsive.isDesktop(context)
        ? DesktopTopNav(
            selectedIndex: 0,
            onDestinationSelected: (_) {},
            items: const [],
            trailing: const CustomerNavActions(),
          )
        : AppBar(title: Text(_t('بيع موبايلك', 'Sell your phone')));

    return Scaffold(
      appBar: appBar,
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error
              ? _centerMessage(
                  icon: Icons.error_outline,
                  text: _t('حصل خطأ، حاول تاني', 'Something went wrong'),
                  action: ElevatedButton(onPressed: _load, child: Text(_t('حاول تاني', 'Retry'))),
                )
              : _models.isEmpty
                  ? _centerMessage(
                      icon: Icons.phone_iphone,
                      text: _t('الخدمة مش متاحة دلوقتي', 'This service is not available right now'),
                    )
                  : _submitted
                      ? _successView()
                      : _wizard(),
    );
  }

  Widget _centerMessage({required IconData icon, required String text, Widget? action}) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 44, color: AppTheme.midGray),
            const SizedBox(height: 12),
            Text(text, textAlign: TextAlign.center, style: const TextStyle(fontSize: 16)),
            if (action != null) ...[const SizedBox(height: 16), action],
          ],
        ),
      ),
    );
  }

  /// ويب/ديسكتوب (من 900px): كارت الخطوات + لوحة ملخص جنبه. غير كده: الشكل الضيق (موبايل/تطبيق).
  bool get _wide => MediaQuery.sizeOf(context).width >= 900;

  Widget _wizard() => _wide ? _wideWizard() : _narrowWizard();

  Widget _narrowWizard() {
    final total = _resultStep;
    final progress = _isResult ? 1.0 : _step / total;

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 760),
        child: Column(
          children: [
            LinearProgressIndicator(
              value: progress,
              minHeight: 4,
              backgroundColor: AppTheme.lightGray,
              color: AppTheme.gold,
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 28, 20, 20),
                child: _isResult ? _resultView() : _stepView(),
              ),
            ),
            if (!_isResult) _bottomBar(),
          ],
        ),
      ),
    );
  }

  Widget _navRow({required bool expand}) {
    final isLastQuestion = _step == _resultStep - 1;
    final next = ElevatedButton(
      onPressed: _canNext() ? _next : null,
      child: Text(isLastQuestion ? _t('اعرف سعر موبايلك', 'See my price') : _t('التالي', 'Next')),
    );
    return Row(
      mainAxisAlignment: expand ? MainAxisAlignment.start : MainAxisAlignment.end,
      children: [
        if (_step > 0) ...[
          OutlinedButton(onPressed: _back, child: Text(_t('رجوع', 'Back'))),
          const SizedBox(width: 12),
        ],
        if (expand) Expanded(child: next) else next,
      ],
    );
  }

  Widget _bottomBar() {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
      decoration: const BoxDecoration(border: Border(top: BorderSide(color: AppTheme.lightGray))),
      child: SafeArea(top: false, child: _navRow(expand: true)),
    );
  }

  // ───────────────────────── تخطيط الويب ─────────────────────────

  Widget _wideWizard() {
    return SingleChildScrollView(
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1120),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(32, 28, 32, 64),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (Responsive.isDesktop(context)) ...[
                  TextButton.icon(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.arrow_back, size: 18),
                    label: Text(_t('رجوع للرئيسية', 'Back to home')),
                  ),
                  const SizedBox(height: 8),
                ],
                Padding(
                  padding: const EdgeInsets.only(bottom: 24),
                  child: Text(_t('بيع موبايلك', 'Sell your phone'),
                      style: const TextStyle(fontSize: 32, fontWeight: FontWeight.w800, letterSpacing: -0.4)),
                ),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(child: _stepCard()),
                    const SizedBox(width: 32),
                    SizedBox(width: 340, child: _summaryPanel()),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _stepCard() {
    final total = _resultStep;
    return Container(
      width: double.infinity,
      constraints: const BoxConstraints(minHeight: 480),
      padding: const EdgeInsets.all(40),
      decoration: BoxDecoration(
        color: AppTheme.pureWhite,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.lightGray),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!_isResult) ...[
            Text(
              _t('خطوة ${_step + 1} من $total', 'Step ${_step + 1} of $total'),
              style: const TextStyle(color: AppTheme.midGray, fontWeight: FontWeight.w600, fontSize: 13),
            ),
            const SizedBox(height: 10),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: _step / total,
                minHeight: 4,
                backgroundColor: AppTheme.lightGray,
                color: AppTheme.gold,
              ),
            ),
            const SizedBox(height: 32),
          ],
          _isResult ? _resultView() : _stepView(),
          if (!_isResult) ...[
            const SizedBox(height: 36),
            const Divider(color: AppTheme.lightGray),
            const SizedBox(height: 16),
            _navRow(expand: false),
          ],
        ],
      ),
    );
  }

  /// لوحة جانبية: موبايلك (صورة + اسم + مساحة) وتقدّمك في الخطوات
  Widget _summaryPanel() {
    final model = _model;
    final labels = [
      _t('الموديل', 'Model'),
      _t('المساحة', 'Storage'),
      ..._questions.map((q) => q.text(_ar)),
    ];

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppTheme.offWhite,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.lightGray),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(_t('موبايلك', 'Your phone'), style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
          const SizedBox(height: 16),
          Container(
            height: 210,
            width: double.infinity,
            decoration: BoxDecoration(color: AppTheme.pureWhite, borderRadius: BorderRadius.circular(14)),
            child: model?.imageUrl != null
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(14),
                    child: CachedNetworkImage(
                      imageUrl: model!.imageUrl!,
                      fit: BoxFit.contain,
                      errorWidget: (_, __, ___) => const Icon(Icons.phone_iphone, size: 64, color: AppTheme.lightGray),
                    ),
                  )
                : const Icon(Icons.phone_iphone, size: 64, color: AppTheme.lightGray),
          ),
          const SizedBox(height: 16),
          Text(
            model?.name ?? _t('لسه ما اخترتش موديل', 'No model selected yet'),
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: model == null ? AppTheme.midGray : AppTheme.charcoal),
          ),
          if (_storage != null) ...[
            const SizedBox(height: 2),
            Text(_storage!.storage, style: const TextStyle(color: AppTheme.deepGray)),
          ],
          const SizedBox(height: 20),
          const Divider(color: AppTheme.lightGray, height: 1),
          const SizedBox(height: 14),
          for (var i = 0; i < labels.length; i++)
            _SummaryStep(
              label: labels[i],
              state: (_isResult || i < _step) ? _StepState.done : (i == _step ? _StepState.current : _StepState.todo),
            ),
        ],
      ),
    );
  }

  // ───────────────────────── الخطوات ─────────────────────────

  Widget _stepView() {
    if (_step == 0) return _modelStep();
    if (_step == 1) return _storageStep();
    return _questionStep(_questions[_step - 2]);
  }

  Widget _title(String text, {String? subtitle}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(text, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w800, height: 1.25)),
          if (subtitle != null) ...[
            const SizedBox(height: 6),
            Text(subtitle, style: const TextStyle(color: AppTheme.deepGray, height: 1.5)),
          ],
        ],
      ),
    );
  }

  Widget _modelStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _title(_t('إيه موديل الأيفون بتاعك؟', 'Which iPhone do you have?')),
        Wrap(
          spacing: 14,
          runSpacing: 14,
          children: [
            for (final m in _models)
              _ModelTile(
                model: m,
                large: _wide,
                selected: _model?.id == m.id,
                onTap: () => setState(() {
                  if (_model?.id != m.id) _storage = null; // لو غيّر الموديل، المساحة تتصفّر
                  _model = m;
                }),
              ),
          ],
        ),
      ],
    );
  }

  Widget _storageStep() {
    final model = _model!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _title(_t('إيه مساحة التخزين؟', 'What is the storage size?'), subtitle: model.name),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            for (final s in model.storages)
              _OptionTile(
                label: s.storage,
                selected: _storage?.id == s.id,
                multi: false,
                onTap: () => setState(() => _storage = s),
              ),
          ],
        ),
      ],
    );
  }

  Widget _questionStep(SellQuestion q) {
    if (q.isBattery) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _title(
            q.text(_ar),
            subtitle: 'Settings → Battery → Battery Health & Charging',
          ),
          SizedBox(
            width: 220,
            child: TextFormField(
              key: ValueKey('battery-${q.id}'),
              initialValue: _battery[q.id]?.toString() ?? '',
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(3)],
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w700),
              decoration: InputDecoration(
                suffixText: '%',
                hintText: _t('مثال: 92', 'e.g. 92'),
              ),
              onChanged: (v) => setState(() {
                final n = int.tryParse(v);
                if (n == null) {
                  _battery.remove(q.id);
                } else {
                  _battery[q.id] = n;
                }
              }),
            ),
          ),
          if (_battery[q.id] != null && (_battery[q.id]! < 1 || _battery[q.id]! > 100))
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(_t('اكتب رقم من 1 لـ 100', 'Enter a number from 1 to 100'),
                  style: const TextStyle(color: AppTheme.errorColor, fontSize: 13)),
            ),
        ],
      );
    }

    final selected = _picked[q.id] ?? <String>{};
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _title(q.text(_ar), subtitle: q.isMulti ? _t('اختار كل اللي ينطبق (أو سيبها فاضية)', 'Select all that apply (or leave empty)') : null),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            for (final o in q.options)
              _OptionTile(
                label: o.label(_ar),
                selected: selected.contains(o.id),
                multi: q.isMulti,
                onTap: () => setState(() {
                  final set = {...selected};
                  if (q.isMulti) {
                    set.contains(o.id) ? set.remove(o.id) : set.add(o.id);
                  } else {
                    set
                      ..clear()
                      ..add(o.id);
                  }
                  _picked[q.id] = set;
                }),
              ),
          ],
        ),
      ],
    );
  }

  // ───────────────────────── النتيجة ─────────────────────────

  Widget _resultView() {
    final picks = _buildPicks();
    final quote = SellPriceCalculator.calculate(
      basePrice: _storage!.basePrice,
      picks: picks,
      spreadPercent: _settings.rangeSpreadPercent,
    );
    final egp = _t('ج.م', 'EGP');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _title(_t('السعر التقديري لموبايلك', 'Your estimated price')),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(28),
          decoration: BoxDecoration(color: AppTheme.charcoal, borderRadius: BorderRadius.circular(16)),
          child: Column(
            children: [
              Text('${_model!.name} · ${_storage!.storage}',
                  style: const TextStyle(color: Color(0xFFD6D3CD), fontSize: 14)),
              const SizedBox(height: 12),
              Text(
                quote.low == quote.high
                    ? '$egp ${_money.format(quote.high)}'
                    : '$egp ${_money.format(quote.low)} – ${_money.format(quote.high)}',
                textAlign: TextAlign.center,
                style: TextStyle(color: AppTheme.pureWhite, fontSize: _wide ? 40 : 30, fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 12),
              Text(
                _t('السعر النهائي بيتأكد بعد فحص الجهاز.', 'Final price is confirmed after inspecting the device.'),
                textAlign: TextAlign.center,
                style: const TextStyle(color: Color(0xFFD6D3CD), fontSize: 13, height: 1.5),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        Text(_t('إجاباتك', 'Your answers'), style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
        const SizedBox(height: 10),
        Container(
          decoration: BoxDecoration(
            color: AppTheme.offWhite,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppTheme.lightGray),
          ),
          child: Column(
            children: [
              for (var i = 0; i < picks.length; i++) ...[
                if (i > 0) const Divider(height: 1, color: AppTheme.lightGray),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(flex: 5, child: Text(picks[i].question.text(_ar), style: const TextStyle(color: AppTheme.deepGray))),
                      const SizedBox(width: 12),
                      Expanded(
                        flex: 4,
                        child: Text(
                          picks[i].question.isBattery
                              ? picks[i].answerText
                              : (picks[i].option?.label(_ar) ?? _t('ولا حاجة', 'None')),
                          textAlign: TextAlign.end,
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 24),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: _submitting ? null : () => _submit(quote),
            child: _submitting
                ? const SizedBox(height: 18, width: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                : Text(_t('ابعت طلب بيع', 'Send sell request')),
          ),
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TextButton(onPressed: _back, child: Text(_t('تعديل الإجابات', 'Edit answers'))),
            TextButton(onPressed: _restart, child: Text(_t('ابدأ من الأول', 'Start over'))),
          ],
        ),
      ],
    );
  }

  Widget _successView() {
    return _centerMessage(
      icon: Icons.check_circle_outline,
      text: _t('تم إرسال طلبك! هنتواصل معاك على رقمك المسجل.', "Request sent! We'll contact you on your registered phone number."),
      action: ElevatedButton(onPressed: () => Navigator.pop(context), child: Text(_t('تمام', 'Done'))),
    );
  }
}

// ───────────────────────── ودجتس مساعدة ─────────────────────────

class _ModelTile extends StatelessWidget {
  final SellModel model;
  final bool selected;
  final bool large;
  final VoidCallback onTap;
  const _ModelTile({required this.model, required this.selected, required this.onTap, this.large = false});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: onTap,
      child: Container(
        width: large ? 190 : 150,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppTheme.pureWhite,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: selected ? AppTheme.charcoal : AppTheme.lightGray, width: selected ? 2 : 1),
        ),
        child: Column(
          children: [
            Container(
              height: large ? 160 : 120,
              width: double.infinity,
              decoration: BoxDecoration(color: AppTheme.offWhite, borderRadius: BorderRadius.circular(10)),
              child: model.imageUrl == null
                  ? const Icon(Icons.phone_iphone, size: 46, color: AppTheme.lightGray)
                  : ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: CachedNetworkImage(
                        imageUrl: model.imageUrl!,
                        fit: BoxFit.contain,
                        errorWidget: (_, __, ___) => const Icon(Icons.phone_iphone, size: 46, color: AppTheme.lightGray),
                      ),
                    ),
            ),
            const SizedBox(height: 10),
            Text(model.name, textAlign: TextAlign.center, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
          ],
        ),
      ),
    );
  }
}

class _OptionTile extends StatelessWidget {
  final String label;
  final bool selected;
  final bool multi;
  final VoidCallback onTap;
  const _OptionTile({required this.label, required this.selected, required this.multi, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: onTap,
      child: Container(
        constraints: const BoxConstraints(minWidth: 140),
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
        decoration: BoxDecoration(
          color: selected ? AppTheme.charcoal : AppTheme.pureWhite,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: selected ? AppTheme.charcoal : AppTheme.lightGray, width: 1.5),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (multi) ...[
              Icon(selected ? Icons.check_box : Icons.check_box_outline_blank,
                  size: 20, color: selected ? AppTheme.pureWhite : AppTheme.midGray),
              const SizedBox(width: 8),
            ],
            Flexible(
              child: Text(
                label,
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: selected ? AppTheme.pureWhite : AppTheme.charcoal,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

enum _StepState { done, current, todo }

class _SummaryStep extends StatelessWidget {
  final String label;
  final _StepState state;
  const _SummaryStep({required this.label, required this.state});

  @override
  Widget build(BuildContext context) {
    final IconData icon;
    final Color color;
    switch (state) {
      case _StepState.done:
        icon = Icons.check_circle;
        color = AppTheme.successColor;
        break;
      case _StepState.current:
        icon = Icons.radio_button_checked;
        color = AppTheme.charcoal;
        break;
      case _StepState.todo:
        icon = Icons.radio_button_unchecked;
        color = AppTheme.lightGray;
        break;
    }
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Icon(icon, size: 18, color: color),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 14,
                fontWeight: state == _StepState.current ? FontWeight.w700 : FontWeight.w500,
                color: state == _StepState.todo ? AppTheme.midGray : AppTheme.charcoal,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
