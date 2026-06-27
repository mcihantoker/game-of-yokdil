import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../theme/app_theme.dart';
import '../../models/models.dart';
import '../../models/game_models.dart';
import '../../widgets/shared_widgets.dart';
import '../../visual/app_assets.dart';
import '../../visual/visual_effects.dart';
import '../../visual/badge_service.dart';

class BossScreen extends StatefulWidget {
  final BossBattle boss;
  final List<Question> questions;
  final Department department;
  final Function(ChestRewards) onVictory;
  final VoidCallback onDefeat;

  const BossScreen({
    super.key,
    required this.boss,
    required this.questions,
    required this.department,
    required this.onVictory,
    required this.onDefeat,
  });

  @override
  State<BossScreen> createState() => _BossScreenState();
}

class _BossScreenState extends State<BossScreen> with TickerProviderStateMixin {
  late BossBattle _boss;
  late List<Question> _questions;
  int _qIndex = 0;
  bool _answered = false;
  int? _selectedIdx;

  // Timer
  late AnimationController _timerCtrl;
  late Timer _ticker;
  int _timeLeft = 15;

  // Boss hasar animasyonu
  late AnimationController _shakeCtrl;
  late Animation<double> _shake;

  // Combo ışık animasyonu
  late AnimationController _comboCtrl;

