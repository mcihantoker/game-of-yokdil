import 'dart:math';
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

// ═══════════════════════════════════════════════════════════════════════════════
// GÖRSEL EFEKT SİSTEMİ
// Lottie dosyası yokken de çalışan Flutter-native animasyonlar.
// Lottie dosyası eklendiğinde SmartLottie widget ile değiştirilir.
// ═══════════════════════════════════════════════════════════════════════════════

// ─── Ekran Flash Efekti ───────────────────────────────────────────────────────
// Doğru cevap → yeşil flash, Yanlış cevap → kırmızı flash
class ScreenFlashEffect extends StatefulWidget {
  final Widget child;
  final Color? flashColor;
  final bool trigger; // true olduğunda flash tetiklenir

  const ScreenFlashEffect({
    super.key,
    required this.child,
    this.flashColor,
    this.trigger = false,
  });

  @override
  State<ScreenFlashEffect> createState() => _ScreenFlashEffectState();
}

class _ScreenFlashEffectState extends State<ScreenFlashEffect>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _opacity;
  bool _prevTrigger = false;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 300));
    _opacity = Tween<double>(begin: 0.0, end: 0.25)
        .animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOut));
  }

  @override
  void didUpdateWidget(ScreenFlashEffect old) {
    super.didUpdateWidget(old);
    if (widget.trigger && !_prevTrigger) {
      _ctrl.forward(from: 0).then((_) => _ctrl.reverse());
    }
    _prevTrigger = widget.trigger;
  }

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        widget.child,
        IgnorePointer(
          child: AnimatedBuilder(
            animation: _ctrl,
            builder: (_, __) => Opacity(
              opacity: _opacity.value,
              child: Container(
                color: widget.flashColor ?? AppColors.danger,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// ─── Konfeti Patlaması (Doğru Cevap) ─────────────────────────────────────────
class CorrectAnswerBurst extends StatefulWidget {
  final bool trigger;
  final Color color;

  const CorrectAnswerBurst({
    super.key,
    required this.trigger,
    required this.color,
  });

  @override
  State<CorrectAnswerBurst> createState() => _CorrectAnswerBurstState();
}

class _CorrectAnswerBurstState extends State<CorrectAnswerBurst>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  bool _prevTrigger = false;
  final List<_ConfettiParticle> _particles = [];
  final Random _rng = Random();

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 700));
    _ctrl.addStatusListener((s) {
      if (s == AnimationStatus.completed) {
        setState(() => _particles.clear());
      }
    });
    _generateParticles();
  }

  @override
  void didUpdateWidget(CorrectAnswerBurst old) {
    super.didUpdateWidget(old);
    if (widget.trigger && !_prevTrigger) {
      _generateParticles();
      _ctrl.forward(from: 0);
    }
    _prevTrigger = widget.trigger;
  }

  void _generateParticles() {
    _particles.clear();
    for (int i = 0; i < 18; i++) {
      _particles.add(_ConfettiParticle(
        x: 0.3 + _rng.nextDouble() * 0.4,
        angle: -pi / 2 + (_rng.nextDouble() - 0.5) * pi,
        speed: 80 + _rng.nextDouble() * 120,
        size: 4 + _rng.nextDouble() * 5,
        color: [widget.color, AppColors.sosyal, AppColors.text]
            [_rng.nextInt(3)].withOpacity(0.85),
        delay: _rng.nextDouble() * 0.2,
      ));
    }
  }

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    if (_particles.isEmpty) return const SizedBox.shrink();
    return IgnorePointer(
      child: AnimatedBuilder(
        animation: _ctrl,
        builder: (ctx, __) => CustomPaint(
          painter: _ConfettiPainter(_particles, _ctrl.value),
          size: Size.infinite,
        ),
      ),
    );
  }
}

class _ConfettiParticle {
  final double x, angle, speed, size, delay;
  final Color color;
  _ConfettiParticle({
    required this.x, required this.angle, required this.speed,
    required this.size, required this.color, required this.delay,
  });
}

class _ConfettiPainter extends CustomPainter {
  final List<_ConfettiParticle> particles;
  final double t;
  _ConfettiPainter(this.particles, this.t);

