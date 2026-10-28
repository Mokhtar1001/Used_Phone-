import 'package:flutter/material.dart';
import '../core/responsive.dart';
import '../core/theme.dart';
import '../screens/customer/about_screen.dart';

/// فوتر الموقع (SHOP / MERCHNT / SUPPORT / VISIT US).
/// مشترك بين الرئيسية وصفحة About. أي لينك له [onTap] بيتحول لزرار؛ الباقي نص عادي لحد ما تربطه.
class SiteFooter extends StatelessWidget {
  /// لو true: ماينفعش تدوس "About us" (بنستخدمها جوه صفحة About نفسها)
  final bool onAboutPage;
  const SiteFooter({super.key, this.onAboutPage = false});

  @override
  Widget build(BuildContext context) {
    final narrow = MediaQuery.sizeOf(context).width < 520;

    // كل عمود: العنوان + الروابط. اربط أي رابط بإضافة onTap.
    final cols = <String, List<_FooterLink>>{
      'SHOP': [const _FooterLink('All phones'), const _FooterLink('iPhone'), const _FooterLink('Samsung')],
      'MERCHNT': [
        _FooterLink(
          'About us',
          onTap: onAboutPage
              ? null
              : () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AboutScreen())),
        ),
        const _FooterLink('Why MERCHNT'),
        const _FooterLink('Sell your phone'),
      ],
      'SUPPORT': [const _FooterLink('Contact us'), const _FooterLink('Delivery & returns')],
      'VISIT US': [const _FooterLink('Store locations'), const _FooterLink('Store hours')],
    };

    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(border: Border(top: BorderSide(color: AppTheme.lightGray))),
      padding: const EdgeInsets.fromLTRB(0, 48, 0, 32),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: Responsive.maxContentWidth),
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: narrow ? 20 : 32),
            child: Column(
              children: [
                Wrap(
                  alignment: WrapAlignment.spaceBetween,
                  spacing: 48,
                  runSpacing: 32,
                  children: [
                    for (final e in cols.entries)
                      SizedBox(
                        width: 180,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              e.key,
                              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppTheme.midGray, letterSpacing: 0.5),
                            ),
                            const SizedBox(height: 14),
                            for (final l in e.value) _FooterLinkTile(link: l),
                          ],
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 32),
                const Divider(height: 1, color: AppTheme.lightGray),
                const SizedBox(height: 24),
                const Wrap(
                  alignment: WrapAlignment.spaceBetween,
                  spacing: 12,
                  runSpacing: 12,
                  children: [
                    Text('© 2026 MERCHNT. All rights reserved.', style: TextStyle(fontSize: 13, color: AppTheme.midGray)),
                    Text(
                      'Trusted pre-owned phones — graded, verified, warrantied.',
                      style: TextStyle(fontSize: 13, color: AppTheme.midGray),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _FooterLink {
  final String label;
  final VoidCallback? onTap;
  const _FooterLink(this.label, {this.onTap});
}

class _FooterLinkTile extends StatefulWidget {
  final _FooterLink link;
  const _FooterLinkTile({required this.link});

  @override
  State<_FooterLinkTile> createState() => _FooterLinkTileState();
}

class _FooterLinkTileState extends State<_FooterLinkTile> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    final link = widget.link;
    final clickable = link.onTap != null;
    final text = Text(
      link.label,
      style: TextStyle(
        fontSize: 14.5,
        color: clickable && _hover ? AppTheme.charcoal : AppTheme.deepGray,
        decoration: clickable && _hover ? TextDecoration.underline : TextDecoration.none,
        decorationColor: AppTheme.gold,
        decorationThickness: 2,
      ),
    );

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: clickable
          ? MouseRegion(
              cursor: SystemMouseCursors.click,
              onEnter: (_) => setState(() => _hover = true),
              onExit: (_) => setState(() => _hover = false),
              child: GestureDetector(behavior: HitTestBehavior.opaque, onTap: link.onTap, child: text),
            )
          : text,
    );
  }
}