  @override
  void initState() {
    super.initState();
    _boss = widget.boss;
    _questions = List.from(widget.questions)..shuffle();

    _timerCtrl = AnimationController(
      vsync: this,
      duration: Duration(seconds: widget.boss.timePerQuestion),
    );

    _shakeCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 400));
    _shake = TweenSequence([
      TweenSequenceItem(tween: Tween(begin: 0.0, end: -8.0), weight: 25),
      TweenSequenceItem(tween: Tween(begin: -8.0, end: 8.0), weight: 50),
      TweenSequenceItem(tween: Tween(begin: 8.0, end: 0.0), weight: 25),
    ]).animate(CurvedAnimation(parent: _shakeCtrl, curve: Curves.easeInOut));

    _comboCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 600));

    _startTimer();
  }

  @override
  void dispose() {
    _timerCtrl.dispose();
    _shakeCtrl.dispose();
    _comboCtrl.dispose();
    _ticker.cancel();
    super.dispose();
  }

  Question get _currentQ => _questions[_qIndex % _questions.length];
  Color get _deptColor => deptColor(widget.department);

  void _startTimer() {
    _timeLeft = widget.boss.timePerQuestion;
    _timerCtrl.reset();
    _timerCtrl.forward();

    _ticker = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) { t.cancel(); return; }
      if (_answered) return;
      setState(() { _timeLeft--; });
      if (_timeLeft <= 0) {
        t.cancel();
        _onTimeout();
      }
    });
  }

  void _stopTimer() {
    _ticker.cancel();
    _timerCtrl.stop();
  }

  void _onTimeout() {
    if (_answered) return;
    HapticFeedback.heavyImpact();
    setState(() {
      _answered = true;
      _boss.onWrong();
    });
    _shakeCtrl.forward(from: 0);
    Future.delayed(const Duration(milliseconds: 800), _nextQuestion);
  }

  void _pick(int idx) {
    if (_answered) return;
    _stopTimer();
    HapticFeedback.selectionClick();

    final isCorrect = idx == _currentQ.correctIndex;
    setState(() {
      _answered = true;
      _selectedIdx = idx;
      if (isCorrect) {
        _boss.onCorrect();
        _comboCtrl.forward(from: 0);
      } else {
        _boss.onWrong();
        _shakeCtrl.forward(from: 0);
      }
    });

    if (_boss.isDefeated) {
      Future.delayed(const Duration(milliseconds: 900), () {
        final rewards = ChestRewards.forBossVictory(widget.department, _boss.maxCombo);
        BadgeService.instance.checkAfterBoss(widget.department);
        widget.onVictory(rewards);
      });
    } else {
      Future.delayed(const Duration(milliseconds: 800), _nextQuestion);
    }
  }

  void _nextQuestion() {
    if (!mounted) return;
    if (_boss.isDefeated) return;
    setState(() {
      _qIndex++;
      _answered = false;
      _selectedIdx = null;
    });
    _startTimer();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF100808), // boss ekranı için koyu kırmızımsı zemin
      body: SafeArea(
        child: Column(
          children: [
            _buildBossHeader(),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(16, 10, 16, 20),
                child: Column(
                  children: [
                    _buildComboTimer(),
                    const SizedBox(height: 12),
                    _buildWordCard(),
                    const SizedBox(height: 14),
                    _buildOptions(),
                    if (_answered) ...[
                      const SizedBox(height: 12),
                      _buildFeedback(),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBossHeader() {
    return AnimatedBuilder(
      animation: _shake,
      builder: (ctx, child) => Transform.translate(
        offset: Offset(_shake.value, 0),
        child: Container(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
          decoration: BoxDecoration(
            color: AppColors.bg2,
            border: Border.all(color: AppColors.danger.withOpacity(0.3)),
            borderRadius: const BorderRadius.vertical(bottom: Radius.circular(20)),
          ),
          child: Column(
            children: [
              // Boss isim + emoji
              Row(
                children: [
                  BossCharacterImage(department: widget.department, fallbackEmoji: _boss.bossEmoji, size: 72),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(_boss.bossName,
                            style: AppTextStyles.display(14,
                                color: AppColors.danger, weight: FontWeight.w600)),
                        Text('${_boss.totalHp} doğru cevap ver — canavar yenilsin',
                            style: AppTextStyles.body(11, color: AppColors.muted)),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              // Boss HP barı
              Row(
                children: [
                  Text('CANAVAR CANI',
                      style: AppTextStyles.label(9, color: AppColors.danger)),
                  const Spacer(),
                  Text('${_boss.currentHp} / ${_boss.totalHp}',
                      style: AppTextStyles.mono(11, color: AppColors.danger)),
                ],
              ),
              const SizedBox(height: 5),
              ClipRRect(
                borderRadius: BorderRadius.circular(99),
                child: LinearProgressIndicator(
                  value: _boss.hpPercent,
                  backgroundColor: AppColors.border,
                  color: AppColors.danger,
                  minHeight: 8,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildComboTimer() {
    return Row(
      children: [
        // Combo kutusu
        Expanded(
          child: AnimatedBuilder(
            animation: _comboCtrl,
            builder: (ctx, _) {
              final glow = sin(_comboCtrl.value * pi) * 6;
              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: AppColors.bg3,
                  borderRadius: AppRadius.mdBR,
                  border: Border.all(color: AppColors.border2),
                  boxShadow: glow > 0
                      ? [BoxShadow(color: AppColors.sosyal.withOpacity(0.4), blurRadius: glow)]
                      : null,
                ),
                child: Row(
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('COMBO', style: AppTextStyles.label(9, color: AppColors.muted)),
                        const SizedBox(height: 2),
                        ComboFireEffect(combo: _boss.combo, color: deptColor(widget.department)),
                    Text('×${_boss.comboMultiplier}',
                            style: AppTextStyles.mono(22, color: AppColors.sosyal, weight: FontWeight.w700)),
                      ],
                    ),
                    const Spacer(),
                    // Combo noktaları
                    Row(
                      children: List.generate(5, (i) => Container(
                        width: 9, height: 9,
                        margin: const EdgeInsets.only(left: 4),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: i < _boss.combo
                              ? AppColors.sosyal
                              : AppColors.sosyal.withOpacity(0.15),
                        ),
                      )),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
        const SizedBox(width: 10),
        // Timer ring
        _TimerRing(
          timeLeft: _timeLeft,
          total: widget.boss.timePerQuestion,
          color: _timeLeft <= 5 ? AppColors.danger : _deptColor,
        ),
      ],
    );
  }

  Widget _buildWordCard() {
    final word = _currentQ.word;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: AppColors.bg2,
        borderRadius: AppRadius.xlBR,
        border: Border.all(color: AppColors.border2),
      ),
      child: Column(
        children: [
          Text('TÜRKÇE ANLAMI NEDİR?',
              style: AppTextStyles.label(10, color: AppColors.muted)),
          const SizedBox(height: 14),
          Text(word.word, style: AppTextStyles.display(34, weight: FontWeight.w700)),
          const SizedBox(height: 6),
          Text(word.phonetic, style: AppTextStyles.mono(12, color: AppColors.muted)),
          const SizedBox(height: 14),
          ExamTimeline(
            examYears: word.examYears,
            color: _deptColor,
            highProbability: word.highProbability,
          ),
        ],
      ),
    );
  }

  Widget _buildOptions() {
    final letters = ['A', 'B', 'C', 'D'];
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
        childAspectRatio: 2.8,
      ),
      itemCount: _currentQ.options.length,
      itemBuilder: (ctx, i) => _BossOption(
        letter: letters[i],
        text: _currentQ.options[i],
        state: _optionState(i),
        onTap: () => _pick(i),
      ),
    );
  }

  _OptionState _optionState(int i) {
    if (!_answered) return _OptionState.idle;
    if (i == _currentQ.correctIndex) return _OptionState.correct;
    if (i == _selectedIdx) return _OptionState.wrong;
    return _OptionState.idle;
  }

  Widget _buildFeedback() {
    final isCorrect = _selectedIdx == _currentQ.correctIndex;
    final timeout = _selectedIdx == null;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isCorrect ? AppColors.saglikDim : AppColors.dangerDim,
        borderRadius: AppRadius.mdBR,
        border: Border.all(color: isCorrect ? AppColors.saglik : AppColors.danger),
      ),
      child: Row(
        children: [
          Icon(
            isCorrect ? Icons.check_circle_rounded : Icons.cancel_rounded,
            color: isCorrect ? AppColors.saglik : AppColors.danger,
            size: 18,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              timeout
                  ? 'Süre doldu! −1 boss canı'
                  : isCorrect
                  ? '+1 boss canı · ×${_boss.combo} combo!'
                  : '−1 boss canı · combo sıfırlandı',
              style: AppTextStyles.body(12,
                  color: isCorrect ? AppColors.saglik : AppColors.danger,
                  weight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Timer Ring Widget ────────────────────────────────────────────────────────
class _TimerRing extends StatelessWidget {
  final int timeLeft;
  final int total;
  final Color color;

  const _TimerRing({required this.timeLeft, required this.total, required this.color});

  @override
  Widget build(BuildContext context) {
    const size = 56.0;
    const stroke = 4.0;
    const r = (size / 2) - stroke;
    const circ = 2 * pi * r;
    final offset = circ * (1 - timeLeft / total);

    return SizedBox(
      width: size, height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          CustomPaint(
            size: const Size(size, size),
            painter: _RingPainter(
              progress: timeLeft / total,
              color: color,
              stroke: stroke,
            ),
          ),
          Text(
            timeLeft.toString(),
            style: AppTextStyles.mono(16, color: color, weight: FontWeight.w700),
          ),
        ],
      ),
    );
  }
}

class _RingPainter extends CustomPainter {
  final double progress;
  final Color color;
  final double stroke;

  _RingPainter({required this.progress, required this.color, required this.stroke});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - stroke / 2;

    // Arka iz
    canvas.drawCircle(center, radius,
        Paint()..color = color.withOpacity(0.1)..style = PaintingStyle.stroke..strokeWidth = stroke);

    // İlerleme yayı
    const start = -pi / 2;
    final sweep = 2 * pi * progress;
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      start, sweep, false,
      Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = stroke
        ..strokeCap = StrokeCap.round,
    );
  }

  @override
  bool shouldRepaint(_RingPainter old) => old.progress != progress || old.color != color;
}

// ─── Boss Seçenek ─────────────────────────────────────────────────────────────
enum _OptionState { idle, correct, wrong }

class _BossOption extends StatelessWidget {
  final String letter;
  final String text;
  final _OptionState state;
  final VoidCallback onTap;

  const _BossOption({
    required this.letter, required this.text,
    required this.state, required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    Color bg, border, letterBg, textColor;
    switch (state) {
      case _OptionState.correct:
        bg = AppColors.saglikDim; border = AppColors.saglik;
        letterBg = AppColors.saglik; textColor = AppColors.saglik;
      case _OptionState.wrong:
        bg = AppColors.dangerDim; border = AppColors.danger;
        letterBg = AppColors.danger; textColor = AppColors.danger;
      case _OptionState.idle:
        bg = AppColors.bg3; border = AppColors.border2;
        letterBg = AppColors.bg2; textColor = AppColors.text;
    }

    return GestureDetector(
      onTap: state == _OptionState.idle ? onTap : null,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(color: bg, borderRadius: AppRadius.mdBR,
            border: Border.all(color: border)),
        child: Row(
          children: [
            Container(
              width: 24, height: 24,
              decoration: BoxDecoration(color: letterBg, borderRadius: AppRadius.smBR),
              alignment: Alignment.center,
              child: Text(letter,
                  style: AppTextStyles.display(11,
                      color: state == _OptionState.idle ? AppColors.muted : AppColors.bg,
                      weight: FontWeight.w600)),
            ),
            const SizedBox(width: 7),
            Expanded(
              child: Text(text,
                  style: AppTextStyles.body(12, color: textColor, weight: FontWeight.w500),
                  maxLines: 2, overflow: TextOverflow.ellipsis),
            ),
          ],
        ),
      ),
    );
  }
}
