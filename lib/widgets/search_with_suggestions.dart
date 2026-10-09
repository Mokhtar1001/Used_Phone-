import 'dart:async';
import 'package:flutter/material.dart';
import '../core/theme.dart';
import '../services/product_service.dart';
import 'search_field.dart';

/// حقل بحث بقايمة اقتراحات بأسماء الموديلات (نص بس، مش منتجات):
/// لما العميل يكتب "ايفون 13" بتنزل قايمة بأسماء الموديلات المطابقة، وباختيار اسم
/// (أو ضغط Enter) بيتفتح [onSelectName] عشان الصفحة تروح لنتايج الاسم ده.
/// الاقتراحات بتيجي من الداتابيز مباشرة.
class SearchWithSuggestions extends StatefulWidget {
  final bool isArabic;
  final String hintText;
  final ValueChanged<String> onSelectName;

  const SearchWithSuggestions({
    super.key,
    required this.isArabic,
    required this.hintText,
    required this.onSelectName,
  });

  @override
  State<SearchWithSuggestions> createState() => _SearchWithSuggestionsState();
}

class _SearchWithSuggestionsState extends State<SearchWithSuggestions> {
  final _controller = TextEditingController();
  final _link = LayerLink();
  final _portal = OverlayPortalController();
  final _tapGroup = Object();
  final _service = ProductService();

  Timer? _debounce;
  int _requestId = 0; // عشان نتجاهل أي رد قديم وصل متأخر
  List<String> _names = [];
  bool _loading = false;
  bool _error = false;
  double _width = 400;

  String _t(String ar, String en) => widget.isArabic ? ar : en;

  @override
  void dispose() {
    _debounce?.cancel();
    _controller.dispose();
    super.dispose();
  }

  void _show() {
    if (!_portal.isShowing) _portal.show();
  }

  void _hide() {
    if (_portal.isShowing) _portal.hide();
  }

  void _onChanged(String text) {
    final q = text.trim();
    _debounce?.cancel();

    if (q.isEmpty) {
      _requestId++; // يلغي أي طلب شغال
      _hide();
      setState(() {
        _names = [];
        _loading = false;
        _error = false;
      });
      return;
    }

    _show();
    setState(() {
      _loading = true;
      _error = false;
    });
    _debounce = Timer(const Duration(milliseconds: 250), () => _fetch(q));
  }

  Future<void> _fetch(String q) async {
    final id = ++_requestId;
    try {
      final list = await _service.searchModelNames(q, isArabic: widget.isArabic);
      if (!mounted || id != _requestId) return;
      setState(() {
        _names = list;
        _loading = false;
      });
    } catch (_) {
      if (!mounted || id != _requestId) return;
      setState(() {
        _loading = false;
        _error = true;
      });
    }
  }

  void _choose(String name) {
    final q = name.trim();
    if (q.isEmpty) return;
    _debounce?.cancel();
    _hide();
    FocusScope.of(context).unfocus();
    widget.onSelectName(q);
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, box) {
      _width = box.maxWidth;
      return OverlayPortal(
        controller: _portal,
        overlayChildBuilder: (context) => CompositedTransformFollower(
          link: _link,
          showWhenUnlinked: false,
          targetAnchor: Alignment.bottomLeft,
          followerAnchor: Alignment.topLeft,
          offset: const Offset(0, 8),
          child: Align(
            alignment: Alignment.topLeft,
            child: TapRegion(
              groupId: _tapGroup,
              child: SizedBox(width: _width, child: _dropdown()),
            ),
          ),
        ),
        child: CompositedTransformTarget(
          link: _link,
          child: TapRegion(
            groupId: _tapGroup,
            onTapOutside: (_) => _hide(),
            child: SearchField(
              controller: _controller,
              hintText: widget.hintText,
              onChanged: _onChanged,
              onSubmitted: _choose,
              // لو قفلنا القايمة بالضغط بره، الضغط على الحقل تاني يفتحها
              onTap: () {
                if (_controller.text.trim().isNotEmpty) _show();
              },
              trailing: _controller.text.isEmpty
                  ? null
                  : IconButton(
                      icon: const Icon(Icons.close, size: 18, color: AppTheme.midGray),
                      onPressed: () {
                        _controller.clear();
                        _onChanged('');
                      },
                    ),
            ),
          ),
        ),
      );
    });
  }

  Widget _dropdown() {
    return Material(
      color: AppTheme.pureWhite,
      elevation: 10,
      shadowColor: Colors.black26,
      borderRadius: BorderRadius.circular(16),
      clipBehavior: Clip.antiAlias,
      child: Container(
        constraints: const BoxConstraints(maxHeight: 420),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppTheme.lightGray),
        ),
        child: _body(),
      ),
    );
  }

  Widget _message({Widget? leading, required String text}) {
    return Padding(
      padding: const EdgeInsets.all(18),
      child: Row(
        children: [
          if (leading != null) ...[leading, const SizedBox(width: 12)],
          Expanded(child: Text(text, style: const TextStyle(color: AppTheme.deepGray, fontSize: 14))),
        ],
      ),
    );
  }

  Widget _body() {
    final q = _controller.text.trim();

    if (_error) {
      return _message(
        leading: const Icon(Icons.error_outline, color: AppTheme.midGray),
        text: _t('حصل خطأ، حاول تاني', 'Something went wrong, try again'),
      );
    }
    if (_loading && _names.isEmpty) {
      return _message(
        leading: const SizedBox(height: 18, width: 18, child: CircularProgressIndicator(strokeWidth: 2)),
        text: _t('جاري البحث...', 'Searching...'),
      );
    }
    if (_names.isEmpty) {
      return _message(
        leading: const Icon(Icons.search_off, color: AppTheme.midGray),
        text: _t('مفيش موديلات مطابقة لـ "$q"', 'No models match "$q"'),
      );
    }

    return Opacity(
      opacity: _loading ? 0.5 : 1, // بنسيب الاقتراحات القديمة لحد ما الجديدة توصل
      child: ListView(
        shrinkWrap: true,
        padding: const EdgeInsets.symmetric(vertical: 6),
        children: [
          for (final name in _names)
            InkWell(
              onTap: () => _choose(name),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
                child: Row(
                  children: [
                    const Icon(Icons.search, size: 18, color: AppTheme.midGray),
                    const SizedBox(width: 12),
                    Expanded(child: _highlight(name, q)),
                    const Icon(Icons.north_west, size: 15, color: AppTheme.lightGray),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  /// بيعمل الجزء المطابق للكلمة Bold
  Widget _highlight(String name, String query) {
    const normal = TextStyle(fontSize: 15, color: AppTheme.charcoal);
    final i = query.isEmpty ? -1 : name.toLowerCase().indexOf(query.toLowerCase());
    if (i < 0) return Text(name, maxLines: 1, overflow: TextOverflow.ellipsis, style: normal);
    return Text.rich(
      TextSpan(
        style: normal,
        children: [
          TextSpan(text: name.substring(0, i)),
          TextSpan(text: name.substring(i, i + query.length), style: const TextStyle(fontWeight: FontWeight.w800)),
          TextSpan(text: name.substring(i + query.length)),
        ],
      ),
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
    );
  }
}