  @override
  void paint(Canvas canvas, Size size) {
    for (final p in particles) {
      final progress = ((t - p.delay) / (1 - p.delay)).clamp(0.0, 1.0);
      if (progress <= 0) continue;
      final opacity = (1.0 - progress * 1.2).clamp(0.0, 1.0);
      final dist = p.speed * progress;
      final x = size.width * p.x + cos(p.angle) * dist;
      final y = size.height * 0.6 + sin(p.angle) * dist + progress * 40;
      canvas.drawCircle(
        Offset(x, y),
        p.size * (1 - progress * 0.5),
        Paint()..color = p.color.withOpacity(opacity),
      );
    }
  }

  @override
  bool shouldRepaint(_ConfettiPainter old) => old.t != t;
}

// ─── Combo Ateş Efekti ───────────────────────────────────────────────────────
class ComboFireEffect extends StatefulWidget {
  final int combo;  // 0-5
  final Color color;

  const ComboFireEffect({super.key, required this.combo, required this.color});

  @override
  State<ComboFireEffect> createState() => _ComboFireEffectState();
}

class _ComboFireEffectState extends State<ComboFireEffect>
    with TickerProviderStateMixin {
  late AnimationController _flameCtrl;
  late AnimationController _scaleCtrl;
  late Animation<double> _flame;
  late Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _flameCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 800))
      ..repeat(reverse: true);
    _scaleCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 300));
    _flame = Tween<double>(begin: 0.8, end: 1.0)
        .animate(CurvedAnimation(parent: _flameCtrl, curve: Curves.easeInOut));
    _scale = Tween<double>(begin: 0.8, end: 1.0)
        .animate(CurvedAnimation(parent: _scaleCtrl, curve: Curves.easeOutBack));
  }

  @override
  void didUpdateWidget(ComboFireEffect old) {
    super.didUpdateWidget(old);
    if (widget.combo != old.combo && widget.combo >= 3) {
      _scaleCtrl.forward(from: 0);
    }
  }

  @override
  void dispose() { _flameCtrl.dispose(); _scaleCtrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    if (widget.combo < 3) return const SizedBox(width: 36, height: 36);

    return ScaleTransition(
      scale: _scale,
      child: AnimatedBuilder(
        animation: _flameCtrl,
        builder: (_, __) => CustomPaint(
          size: const Size(36, 36),
          painter: _FlamePainter(_flame.value, widget.combo, widget.color),
        ),
      ),
    );
  }
}

class _FlamePainter extends CustomPainter {
  final double pulse;
  final int combo;
  final Color color;
  _FlamePainter(this.pulse, this.combo, this.color);

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;
    final r = 10.0 + pulse * 4;
    final intensity = ((combo - 3) / 2).clamp(0.0, 1.0);

    // Dış parıltı
    canvas.drawCircle(
      Offset(cx, cy), r * 1.6,
      Paint()..color = color.withOpacity(0.1 + intensity * 0.15)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8),
    );
    // İç kor
    canvas.drawCircle(
      Offset(cx, cy), r,
      Paint()..color = color.withOpacity(0.7 + intensity * 0.2),
    );
    // Merkez beyaz
    canvas.drawCircle(
      Offset(cx, cy), r * 0.4,
      Paint()..color = Colors.white.withOpacity(0.5 + intensity * 0.3),
    );
  }

  @override
  bool shouldRepaint(_FlamePainter old) => old.pulse != pulse || old.combo != combo;
}

// ─── Hücre Açılış Parıltısı ──────────────────────────────────────────────────
// Harita hücresi açılınca çalışır — Lottie yoksa bu kullanılır
class CellUnlockSparkle extends StatefulWidget {
  const CellUnlockSparkle({super.key});

  @override
  State<CellUnlockSparkle> createState() => _CellUnlockSparkleState();
}

class _CellUnlockSparkleState extends State<CellUnlockSparkle>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 500));
    _anim = CurvedAnimation(parent: _ctrl, curve: Curves.easeOut);
    _ctrl.forward();
  }

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _anim,
      builder: (_, __) => Opacity(
        opacity: 1.0 - _anim.value,
        child: CustomPaint(
          size: const Size(32, 32),
          painter: _SparklePainter(_anim.value),
        ),
      ),
    );
  }
}

class _SparklePainter extends CustomPainter {
  final double t;
  _SparklePainter(this.t);

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;
    final paint = Paint()..color = AppColors.fen.withOpacity(0.8 - t * 0.8);

