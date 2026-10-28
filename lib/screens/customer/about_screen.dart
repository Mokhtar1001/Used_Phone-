import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../../core/brand_mark.dart';
import '../../core/theme.dart';
import '../../widgets/customer_nav_actions.dart';
import '../../widgets/site_footer.dart';

// لون من ملف الـ HTML مش موجود في AppTheme
const Color _goldLight = Color(0xFFFFF8E7);
const Color _subOnDark = Color(0xFFC9C7C2);

/// صفحة "About us" / Our Story (مبنية على Merchnt_About_Page_Mockup.html).
/// المحتوى إنجليزي زي باقي الأقسام التسويقية في الرئيسية.
class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.sizeOf(context).width;
    final narrow = w < 700;
    final padH = w < 520 ? 20.0 : 32.0;
    final dividerH = narrow ? 48.0 : 84.0;

    return Scaffold(
      backgroundColor: AppTheme.pureWhite,
      appBar: withCustomerNav(context, AppBar(title: const Text('About'))),
      body: SingleChildScrollView(
        child: Column(
          children: [
            _Hero(narrow: narrow, padH: padH),
            _Divider(height: dividerH, background: AppTheme.charcoal, fill: AppTheme.offWhite, shape: _DividerShape.risingRight),
            _Story(narrow: narrow, padH: padH),
            _Divider(height: dividerH, background: AppTheme.offWhite, fill: AppTheme.charcoal, shape: _DividerShape.fallingRight),
            _Mission(narrow: narrow, padH: padH),
            _Divider(height: dividerH, background: AppTheme.charcoal, fill: AppTheme.pureWhite, shape: _DividerShape.risingRight),
            _ForWhom(narrow: narrow, padH: padH),
            _Divider(height: dividerH, background: AppTheme.pureWhite, fill: _goldLight, shape: _DividerShape.curve),
            _Closing(narrow: narrow, padH: padH),
            const SiteFooter(onAboutPage: true),
          ],
        ),
      ),
    );
  }
}

// ───────────────────────── مكونات مشتركة ─────────────────────────

/// يحصر المحتوى في 1200 ويوسّطه (زي .wrap في الـ HTML)
class _Wrap extends StatelessWidget {
  final double padH;
  final Widget child;
  const _Wrap({required this.padH, required this.child});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 1200),
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: padH),
          child: SizedBox(width: double.infinity, child: Align(alignment: AlignmentDirectional.centerStart, child: child)),
        ),
      ),
    );
  }
}

/// سطر صغير دهبي بعلامة الـ tick (WHERE WE STARTED ...)
class _Eyebrow extends StatelessWidget {
  final String text;
  const _Eyebrow(this.text);

  static const _tick =
      '<svg viewBox="0 0 20 20" xmlns="http://www.w3.org/2000/svg"><path d="M3 17 L10 3 L13 9 L17 4" stroke="#C9971F" stroke-width="2.4" fill="none" stroke-linecap="square"/></svg>';

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        SvgPicture.string(_tick, width: 14, height: 14),
        const SizedBox(width: 10),
        Text(
          text,
          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, letterSpacing: 2.5, color: AppTheme.gold),
        ),
      ],
    );
  }
}

enum _DividerShape { risingRight, fallingRight, curve }

/// فواصل مائلة بين الأقسام (نفس polygons الـ HTML، متمطّطة على العرض كله)
class _Divider extends StatelessWidget {
  final double height;
  final Color background;
  final Color fill;
  final _DividerShape shape;
  const _Divider({required this.height, required this.background, required this.fill, required this.shape});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: height,
      color: background,
      child: CustomPaint(painter: _DividerPainter(fill, shape)),
    );
  }
}

