import 'package:flutter/material.dart';
import '../core/theme.dart';
import '../models/inspection_request.dart';

/// شارة حالة طلب المعاينة (بتستخدم عند العميل وعند الأدمن)
class VisitStatusChip extends StatelessWidget {
  final InspectionRequest request;
  final bool isArabic;
  const VisitStatusChip({super.key, required this.request, required this.isArabic});

  @override
  Widget build(BuildContext context) {
    final (label, color) = _info();
    return _Pill(label: label, color: color);
  }

  (String, Color) _info() {
    if (request.isPending) {
      return (isArabic ? 'مستني التأكيد' : 'Awaiting confirmation', AppTheme.warningColor);
    }
    if (request.isConfirmed) {
      return (isArabic ? 'متأكد' : 'Confirmed', AppTheme.successColor);
    }
    if (request.isCompleted) {
      return (isArabic ? 'تمت المعاينة' : 'Completed', AppTheme.midGray);
    }
    if (request.isNoShow) {
      return (isArabic ? 'ماحضرش' : 'No-show', AppTheme.errorColor);
    }
    return (isArabic ? 'ملغي' : 'Cancelled', AppTheme.midGray);
  }
}

/// شارة صغيرة عامة (مثلًا "التليفون محجوزلك")
class VisitPill extends StatelessWidget {
  final String label;
  final Color color;
  final IconData? icon;
  const VisitPill({super.key, required this.label, required this.color, this.icon});

  @override
  Widget build(BuildContext context) => _Pill(label: label, color: color, icon: icon);
}

class _Pill extends StatelessWidget {
  final String label;
  final Color color;
  final IconData? icon;
  const _Pill({required this.label, required this.color, this.icon});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 13, color: color),
            const SizedBox(width: 4),
          ],
          Text(label, style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}
