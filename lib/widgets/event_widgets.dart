import 'package:flutter/material.dart';
import '../models/daily_event.dart';
import '../services/event_service.dart';
import '../theme/app_theme.dart';

// ═══════════════════════════════════════════════════════════════════════════════
// GÜNLÜK OLAY KARTI — Ana sayfada gösterilen kompakt kart
// ═══════════════════════════════════════════════════════════════════════════════
class DailyEventCard extends StatelessWidget {
  final DailyEvent event;
  final VoidCallback onTap;

  const DailyEventCard({super.key, required this.event, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final style = DailyEvents.rarityStyle(event.rarity);
    final rarityColor = Color(style.colorHex);
    final isLegendary = event.rarity == 'legendary';

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.fromLTRB(20, 0, 20, 16),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.bg3,
          borderRadius: AppRadius.lgBR,
          border: Border.all(
            color: rarityColor.withOpacity(isLegendary ? 0.7 : 0.35),
            width: isLegendary ? 1.5 : 1,
          ),
        ),
        child: Row(
          children: [
            // Emoji + rarity dot
            Stack(
              clipBehavior: Clip.none,
              children: [
                Container(
                  width: 48, height: 48,
                  decoration: BoxDecoration(
                    color: rarityColor.withOpacity(0.12),
                    borderRadius: AppRadius.smBR,
                  ),
                  alignment: Alignment.center,
                  child: Text(event.emoji, style: const TextStyle(fontSize: 24)),
                ),
                Positioned(
                  top: -4, right: -4,
                  child: Container(
                    width: 10, height: 10,
                    decoration: BoxDecoration(
                      color: rarityColor,
                      shape: BoxShape.circle,
                      border: Border.all(color: AppColors.bg3, width: 1.5),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        'BUGÜNÜN OLAYI',
                        style: AppTextStyles.label(9, color: rarityColor),
                      ),
                      const SizedBox(width: 6),
                      _RarityBadge(rarity: event.rarity, color: rarityColor),
                    ],
                  ),
                  const SizedBox(height: 3),
                  Text(event.title,
                      style: AppTextStyles.display(15, weight: FontWeight.w600)),
                  const SizedBox(height: 2),
                  Text(event.description,
                      style: AppTextStyles.body(12, color: AppColors.muted)),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Icon(Icons.chevron_right_rounded, color: AppColors.dim, size: 20),
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// GÜNLÜK OLAY MODAL — Detaylı açıklama + aktif efekt özeti
// ═══════════════════════════════════════════════════════════════════════════════
class DailyEventModal extends StatefulWidget {
  final DailyEvent event;
  final VoidCallback onDismiss;

  const DailyEventModal({super.key, required this.event, required this.onDismiss});

  @override
  State<DailyEventModal> createState() => _DailyEventModalState();
}

class _DailyEventModalState extends State<DailyEventModal>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _scale;
  late Animation<double> _fade;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 340));
    _scale = Tween<double>(begin: 0.88, end: 1.0).animate(
        CurvedAnimation(parent: _ctrl, curve: Curves.easeOutBack));
    _fade = CurvedAnimation(parent: _ctrl, curve: Curves.easeOut);
    _ctrl.forward();
  }

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  DailyEvent get event => widget.event;

  @override
  Widget build(BuildContext context) {
    final style = DailyEvents.rarityStyle(event.rarity);
    final rarityColor = Color(style.colorHex);

    return FadeTransition(
      opacity: _fade,
      child: Container(
        color: Colors.black54,
        alignment: Alignment.center,
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: ScaleTransition(
          scale: _scale,
          child: Container(
            decoration: BoxDecoration(
              color: AppColors.bg2,
              borderRadius: AppRadius.xlBR,
              border: Border.all(color: rarityColor.withOpacity(0.4), width: 1.5),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Header
                Container(
                  padding: const EdgeInsets.fromLTRB(20, 24, 20, 20),
                  decoration: BoxDecoration(
                    color: rarityColor.withOpacity(0.08),
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
                  ),
                  child: Column(
                    children: [
                      Text(event.emoji, style: const TextStyle(fontSize: 56)),
                      const SizedBox(height: 10),
                      _RarityBadge(rarity: event.rarity, color: rarityColor, large: true),
                      const SizedBox(height: 8),
                      Text(event.title,
                          style: AppTextStyles.display(22, weight: FontWeight.w700),
                          textAlign: TextAlign.center),
                    ],
                  ),
                ),
                // Body
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        event.fullDescription,
                        style: AppTextStyles.body(14, color: AppColors.muted),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 18),
                      _buildEffectSummary(rarityColor),
                      const SizedBox(height: 20),
                      _buildGoldenHourBanner(),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: () async {
                            await EventService.instance.markEventSeen();
                            widget.onDismiss();
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: rarityColor,
                            foregroundColor: AppColors.bg,
                            padding: const EdgeInsets.symmetric(vertical: 15),
                            shape: const RoundedRectangleBorder(
                                borderRadius: AppRadius.mdBR),
                            elevation: 0,
                          ),
                          child: Text('Anladım, savaşa hazırım!',
                              style: AppTextStyles.display(14,
                                  color: AppColors.bg, weight: FontWeight.w600)),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEffectSummary(Color color) {
    final effects = _getActiveEffects();
    if (effects.isEmpty) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: AppRadius.mdBR,
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('BUGÜN AKTİF EFEKTLER',
              style: AppTextStyles.label(10, color: color)),
          const SizedBox(height: 10),
          ...effects.map((e) => Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: Row(
              children: [
                Icon(e.$1, size: 16, color: color),
                const SizedBox(width: 8),
                Expanded(
                    child: Text(e.$2,
                        style: AppTextStyles.body(13, color: AppColors.text))),
              ],
            ),
          )),
        ],
      ),
    );
  }

  List<(IconData, String)> _getActiveEffects() {
    final ef = event.effect;
    final list = <(IconData, String)>[];

    if (ef.hideWordAfterMs) {
      final sn = (ef.wordHideMs / 1000).toStringAsFixed(0);
      list.add((Icons.visibility_off_outlined, 'Kelime $sn saniye sonra kaybolur'));
    }
    if (ef.doubleOrNothing) {
      list.add((Icons.casino_outlined, 'Doğru → XP×2 · Yanlış → 0 XP'));
    }
    if (ef.goldenHourActive) {
      list.add((Icons.access_time_rounded,
          'Saat ${ef.goldenHourStart}:00–${ef.goldenHourEnd}:00 arası ×${ef.xpMultiplier.toInt()} XP'));
    }
    if (ef.timerMultiplier != 1.0 && !ef.goldenHourActive) {
      final pct = (ef.timerMultiplier * 100).toInt();
      list.add((Icons.timer_outlined, 'Süre normal değerin %$pct\'i'));
    }
    if (ef.xpMultiplier != 1.0 && !ef.goldenHourActive && !ef.doubleOrNothing) {
      list.add((Icons.star_outline_rounded, 'Tüm XP ×${ef.xpMultiplier}'));
    }
    if (ef.singleLife) {
      list.add((Icons.favorite_border_rounded, 'Tek can — ilk yanlışta biter'));
    }
    if (ef.noDamageOnWrong) {
      list.add((Icons.shield_outlined, 'Yanlış cevaplar can düşürmez'));
    }
    if (ef.swapAC_BD) {
      list.add((Icons.swap_horiz_rounded, 'A↔C ve B↔D seçenekleri yer değiştirdi'));
    }
    if (ef.comboBonus > 0) {
      list.add((Icons.local_fire_department_outlined,
          'Her doğru cevap comboya +${1 + ef.comboBonus} ekler'));
    }
    if (ef.bonusChestOnFirst) {
      list.add((Icons.card_giftcard_outlined, 'İlk doğru cevabında bonus sandık'));
    }
    return list;
  }

  Widget _buildGoldenHourBanner() {
    if (!event.effect.goldenHourActive) return const SizedBox.shrink();
    final isActive = DailyEvents.isGoldenHourNow(event);
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: isActive
            ? AppColors.sosyal.withOpacity(0.15)
            : AppColors.border.withOpacity(0.3),
        borderRadius: AppRadius.mdBR,
        border: Border.all(
            color: isActive ? AppColors.sosyal.withOpacity(0.5) : AppColors.border),
      ),
      child: Row(
        children: [
          Icon(isActive ? Icons.bolt_rounded : Icons.access_time_rounded,
              color: isActive ? AppColors.sosyal : AppColors.muted, size: 18),
          const SizedBox(width: 8),
          Text(
            isActive ? 'Altın saat şu an aktif!' : 'Altın saat henüz başlamadı',
            style: AppTextStyles.body(13,
                color: isActive ? AppColors.sosyal : AppColors.muted,
                weight: isActive ? FontWeight.w500 : FontWeight.w400),
          ),
        ],
      ),
    );
  }
}

// ─── Rarity Rozeti ───────────────────────────────────────────────────────────
class _RarityBadge extends StatelessWidget {
  final String rarity;
  final Color color;
  final bool large;