class _DividerPainter extends CustomPainter {
  final Color fill;
  final _DividerShape shape;
  _DividerPainter(this.fill, this.shape);

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width, h = size.height;
    // الإحداثيات الأصلية على viewBox 1200×84
    double y(double v) => v / 84 * h;
    final path = Path();
    switch (shape) {
      case _DividerShape.risingRight: // 0,84  1200,18  1200,84
        path
          ..moveTo(0, y(84))
          ..lineTo(w, y(18))
          ..lineTo(w, y(84));
      case _DividerShape.fallingRight: // 0,18  1200,84  0,84
        path
          ..moveTo(0, y(18))
          ..lineTo(w, y(84))
          ..lineTo(0, y(84));
      case _DividerShape.curve: // M0,0 L1200,0 L1200,84 Q600,10 0,84 Z
        path
          ..moveTo(0, 0)
          ..lineTo(w, 0)
          ..lineTo(w, y(84))
          ..quadraticBezierTo(w / 2, y(10), 0, y(84));
    }
    path.close();
    // نمد الشكل شعرة لتحت عشان ماتظهرش خطوط رفيعة بين الأقسام
    canvas.drawPath(path, Paint()..color = fill..isAntiAlias = true);
    canvas.drawRect(Rect.fromLTWH(0, h - 0.5, w, 1), Paint()..color = fill);
  }

  @override
  bool shouldRepaint(_DividerPainter old) => old.fill != fill || old.shape != shape;
}

// ───────────────────────── الأقسام ─────────────────────────

class _Hero extends StatelessWidget {
  final bool narrow;
  final double padH;
  const _Hero({required this.narrow, required this.padH});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      color: AppTheme.charcoal,
      child: ClipRect(
        child: Stack(
          children: [
            // دايرة خفيفة + علامة المارك كـ watermark
            Positioned(
              top: -420,
              right: -300,
              child: Container(
                width: 900,
                height: 900,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
                ),
              ),
            ),
            Positioned(
              right: -40,
              bottom: -120,
              child: Opacity(
                opacity: 0.055,
                child: const MerchntMark(size: 460, main: Colors.white, accent: Colors.white),
              ),
            ),
            Padding(
              padding: EdgeInsets.symmetric(vertical: narrow ? 64 : 110),
              child: _Wrap(
                padH: padH,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 800),
                      child: Text(
                        "We started with a simple belief: a great phone shouldn't require blind faith in a stranger.",
                        style: TextStyle(
                          fontSize: narrow ? 36 : 56,
                          fontWeight: FontWeight.w900,
                          height: 1.14,
                          letterSpacing: -1,
                          color: AppTheme.pureWhite,
                        ),
                      ),
                    ),
                    const SizedBox(height: 26),
                    ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 540),
                      child: const Text(
                        'That belief still shapes everything we do — from how we grade a phone to how we talk about it.',
                        style: TextStyle(fontSize: 19, height: 1.6, color: _subOnDark),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Story extends StatelessWidget {
  final bool narrow;
  final double padH;
  const _Story({required this.narrow, required this.padH});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      color: AppTheme.offWhite,
      padding: EdgeInsets.symmetric(vertical: narrow ? 64 : 100),
      child: _Wrap(
        padH: padH,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const _Eyebrow('WHERE WE STARTED'),
            const SizedBox(height: 22),
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 840),
              child: Text(
                'Before there was a website, there were counters. Real conversations with real people about what “good condition” actually means — the kind of trust you build slowly, one transaction at a time. That’s the only kind we know how to build, so it’s the same trust we brought online.',
                style: TextStyle(fontSize: narrow ? 22 : 28, fontWeight: FontWeight.w700, height: 1.55, letterSpacing: -0.3),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Mission extends StatelessWidget {
  final bool narrow;
  final double padH;
  const _Mission({required this.narrow, required this.padH});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      color: AppTheme.charcoal,
      padding: EdgeInsets.symmetric(vertical: narrow ? 72 : 120, horizontal: padH),
      child: Column(
        children: [
          const MerchntMark(size: 50, main: Colors.white, accent: AppTheme.gold),
          const SizedBox(height: 34),
          const Text(
            'OUR MISSION',
            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, letterSpacing: 2.5, color: AppTheme.gold),
          ),
          const SizedBox(height: 26),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 660),
            child: Text(
              'A good phone, honestly priced, backed by someone who’ll stand behind it. That’s the whole idea.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: narrow ? 24 : 32,
                fontWeight: FontWeight.w700,
                height: 1.5,
                letterSpacing: -0.3,
                color: AppTheme.pureWhite,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ForWhom extends StatelessWidget {
  final bool narrow;
  final double padH;
  const _ForWhom({required this.narrow, required this.padH});

  @override
  Widget build(BuildContext context) {
    final text = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'For anyone who’s done the math and knows a flagship phone doesn’t need a flagship price — as long as somebody’s willing to prove it, condition and all.',
          style: TextStyle(fontSize: narrow ? 19 : 23, fontWeight: FontWeight.w600, height: 1.6, letterSpacing: -0.2),
        ),
        const SizedBox(height: 22),
        ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 560),
          child: const Text(
            'Some of you we’ve already met in person, phone in hand, asking exactly the right questions. This is that same conversation — just easier to have from wherever you are.',
            style: TextStyle(fontSize: 16, height: 1.7, color: AppTheme.deepGray),
          ),
        ),
      ],
    );

    return Container(
      width: double.infinity,
      color: AppTheme.pureWhite,
      padding: EdgeInsets.symmetric(vertical: narrow ? 64 : 100),
      child: _Wrap(
        padH: padH,
        child: narrow
            ? Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [const _Eyebrow('WHO THIS IS FOR'), const SizedBox(height: 22), text],
              )
            : Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(width: 240, child: _Eyebrow('WHO THIS IS FOR')),
                  const SizedBox(width: 70),
                  Expanded(child: text),
                ],
              ),
      ),
    );
  }
}

