import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../visual/app_assets.dart';
import '../models/models.dart';

// ─── Dept Rengi ──────────────────────────────────────────────────────────────
Color deptColor(Department dept) {
  switch (dept) {
    case Department.fen:    return AppColors.fen;
    case Department.saglik: return AppColors.saglik;
    case Department.sosyal: return AppColors.sosyal;
  }
}

Color deptDimColor(Department dept) {
  switch (dept) {
    case Department.fen:    return AppColors.fenDim;
    case Department.saglik: return AppColors.saglikDim;
    case Department.sosyal: return AppColors.sosyalDim;
  }
}

// ─── Yüzey Kartı ─────────────────────────────────────────────────────────────
class SurfaceCard extends StatelessWidget {
  final Widget child;
  final EdgeInsets? padding;
  final BorderRadius? borderRadius;
  final Color? borderColor;
  final VoidCallback? onTap;

  const SurfaceCard({
    super.key,
    required this.child,
    this.padding,
    this.borderRadius,
    this.borderColor,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final card = Container(
      padding: padding ?? const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.bg3,
        borderRadius: borderRadius ?? AppRadius.lgBR,
        border: Border.all(color: borderColor ?? AppColors.border2),
      ),
      child: child,
    );
    if (onTap == null) return card;
    return GestureDetector(onTap: onTap, child: card);
  }
}

// ─── Birincil Buton ──────────────────────────────────────────────────────────
class PrimaryButton extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  final Color? color;
  final Color? textColor;
  final bool isFullWidth;

  const PrimaryButton({
    super.key,
    required this.label,
    required this.onTap,
    this.color,
    this.textColor,
    this.isFullWidth = true,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: isFullWidth ? double.infinity : null,
      child: ElevatedButton(
        onPressed: onTap,
        style: ElevatedButton.styleFrom(
          backgroundColor: color ?? AppColors.fen,
          foregroundColor: textColor ?? AppColors.bg,
          padding: const EdgeInsets.symmetric(vertical: 15),
          shape: const RoundedRectangleBorder(borderRadius: AppRadius.mdBR),
          elevation: 0,
        ),
        child: Text(label, style: AppTextStyles.display(14, color: textColor ?? AppColors.bg)),
      ),
    );
  }
}

// ─── İkincil (Hayalet) Buton ─────────────────────────────────────────────────
class GhostButton extends StatelessWidget {
  final String label;
  final VoidCallback onTap;

  const GhostButton({super.key, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton(
        onPressed: onTap,
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.text,
          side: const BorderSide(color: AppColors.border2),
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape: const RoundedRectangleBorder(borderRadius: AppRadius.mdBR),
        ),
        child: Text(label, style: AppTextStyles.display(14)),
      ),
    );
  }
}

// ─── Stat Pill (header için) ─────────────────────────────────────────────────
class StatPill extends StatelessWidget {
  final String value;
  final IconData icon;
  final Color iconColor;

  const StatPill({super.key, required this.value, required this.icon, required this.iconColor});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.bg3,
        borderRadius: AppRadius.smBR,
        border: Border.all(color: AppColors.border2),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: iconColor),
          const SizedBox(width: 5),
          Text(value, style: AppTextStyles.mono(13, color: AppColors.text, weight: FontWeight.w600)),
        ],
      ),
    );
  }
}

// ─── Bölüm Rozeti ────────────────────────────────────────────────────────────
class DeptBadge extends StatelessWidget {
  final Department dept;
  final String? label;

  const DeptBadge({super.key, required this.dept, this.label});

  @override
  Widget build(BuildContext context) {
    final color = deptColor(dept);
    final dim   = deptDimColor(dept);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(color: dim, borderRadius: AppRadius.smBR),
      child: Text(
        label ?? dept.shortLabel,
        style: AppTextStyles.mono(11, color: color, weight: FontWeight.w600),
      ),
    );
  }
}

// ─── İlerleme Çubuğu ─────────────────────────────────────────────────────────
class AppProgressBar extends StatelessWidget {
  final double value;
  final Color? color;
  final double height;

