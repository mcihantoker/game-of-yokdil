import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../theme/app_theme.dart';
import '../../models/game_models.dart';
import '../../widgets/shared_widgets.dart';

class ChestScreen extends StatefulWidget {
  final ChestRewards rewards;
  final VoidCallback onContinue;

  const ChestScreen({super.key, required this.rewards, required this.onContinue});

  @override
  State<ChestScreen> createState() => _ChestScreenState();
}

class _ChestScreenState extends State<ChestScreen> with TickerProviderStateMixin {
  bool _opened = false;
  late AnimationController _chestCtrl;
  late AnimationController _rewardsCtrl;
  late AnimationController _particleCtrl;

  late Animation<double> _chestScale;
  late Animation<double> _chestBounce;
  late List<Animation<double>> _rewardFades;
  late List<Animation<Offset>> _rewardSlides;

  @override
  void initState() {
    super.initState();

    _chestCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 600));
    _rewardsCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 800));
    _particleCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 1200))
      ..repeat();

    _chestScale = TweenSequence([
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 1.3), weight: 40),
      TweenSequenceItem(tween: Tween(begin: 1.3, end: 0.9), weight: 30),
      TweenSequenceItem(tween: Tween(begin: 0.9, end: 1.05), weight: 30),
    ]).animate(CurvedAnimation(parent: _chestCtrl, curve: Curves.easeInOut));

    _chestBounce = Tween<double>(begin: 0, end: -12)
        .animate(CurvedAnimation(parent: _chestCtrl, curve: const Interval(0, 0.4, curve: Curves.easeOut)));

    // Her ödül için ayrı animasyon
    final count = widget.rewards.rewards.length;
    _rewardFades = List.generate(count, (i) => Tween<double>(begin: 0, end: 1).animate(
        CurvedAnimation(
          parent: _rewardsCtrl,
          curve: Interval(i / count, min((i + 1) / count + 0.2, 1), curve: Curves.easeOut),
        )));
    _rewardSlides = List.generate(count, (i) =>
        Tween<Offset>(begin: const Offset(0, 0.3), end: Offset.zero).animate(
          CurvedAnimation(
            parent: _rewardsCtrl,
            curve: Interval(i / count, min((i + 1) / count + 0.2, 1), curve: Curves.easeOut),
          )));
  }

  @override
  void dispose() {
    _chestCtrl.dispose();
    _rewardsCtrl.dispose();
    _particleCtrl.dispose();
    super.dispose();
  }

  void _openChest() {
    HapticFeedback.heavyImpact();
    setState(() => _opened = true);
    _chestCtrl.forward().then((_) {
      _rewardsCtrl.forward();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 24, 20, 24),
          child: Column(
            children: [
              // Başlık
              Text(
                widget.rewards.isGrandChest ? 'BÜYÜK HAZİNE!' : 'HAZİNE!',
                style: AppTextStyles.label(12, color: AppColors.sosyal),
              ),
              const SizedBox(height: 20),

              // Sandık / Confetti alanı
              Expanded(
                flex: 2,
                child: Center(
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      // Parıltı halkası
                      if (_opened)
                        AnimatedBuilder(
                          animation: _particleCtrl,
                          builder: (_, __) => _buildGlowRing(),
                        ),
                      // Sandık
                      AnimatedBuilder(
                        animation: _chestCtrl,
                        builder: (_, __) => Transform.translate(
                          offset: Offset(0, _opened ? _chestBounce.value : 0),
                          child: Transform.scale(
                            scale: _opened ? _chestScale.value : 1.0,
                            child: Text(
                              _opened ? '🎊' : (widget.rewards.isGrandChest ? '🏆' : '📦'),
                              style: const TextStyle(fontSize: 80),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Açılmamışsa buton
              if (!_opened) ...[
                Text(
                  widget.rewards.isGrandChest
                      ? 'Boss yenildi! Büyük hazineni aç.'
                      : 'Hazine keşfedildi! Ne çıkacak?',
                  style: AppTextStyles.body(14, color: AppColors.muted),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                PrimaryButton(
                  label: '🎁  Hazineyi aç!',
                  onTap: _openChest,
                  color: AppColors.sosyal,
                  textColor: AppColors.bg,
                ),
              ],

              // Açılmışsa ödüller
              if (_opened) ...[
                Expanded(
                  flex: 3,
                  child: ListView.separated(
                    itemCount: widget.rewards.rewards.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemBuilder: (ctx, i) {
                      final r = widget.rewards.rewards[i];
                      return FadeTransition(
                        opacity: _rewardFades[i],
                        child: SlideTransition(
                          position: _rewardSlides[i],
                          child: _RewardTile(reward: r),
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 16),
                AnimatedBuilder(
                  animation: _rewardsCtrl,
                  builder: (_, __) => AnimatedOpacity(
                    opacity: _rewardsCtrl.value > 0.8 ? 1.0 : 0.0,
                    duration: const Duration(milliseconds: 300),
                    child: PrimaryButton(
                      label: 'Devam et →',
                      onTap: widget.onContinue,
                      color: AppColors.fen,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildGlowRing() {
    final t = _particleCtrl.value;
    return CustomPaint(
      size: const Size(200, 200),
      painter: _GlowRingPainter(progress: t),
    );
  }
}

// ─── Ödül Satırı ─────────────────────────────────────────────────────────────
class _RewardTile extends StatelessWidget {
  final Reward reward;
  const _RewardTile({required this.reward});

  Color get _valueColor {
    switch (reward.type) {
      case RewardType.xp:      return AppColors.fen;
      case RewardType.gold:    return AppColors.sosyal;
      case RewardType.badge:   return AppColors.saglik;
      case RewardType.unlock:  return AppColors.muted;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: AppColors.bg3,
        borderRadius: AppRadius.mdBR,
        border: Border.all(color: AppColors.border2),
      ),
      child: Row(
        children: [
          Text(reward.emoji, style: const TextStyle(fontSize: 26)),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(reward.title,
                    style: AppTextStyles.display(14, weight: FontWeight.w600)),
                Text(reward.description,
                    style: AppTextStyles.body(12, color: AppColors.muted)),
              ],
            ),
          ),
          Text(reward.value,
              style: AppTextStyles.mono(16, color: _valueColor, weight: FontWeight.w700)),
        ],
      ),
    );
  }
}

// ─── Parıltı Halkası Painter ─────────────────────────────────────────────────
class _GlowRingPainter extends CustomPainter {
  final double progress;
  _GlowRingPainter({required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final rng = Random(42);
    const particleCount = 12;

    for (int i = 0; i < particleCount; i++) {
      final angle = (i / particleCount) * 2 * pi + progress * 2 * pi;
      final r = 70.0 + sin(progress * 2 * pi + i) * 15;
      final x = center.dx + cos(angle) * r;
      final y = center.dy + sin(angle) * r;
      final opacity = (sin(progress * 2 * pi + i * 0.5) + 1) / 2;

      canvas.drawCircle(
        Offset(x, y),
        3 + rng.nextDouble() * 2,
        Paint()..color = AppColors.sosyal.withValues(alpha: opacity * 0.7),
      );
    }
  }

  @override
  bool shouldRepaint(_GlowRingPainter old) => old.progress != progress;
}