class _Closing extends StatelessWidget {
  final bool narrow;
  final double padH;
  const _Closing({required this.narrow, required this.padH});

  @override
  Widget build(BuildContext context) {
    final browse = ElevatedButton(
      onPressed: () => Navigator.of(context).popUntil((route) => route.isFirst),
      style: ElevatedButton.styleFrom(
        backgroundColor: AppTheme.charcoal,
        foregroundColor: AppTheme.pureWhite,
        elevation: 0,
        minimumSize: const Size(0, 52),
        padding: const EdgeInsets.symmetric(horizontal: 34),
        shape: const StadiumBorder(),
        textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
      ),
      child: const Text('Browse phones'),
    );

    // لسه مفيش صفحة فروع: بنعرّف المستخدم بدل ما الزرار يبقى ميت
    final findStore = OutlinedButton(
      onPressed: () => ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(const SnackBar(content: Text('Store locations are coming soon'))),
      style: OutlinedButton.styleFrom(
        backgroundColor: AppTheme.pureWhite,
        foregroundColor: AppTheme.charcoal,
        minimumSize: const Size(0, 52),
        padding: const EdgeInsets.symmetric(horizontal: 34),
        side: const BorderSide(color: AppTheme.charcoal, width: 2),
        shape: const StadiumBorder(),
        textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
      ),
      child: const Text('Find a store'),
    );

    return Container(
      width: double.infinity,
      color: _goldLight,
      padding: EdgeInsets.symmetric(vertical: narrow ? 64 : 100, horizontal: padH),
      child: Column(
        children: [
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 680),
            child: Text(
              'Come see us in person, or start browsing tonight. Either way, every phone has already proven itself to us — before it has to prove anything to you.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: narrow ? 24 : 32, fontWeight: FontWeight.w800, height: 1.4),
            ),
          ),
          const SizedBox(height: 36),
          narrow
              ? Column(children: [SizedBox(width: double.infinity, child: browse), const SizedBox(height: 12), SizedBox(width: double.infinity, child: findStore)])
              : Row(mainAxisSize: MainAxisSize.min, children: [browse, const SizedBox(width: 16), findStore]),
        ],
      ),
    );
  }
}