  const _RarityBadge({required this.rarity, required this.color, this.large = false});

  @override
  Widget build(BuildContext context) {
    final style = DailyEvents.rarityStyle(rarity);
    return Container(
      padding: EdgeInsets.symmetric(
          horizontal: large ? 12 : 8, vertical: large ? 4 : 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(99),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Text(
        style.label.toUpperCase(),
        style: AppTextStyles.mono(
            large ? 11 : 9, color: color, weight: FontWeight.w600),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// AKTİF OLAY HUD — Quiz/Boss ekranında üstte gösterilen küçük banner
// ═══════════════════════════════════════════════════════════════════════════════
class ActiveEventHUD extends StatelessWidget {
  final DailyEvent event;

  const ActiveEventHUD({super.key, required this.event});

  @override
  Widget build(BuildContext context) {
    final style = DailyEvents.rarityStyle(event.rarity);
    final color = Color(style.colorHex);
    final isGoldenNow = event.effect.goldenHourActive &&
        DailyEvents.isGoldenHourNow(event);
    final xp = EventService.instance.xpMultiplier;

    return Container(
      margin: const EdgeInsets.fromLTRB(20, 0, 20, 10),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: AppRadius.smBR,
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Text(event.emoji, style: const TextStyle(fontSize: 14)),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              event.title,
              style: AppTextStyles.body(12, color: color, weight: FontWeight.w500),
            ),
          ),
          if (xp != 1.0 && (!event.effect.goldenHourActive || isGoldenNow))
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: color.withOpacity(0.2),
                borderRadius: BorderRadius.circular(99),
              ),
              child: Text(
                '×${xp.toStringAsFixed(xp == xp.toInt() ? 0 : 1)} XP',
                style: AppTextStyles.mono(11, color: color, weight: FontWeight.w700),
              ),
            ),
          if (event.effect.goldenHourActive && !isGoldenNow)
            Text(
              '${event.effect.goldenHourStart}:00\'de aktif',
              style: AppTextStyles.mono(10, color: AppColors.muted),
            ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// BONUS SANDIK TOAST — İlk doğru cevapta çıkan bildirim
// ═══════════════════════════════════════════════════════════════════════════════
class BonusChestToast extends StatefulWidget {
  final VoidCallback onClaim;

  const BonusChestToast({super.key, required this.onClaim});

  @override
  State<BonusChestToast> createState() => _BonusChestToastState();
}

class _BonusChestToastState extends State<BonusChestToast>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<Offset> _slide;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 400));
    _slide = Tween<Offset>(begin: const Offset(0, -1), end: Offset.zero)
        .animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOutBack));
    _ctrl.forward();
  }

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return SlideTransition(
      position: _slide,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 20),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: AppColors.sosyal.withOpacity(0.15),
          borderRadius: AppRadius.mdBR,
          border: Border.all(color: AppColors.sosyal.withOpacity(0.5)),
        ),
        child: Row(
          children: [
            const Text('📦', style: TextStyle(fontSize: 20)),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('Bonus sandık kazandın!',
                      style: AppTextStyles.body(13,
                          color: AppColors.sosyal, weight: FontWeight.w500)),
                  Text('İlk doğru cevap ödülü',
                      style: AppTextStyles.body(11, color: AppColors.muted)),
                ],
              ),
            ),
            TextButton(
              onPressed: widget.onClaim,
              style: TextButton.styleFrom(
                foregroundColor: AppColors.sosyal,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              ),
              child: Text('Aç', style: AppTextStyles.display(13, color: AppColors.sosyal)),
            ),
          ],
        ),
      ),
    );
  }
}
