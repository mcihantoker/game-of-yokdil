import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../services/premium_service.dart';

Future<bool> showPaywall(BuildContext context, {String reason = ''}) async {
  final result = await showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => PaywallSheet(reason: reason),
  );
  return result ?? false;
}

class PaywallSheet extends StatelessWidget {
  final String reason;
  const PaywallSheet({super.key, this.reason = ''});

  static const _features = [
    ('3 bölüme tam erişim',          Icons.layers_rounded),
    ('Sınırsız günlük quiz',         Icons.all_inclusive_rounded),
    ('Cümle İnşa Modu',             Icons.edit_note_rounded),
    ('Tüm günlük olaylar (12 tür)', Icons.event_rounded),
    ('Gelişmiş istatistik',         Icons.bar_chart_rounded),
    ('Sıralama listesi',            Icons.leaderboard_rounded),
    ('Reklamsız deneyim',           Icons.block_rounded),
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 40),
      decoration: const BoxDecoration(
        color: AppColors.bg2,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 36, height: 4,
              decoration: BoxDecoration(color: AppColors.border2, borderRadius: AppRadius.smBR),
            ),
            const SizedBox(height: 20),
            Container(
              width: 56, height: 56,
              decoration: BoxDecoration(
                color: AppColors.sosyal.withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.workspace_premium_rounded, color: AppColors.sosyal, size: 28),
            ),
            const SizedBox(height: 14),
            Text('Premium\'a Geç', style: AppTextStyles.display(20, weight: FontWeight.w700)),
            const SizedBox(height: 6),
            if (reason.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Text(reason,
                    style: AppTextStyles.body(13, color: AppColors.muted),
                    textAlign: TextAlign.center),
              ),
            const SizedBox(height: 10),
            ..._features.map((e) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(children: [
                Icon(e.$2, color: AppColors.sosyal, size: 16),
                const SizedBox(width: 10),
                Text(e.$1, style: AppTextStyles.body(13)),
              ]),
            )),
            const SizedBox(height: 18),
            _PlanButton(
              label: 'Yıllık  ₺199/yıl',
              badge: 'EN POPÜLER  %43 tasarruf',
              color: AppColors.sosyal,
              onTap: () async {
                await PremiumService.instance.activate();
                if (context.mounted) Navigator.pop(context, true);
              },
            ),
            const SizedBox(height: 8),
            _PlanButton(
              label: 'Aylık  ₺29/ay',
              color: AppColors.fen,
              onTap: () async {
                await PremiumService.instance.activate();
                if (context.mounted) Navigator.pop(context, true);
              },
            ),
            const SizedBox(height: 8),
            _PlanButton(
              label: 'Ömür Boyu  ₺499',
              color: AppColors.saglik,
              onTap: () async {
                await PremiumService.instance.activate();
                if (context.mounted) Navigator.pop(context, true);
              },
            ),
            const SizedBox(height: 10),
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text('Şimdi değil', style: AppTextStyles.body(13, color: AppColors.muted)),
            ),
          ],
        ),
      ),
    );
  }
}

class _PlanButton extends StatelessWidget {
  final String label;
  final String? badge;
  final Color color;
  final VoidCallback onTap;

  const _PlanButton({required this.label, required this.color, required this.onTap, this.badge});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 18),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.12),
          borderRadius: AppRadius.mdBR,
          border: Border.all(color: color.withValues(alpha: 0.5)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: AppTextStyles.display(14, color: color, weight: FontWeight.w600)),
            if (badge != null)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.2),
                  borderRadius: AppRadius.smBR,
                ),
                child: Text(badge!, style: AppTextStyles.label(9, color: color)),
              ),
          ],
        ),
      ),
    );
  }
}