  const AppProgressBar({super.key, required this.value, this.color, this.height = 4});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(99),
      child: LinearProgressIndicator(
        value: value,
        backgroundColor: AppColors.border,
        color: color ?? AppColors.fen,
        minHeight: height,
      ),
    );
  }
}

// ─── Sınav Zaman Çizelgesi ────────────────────────────────────────────────────
class ExamTimeline extends StatelessWidget {
  final List<int> examYears;
  final bool highProbability;
  final Color color;

  const ExamTimeline({
    super.key,
    required this.examYears,
    required this.color,
    this.highProbability = false,
  });

  @override
  Widget build(BuildContext context) {
    final years = [...examYears];
    final currentYear = DateTime.now().year;
    final futureYear = years.isEmpty ? currentYear : years.last + 2;
    final showFuture = highProbability || years.isNotEmpty;

    return Row(
      children: [
        Text('SINAVDA', style: AppTextStyles.label(9, color: color)),
        const SizedBox(width: 10),
        Expanded(
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                for (int i = 0; i < years.length; i++) ...[
                  _YearDot(year: years[i], color: color, filled: true),
                  if (i < years.length - 1 || showFuture)
                    _TimelineLine(color: color),
                ],
                if (showFuture) ...[
                  _YearDot(
                    year: futureYear,
                    color: color,
                    filled: false,
                    label: '$futureYear?',
                    labelStyle: AppTextStyles.mono(9, color: color.withValues(alpha: 0.5)),
                  ),
                ] else if (years.isEmpty)
                  Text('Yüksek olasılıklı',
                      style: AppTextStyles.body(10, color: color.withValues(alpha: 0.7))),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _YearDot extends StatelessWidget {
  final int year;
  final Color color;
  final bool filled;
  final String? label;
  final TextStyle? labelStyle;

  const _YearDot({
    required this.year,
    required this.color,
    required this.filled,
    this.label,
    this.labelStyle,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 7, height: 7,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: filled ? color : Colors.transparent,
            border: filled ? null : Border.all(color: color.withValues(alpha: 0.5), width: 1.5),
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label ?? year.toString(),
          style: labelStyle ?? AppTextStyles.mono(9, color: color, weight: FontWeight.w600),
        ),
      ],
    );
  }
}

class _TimelineLine extends StatelessWidget {
  final Color color;
  const _TimelineLine({required this.color});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 11),
      child: Container(width: 14, height: 1.5, color: color.withValues(alpha: 0.3)),
    );
  }
}

// ─── Bölüm Kartı (Ana sayfa listesi) ─────────────────────────────────────────
class DeptListCard extends StatelessWidget {
  final Department dept;
  final int learned;
  final int total;
  final VoidCallback onTap;

  const DeptListCard({
    super.key,
    required this.dept,
    required this.learned,
    required this.total,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = deptColor(dept);
    final dim   = deptDimColor(dept);
    final pct   = total == 0 ? 0.0 : learned / total;

    return SurfaceCard(
      onTap: onTap,
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
      child: Row(
        children: [
          Container(
            width: 42, height: 42,
            decoration: BoxDecoration(color: dim, borderRadius: AppRadius.smBR),
            child: Icon(_deptIcon(dept), color: color, size: 20),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(dept.label, style: AppTextStyles.display(15, weight: FontWeight.w600)),
                const SizedBox(height: 2),
                Text('$learned kelime öğrenildi', style: AppTextStyles.body(12, color: AppColors.muted)),
                const SizedBox(height: 8),
                AppProgressBar(value: pct, color: color, height: 3),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(color: dim, borderRadius: AppRadius.smBR),
            child: Text(
              '${(pct * 100).round()}%',
              style: AppTextStyles.mono(12, color: color, weight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }

  IconData _deptIcon(Department dept) {
    switch (dept) {
      case Department.fen:    return Icons.science_outlined;
      case Department.saglik: return Icons.monitor_heart_outlined;
      case Department.sosyal: return Icons.menu_book_outlined;
    }
  }
}