    for (int i = 0; i < 6; i++) {
      final angle = i * pi / 3;
      final dist = 8 + t * 12;
      canvas.drawCircle(
        Offset(cx + cos(angle) * dist, cy + sin(angle) * dist),
        2.5 * (1 - t),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(_SparklePainter old) => old.t != t;
}

// ─── Sandık Açılış Efekti (Lottie yokken) ────────────────────────────────────
class ChestOpenEffect extends StatefulWidget {
  final bool opened;

  const ChestOpenEffect({super.key, required this.opened});

  @override
  State<ChestOpenEffect> createState() => _ChestOpenEffectState();
}

class _ChestOpenEffectState extends State<ChestOpenEffect>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _scale;
  late Animation<double> _glow;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1400))
      ..repeat(reverse: true);
    _scale = Tween<double>(begin: 1.0, end: 1.08)
        .animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut));
    _glow = Tween<double>(begin: 0.4, end: 1.0)
        .animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut));
  }

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    if (!widget.opened) return const SizedBox(width: 80, height: 80);

    return AnimatedBuilder(
      animation: _ctrl,
      builder: (_, __) => Stack(
        alignment: Alignment.center,
        children: [
          // Parıltı halkası
          Container(
            width: 90 * _scale.value,
            height: 90 * _scale.value,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.sosyal.withOpacity(_glow.value * 0.15),
            ),
          ),
          const Text('🎊', style: TextStyle(fontSize: 56)),
        ],
      ),
    );
  }
}

// ─── XP Toast Animasyonu ─────────────────────────────────────────────────────
class XPToastWidget extends StatefulWidget {
  final String text;
  final Color color;
  final bool visible;

  const XPToastWidget({
    super.key,
    required this.text,
    required this.color,
    required this.visible,
  });

  @override
  State<XPToastWidget> createState() => _XPToastWidgetState();
}

class _XPToastWidgetState extends State<XPToastWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _fade;
  late Animation<Offset> _slide;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 600));
    _fade = Tween<double>(begin: 1.0, end: 0.0)
        .animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeIn));
    _slide = Tween<Offset>(begin: Offset.zero, end: const Offset(0, -1))
        .animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeIn));
  }

  @override
  void didUpdateWidget(XPToastWidget old) {
    super.didUpdateWidget(old);
    if (widget.visible && !old.visible) {
      _ctrl.reset();
      Future.delayed(const Duration(milliseconds: 200), () {
        if (mounted) _ctrl.forward();
      });
    }
  }

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    if (!widget.visible) return const SizedBox.shrink();
    return FadeTransition(
      opacity: _fade,
      child: SlideTransition(
        position: _slide,
        child: Text(
          widget.text,
          style: AppTextStyles.mono(
              13, color: widget.color, weight: FontWeight.w700),
        ),
      ),
    );
  }
}

// ─── Rozet Kazanım Kartı ─────────────────────────────────────────────────────
// Yeni rozet kazanıldığında overlay olarak gösterilir
class BadgeEarnedOverlay extends StatefulWidget {
  final String emoji;
  final String title;
  final VoidCallback onDismiss;

  const BadgeEarnedOverlay({
    super.key,
    required this.emoji,
    required this.title,
    required this.onDismiss,
  });

  @override
  State<BadgeEarnedOverlay> createState() => _BadgeEarnedOverlayState();
}

class _BadgeEarnedOverlayState extends State<BadgeEarnedOverlay>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _scale;
  late Animation<double> _fade;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 400));
    _scale = Tween<double>(begin: 0.7, end: 1.0)
        .animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOutBack));
    _fade = CurvedAnimation(parent: _ctrl, curve: Curves.easeOut);
    _ctrl.forward();

    // 2.5 saniye sonra otomatik kapat
    Future.delayed(const Duration(milliseconds: 2500), () {
      if (mounted) _ctrl.reverse().then((_) => widget.onDismiss());
    });
  }

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fade,
      child: ScaleTransition(
        scale: _scale,
        child: GestureDetector(
          onTap: () => _ctrl.reverse().then((_) => widget.onDismiss()),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            decoration: BoxDecoration(
              color: AppColors.bg2,
              borderRadius: AppRadius.lgBR,
              border: Border.all(color: AppColors.sosyal.withOpacity(0.5)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(widget.emoji, style: const TextStyle(fontSize: 28)),
                const SizedBox(width: 12),
                Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Yeni rozet kazandın!',
                        style: AppTextStyles.label(10, color: AppColors.sosyal)),
                    const SizedBox(height: 2),
                    Text(widget.title,
                        style: AppTextStyles.display(14, weight: FontWeight.w600)),
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
