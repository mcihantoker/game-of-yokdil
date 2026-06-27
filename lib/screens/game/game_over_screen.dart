import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../theme/app_theme.dart';
import '../../models/models.dart';
import '../../widgets/shared_widgets.dart';
import '../../visual/app_assets.dart';
import '../../visual/visual_effects.dart';

class GameOverScreen extends StatefulWidget {
  final int correctAnswers;
  final int maxCombo;
  final Word? failedWord;       // son yanıtlanamayan kelime
  final Department department;
  final VoidCallback onReplay;
  final VoidCallback onHome;

  const GameOverScreen({
    super.key,
    required this.correctAnswers,
    required this.maxCombo,
    required this.department,
    this.failedWord,
    required this.onReplay,
    required this.onHome,
  });

  @override
  State<GameOverScreen> createState() => _GameOverScreenState();
}

class _GameOverScreenState extends State<GameOverScreen>
    with TickerProviderStateMixin {

  late AnimationController _fadeCtrl;
  late AnimationController _skullCtrl;
  late AnimationController _particleCtrl;
  late AnimationController _statsCtrl;

  late Animation<double> _fadeIn;
  late Animation<double> _skullScale;
  late Animation<double> _skullGlow;
  late Animation<Offset> _titleSlide;
  late Animation<double> _titleFade;
  late Animation<double> _statsFade;

  final List<_Particle> _particles = [];
  final Random _rng = Random();

  static const _bgColor   = Color(0xFF08080F);
  static const _darkRed   = Color(0xFF8B1A1A);
  static const _midRed    = Color(0xFFC0392B);
  static const _dimRed    = Color(0xFF4A2020);
  static const _surfaceBg = Color(0xFF0F0F1A);
  static const _border    = Color(0xFF1E1E2E);
  static const _mutedText = Color(0xFF4A3A3A);
  static const _dimText   = Color(0xFF8B6565);

  @override
  void initState() {
    super.initState();
    HapticFeedback.heavyImpact();

    _fadeCtrl   = AnimationController(vsync: this, duration: const Duration(milliseconds: 800));
    _skullCtrl  = AnimationController(vsync: this, duration: const Duration(milliseconds: 2400))..repeat(reverse: true);
    _particleCtrl = AnimationController(vsync: this, duration: const Duration(seconds: 5))..repeat();
    _statsCtrl  = AnimationController(vsync: this, duration: const Duration(milliseconds: 600));

    _fadeIn      = CurvedAnimation(parent: _fadeCtrl, curve: Curves.easeOut);
    _skullScale  = Tween<double>(begin: 0.93, end: 1.03).animate(
        CurvedAnimation(parent: _skullCtrl, curve: Curves.easeInOut));
    _skullGlow   = Tween<double>(begin: 0.3, end: 0.9).animate(
        CurvedAnimation(parent: _skullCtrl, curve: Curves.easeInOut));
    _titleSlide  = Tween<Offset>(begin: const Offset(0, 0.2), end: Offset.zero).animate(
        CurvedAnimation(parent: _fadeCtrl, curve: const Interval(.2, .8, curve: Curves.easeOut)));
    _titleFade   = CurvedAnimation(parent: _fadeCtrl, curve: const Interval(.15, .75));
    _statsFade   = CurvedAnimation(parent: _statsCtrl, curve: Curves.easeOut);

    // Partiküller
    for (int i = 0; i < 20; i++) {
      _particles.add(_Particle(
        x: _rng.nextDouble(),
        startY: _rng.nextDouble() * 0.6,
        size: 2 + _rng.nextDouble() * 3,
        speed: 0.04 + _rng.nextDouble() * 0.06,
        delay: _rng.nextDouble(),
        color: _rng.nextBool() ? _darkRed : _dimRed,
      ));
    }

    _fadeCtrl.forward().then((_) => _statsCtrl.forward());
  }

  @override
  void dispose() {
    _fadeCtrl.dispose();
    _skullCtrl.dispose();
    _particleCtrl.dispose();
    _statsCtrl.dispose();
    super.dispose();
  }

  TextStyle _cinzel(double size, {Color? color, FontWeight weight = FontWeight.w700}) =>
      GoogleFonts.cinzel(fontSize: size, fontWeight: weight, color: color ?? Colors.white,
          letterSpacing: 0.04 * size);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bgColor,
      body: DefeatSceneBackground(
        child: Stack(
        children: [
          // Arka plan partikülleri
          AnimatedBuilder(
            animation: _particleCtrl,
            builder: (_, __) => CustomPaint(
              painter: _ParticlePainter(_particles, _particleCtrl.value),
              size: MediaQuery.of(context).size,
            ),
          ),
          // Çatlak çizgiler
          CustomPaint(
            painter: _CrackPainter(_rng),
            size: MediaQuery.of(context).size,
          ),
          // Vignet
          Container(
            decoration: BoxDecoration(
              gradient: RadialGradient(
                center: Alignment.center,
                radius: 1.2,
                colors: [Colors.transparent, _bgColor.withOpacity(0.85)],
              ),
            ),
          ),
          // Ana içerik
          SafeArea(
            child: FadeTransition(
              opacity: _fadeIn,
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(24, 32, 24, 32),
                child: Column(
                  children: [
                    _buildSkull(),
                    const SizedBox(height: 20),
                    _buildBrokenSword(),
                    const SizedBox(height: 12),
                    _buildTitle(),
                    _buildDivider(),
                    const SizedBox(height: 12),
                    _buildStats(),
                    const SizedBox(height: 12),
                    if (widget.failedWord != null) _buildFailedWord(),
                    const SizedBox(height: 20),
                    _buildButtons(),
                    const SizedBox(height: 20),
                    _buildQuote(),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    ));
  }

  Widget _buildSkull() {
    return AnimatedBuilder(
      animation: _skullCtrl,
      builder: (_, __) => Transform.scale(
        scale: _skullScale.value,
        child: SizedBox(
          width: 120, height: 120,
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Dış halka parıltısı
              Container(
                width: 136, height: 136,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: _darkRed.withOpacity(_skullGlow.value * 0.6),
                    width: 1.5,
                  ),
                ),
              ),
              Container(
                width: 150, height: 150,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: _darkRed.withOpacity(_skullGlow.value * 0.2),
                    width: 0.5,
                  ),
                ),
              ),
              // Kuru kafa SVG yerine shape-based çizim
              CustomPaint(
                size: const Size(100, 100),
                painter: _SkullPainter(_skullGlow.value),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBrokenSword() {
    return CustomPaint(
      size: const Size(160, 24),
      painter: _BrokenSwordPainter(),
    );
  }

  Widget _buildTitle() {
    return SlideTransition(
      position: _titleSlide,
      child: FadeTransition(
        opacity: _titleFade,
        child: Column(
          children: [
            Text('Yenildin', style: _cinzel(32, color: _midRed)),
            const SizedBox(height: 4),
            Text(
              'KRALLIĞIN DÜŞTÜ',
              style: _cinzel(12, color: _mutedText, weight: FontWeight.w600),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDivider() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Row(
        children: [
          Expanded(child: Container(height: 0.5,
              decoration: BoxDecoration(
                gradient: LinearGradient(colors: [Colors.transparent, _darkRed]),
              ))),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Container(width: 5, height: 5,
                decoration: const BoxDecoration(color: _darkRed, shape: BoxShape.circle)),
          ),
          Expanded(child: Container(height: 0.5,
              decoration: BoxDecoration(
                gradient: LinearGradient(colors: [_darkRed, Colors.transparent]),
              ))),
        ],
      ),
    );
  }

  Widget _buildStats() {
    return FadeTransition(
      opacity: _statsFade,
      child: Row(
        children: [
          _StatCard(value: '0',                       label: 'Kalan can',       dimRed: _dimRed, mutedText: _mutedText, surfaceBg: _surfaceBg, border: _border, midRed: _midRed),
          const SizedBox(width: 10),
          _StatCard(value: '${widget.correctAnswers}', label: 'Doğru cevap',    dimRed: _dimRed, mutedText: _mutedText, surfaceBg: _surfaceBg, border: _border, midRed: _midRed),
          const SizedBox(width: 10),
          _StatCard(value: '×${widget.maxCombo}',      label: 'En yüksek combo', dimRed: _dimRed, mutedText: _mutedText, surfaceBg: _surfaceBg, border: _border, midRed: _midRed),
        ],
      ),
    );
  }

  Widget _buildFailedWord() {
    final word = widget.failedWord!;
    return FadeTransition(
      opacity: _statsFade,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: _surfaceBg,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: _border),
        ),
        child: Column(
          children: [
            Text('YANIT VEREMEDİĞİN KELİME',
                style: AppTextStyles.label(9, color: _mutedText)),
            const SizedBox(height: 8),
            Text(word.word, style: _cinzel(20, color: _dimText)),
            Text(word.trMeaning,
                style: AppTextStyles.body(12, color: _mutedText)),
            const SizedBox(height: 8),
            Text(
              '"${word.exampleSentence}"',
              style: AppTextStyles.body(11, color: const Color(0xFF3A2A2A))
                  .copyWith(fontStyle: FontStyle.italic),
              textAlign: TextAlign.center,
            ),
            if (word.examYears.isNotEmpty) ...[
              const SizedBox(height: 6),
              ExamTimeline(examYears: word.examYears, color: _darkRed,
                  highProbability: word.highProbability),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildButtons() {
    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: widget.onReplay,
            style: ElevatedButton.styleFrom(
              backgroundColor: _darkRed,
              foregroundColor: const Color(0xFFF5C6C6),
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              elevation: 0,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.refresh_rounded, size: 18),
                const SizedBox(width: 8),
                Text('Tekrar oyna', style: _cinzel(14, color: const Color(0xFFF5C6C6))),
              ],
            ),
          ),
        ),
        const SizedBox(height: 10),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton(
            onPressed: widget.onHome,
            style: OutlinedButton.styleFrom(
              foregroundColor: _mutedText,
              side: const BorderSide(color: _border),
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.castle_outlined, size: 16, color: _mutedText),
                const SizedBox(width: 8),
                Text("Kal'aya dön", style: _cinzel(13, color: _mutedText)),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildQuote() {
    return Text(
      '"Düşen savaşçı kalkar — ama önce kelimeyi öğrenir."',
      style: GoogleFonts.cinzel(
          fontSize: 11, color: const Color(0xFF2A1E1E),
          fontStyle: FontStyle.italic, height: 1.6),
      textAlign: TextAlign.center,
    );
  }
}

// ─── Stat Kartı ──────────────────────────────────────────────────────────────
class _StatCard extends StatelessWidget {
  final String value;
  final String label;
  final Color dimRed, mutedText, surfaceBg, border, midRed;
  const _StatCard({required this.value, required this.label,
      required this.dimRed, required this.mutedText,
      required this.surfaceBg, required this.border, required this.midRed});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: surfaceBg,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: border),
        ),
        child: Column(
          children: [
            Text(value, style: GoogleFonts.cinzel(
                fontSize: 20, fontWeight: FontWeight.w700, color: midRed)),
            const SizedBox(height: 3),
            Text(label, style: AppTextStyles.body(9, color: mutedText),
                textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
}

// ─── Kuru Kafa Painter ────────────────────────────────────────────────────────
class _SkullPainter extends CustomPainter {
  final double glow;
  _SkullPainter(this.glow);

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2 - 4;
    final Paint fill = Paint()..color = const Color(0xFF0D0D16);
    final Paint stroke = Paint()..color = const Color(0xFF2A1A1A)..style = PaintingStyle.stroke..strokeWidth = 1.5;
    final Paint eyePaint = Paint()..color = Color.lerp(const Color(0xFF8B0000), const Color(0xFFC0392B), glow)!;

    // Kafa
    canvas.drawOval(Rect.fromCenter(center: Offset(cx, cy), width: 70, height: 65), fill);
    canvas.drawOval(Rect.fromCenter(center: Offset(cx, cy), width: 70, height: 65), stroke);

    // Göz yuvaları
    canvas.drawOval(Rect.fromCenter(center: Offset(cx - 16, cy - 5), width: 20, height: 24),
        Paint()..color = const Color(0xFF1A0A0A));
    canvas.drawOval(Rect.fromCenter(center: Offset(cx + 16, cy - 5), width: 20, height: 24),
        Paint()..color = const Color(0xFF1A0A0A));

    // Parlayan gözler
    canvas.drawCircle(Offset(cx - 16, cy - 5), 6, eyePaint..color = eyePaint.color.withOpacity(glow * 0.9));
    canvas.drawCircle(Offset(cx + 16, cy - 5), 6, eyePaint..color = eyePaint.color.withOpacity(glow * 0.9));
    canvas.drawCircle(Offset(cx - 16, cy - 5), 2.5, eyePaint..color = const Color(0xFFE74C3C));
    canvas.drawCircle(Offset(cx + 16, cy - 5), 2.5, eyePaint..color = const Color(0xFFE74C3C));

    // Burun
    canvas.drawOval(Rect.fromCenter(center: Offset(cx, cy + 8), width: 10, height: 8),
        Paint()..color = const Color(0xFF0A0A10));

    // Dişler
    final toothPaint = Paint()..color = const Color(0xFF0D0D16);
    final toothStroke = Paint()..color = const Color(0xFF2A1A1A)..style = PaintingStyle.stroke..strokeWidth = 0.8;
    for (int i = 0; i < 4; i++) {
      final tx = cx - 15 + i * 10.0;
      final rect = Rect.fromLTWH(tx, cy + 20, 8, 10);
      canvas.drawRRect(RRect.fromRectAndRadius(rect, const Radius.circular(2)), toothPaint);
      canvas.drawRRect(RRect.fromRectAndRadius(rect, const Radius.circular(2)), toothStroke);
    }

    // Ağız çizgisi
    final mouthPath = Path()
      ..moveTo(cx - 22, cy + 20)
      ..quadraticBezierTo(cx, cy + 24, cx + 22, cy + 20);
    canvas.drawPath(mouthPath, stroke..strokeWidth = 1);
  }

  @override
  bool shouldRepaint(_SkullPainter old) => old.glow != glow;
}

// ─── Kırık Kılıç Painter ─────────────────────────────────────────────────────
class _BrokenSwordPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final blade = Paint()..color = const Color(0xFF2A2A3A)..strokeWidth = 3..strokeCap = StrokeCap.round..style = PaintingStyle.stroke;
    final shine = Paint()..color = const Color(0xFF3A3A4E)..strokeWidth = 1..strokeCap = StrokeCap.round..style = PaintingStyle.stroke;
    final crack = Paint()..color = const Color(0xFF8B1A1A)..strokeWidth = 1.5;
    final hilt  = Paint()..color = const Color(0xFF1A1A28);

    // Sol parça (saptan kırık noktaya)
    canvas.drawLine(const Offset(10, 20), const Offset(65, 10), blade);
    canvas.drawLine(const Offset(10, 20), const Offset(65, 8), shine);
    // Sap
    final hiltRect = RRect.fromLTRBR(3, 18, 20, 24, const Radius.circular(2));
    canvas.drawRRect(hiltRect, hilt..style = PaintingStyle.fill);
    canvas.drawRRect(hiltRect, blade..strokeWidth = 1);
    // Sağ parça (kırık noktadan uca)
    canvas.drawLine(const Offset(72, 18), const Offset(150, 6), blade);
    canvas.drawLine(const Offset(72, 16), const Offset(150, 4), shine);
    // Topuz
    canvas.drawCircle(const Offset(150, 6), 5, hilt..style = PaintingStyle.fill);
    canvas.drawCircle(const Offset(150, 6), 5, blade..strokeWidth = 1);
    // Kırık nokta parıltısı
    canvas.drawLine(const Offset(65, 10), const Offset(72, 17), crack);
    canvas.drawCircle(const Offset(68, 13), 3, Paint()..color = const Color(0xFF8B1A1A)..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2));
  }

  @override
  bool shouldRepaint(_) => false;
}

// ─── Çatlak Çizgiler Painter ──────────────────────────────────────────────────
class _CrackPainter extends CustomPainter {
  final Random rng;
  late final List<Offset> _starts;
  late final List<Offset> _ends;

  _CrackPainter(this.rng) {
    _starts = List.generate(8, (_) => Offset(rng.nextDouble(), rng.nextDouble()));
    _ends = List.generate(8, (i) {
      final angle = rng.nextDouble() * 2 * pi;
      final len = 0.03 + rng.nextDouble() * 0.08;
      return Offset(_starts[i].dx + cos(angle) * len, _starts[i].dy + sin(angle) * len);
    });
  }

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = const Color(0xFF8B1A1A).withOpacity(0.15)..strokeWidth = 0.5;
    for (int i = 0; i < _starts.length; i++) {
      canvas.drawLine(
        Offset(_starts[i].dx * size.width, _starts[i].dy * size.height),
        Offset(_ends[i].dx * size.width, _ends[i].dy * size.height),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(_) => false;
}

// ─── Partikül Painter ─────────────────────────────────────────────────────────
class _Particle {
  final double x, startY, size, speed, delay;
  final Color color;
  const _Particle({required this.x, required this.startY, required this.size,
      required this.speed, required this.delay, required this.color});
}

class _ParticlePainter extends CustomPainter {
  final List<_Particle> particles;
  final double t;
  _ParticlePainter(this.particles, this.t);

  @override
  void paint(Canvas canvas, Size size) {
    for (final p in particles) {
      final progress = ((t - p.delay + 1) % 1);
      if (progress < 0.1 || progress > 0.9) continue;
      final opacity = sin(progress * pi).clamp(0.0, 0.7);
      final y = (p.startY - progress * 0.4) * size.height;
      canvas.drawCircle(
        Offset(p.x * size.width, y),
        p.size,
        Paint()..color = p.color.withOpacity(opacity),
      );
    }
  }

  @override
  bool shouldRepaint(_ParticlePainter old) => old.t != t;
}
