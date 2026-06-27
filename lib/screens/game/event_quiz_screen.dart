import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../theme/app_theme.dart';
import '../../models/models.dart';
import '../../models/daily_event.dart';
import '../../models/game_models.dart';
import '../../services/event_service.dart';
import '../../widgets/shared_widgets.dart';
import '../../widgets/event_widgets.dart';

// ─── Seçenek durumu ──────────────────────────────────────────────────────────
enum OptionState { idle, correct, wrong }

// ═══════════════════════════════════════════════════════════════════════════════
// EVENT-AWARE QUIZ SCREEN
// ═══════════════════════════════════════════════════════════════════════════════
class EventQuizScreen extends StatefulWidget {
  final List<Question> questions;
  final Department department;
  final String theme;
  final Function(SessionResult) onComplete;
  final Function(Word?) onDefeat;   // can bitti, kaybettin
  final VoidCallback onBack;
  final Function(ChestRewards) onBonusChest; // bonus sandık kazanıldı

  const EventQuizScreen({
    super.key,
    required this.questions,
    required this.department,
    required this.theme,
    required this.onComplete,
    required this.onDefeat,
    required this.onBack,
    required this.onBonusChest,
  });

  @override
  State<EventQuizScreen> createState() => _EventQuizScreenState();
}

class _EventQuizScreenState extends State<EventQuizScreen>
    with TickerProviderStateMixin {

  // ─── Quiz state ────────────────────────────────────────────────────────────
  int _currentIndex = 0;
  int _correctCount = 0;
  int _lives = 3;
  int _combo = 0;
  int _totalXP = 0;
  bool _answered = false;
  int? _selectedIdx;
  Word? _lastFailedWord;
  bool _firstCorrectGiven = false;
  bool _bonusChestShown = false;
  final List<Word> _learnedWords = [];
  late List<List<String>> _orderedOptions; // event'e göre düzenlenmiş seçenekler
  late List<int> _displayCorrectIndices;   // görüntüleme indexleri

  // ─── Olay state ───────────────────────────────────────────────────────────
  late DailyEvent _event;
  late EventService _svc;
  bool _wordVisible = true;
  Timer? _hideTimer;
  Timer? _ticker;

  // ─── Timer (boss değil, quiz için basit) ──────────────────────────────────
  // Quiz ekranında süre yok, sadece boss'ta var. Ama Şimşek Turu olayı
  // süreyi etkileyebilir diye hook bırakıldı.

  // ─── Animasyonlar ─────────────────────────────────────────────────────────
  late AnimationController _cardCtrl;
  late AnimationController _xpCtrl;
  late Animation<double> _cardScale;
  late Animation<double> _xpFade;
  String _xpToast = '';

  // ─── Sis efekti (word blur) ───────────────────────────────────────────────
  late AnimationController _fogCtrl;
  late Animation<double> _fogOpacity;

  @override
  void initState() {
    super.initState();
    _svc   = EventService.instance;
    _event = _svc.todaysEvent;
    _lives = _svc.startingLives(3);

    _cardCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 180));
    _cardScale = Tween<double>(begin: 1.0, end: 0.96)
        .animate(CurvedAnimation(parent: _cardCtrl, curve: Curves.easeInOut));

    _xpCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 800));
    _xpFade = CurvedAnimation(parent: _xpCtrl, curve: Curves.easeOut);

    _fogCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 600));
    _fogOpacity = Tween<double>(begin: 1.0, end: 0.0)
        .animate(CurvedAnimation(parent: _fogCtrl, curve: Curves.easeIn));

    _buildOptionOrders();
    _startWordHideTimer();
  }

  @override
  void dispose() {
    _cardCtrl.dispose();
    _xpCtrl.dispose();
    _fogCtrl.dispose();
    _hideTimer?.cancel();
    _ticker?.cancel();
    super.dispose();
  }

  // ─── Seçenekleri olay kuralına göre düzenle ───────────────────────────────
  void _buildOptionOrders() {
    _orderedOptions = widget.questions.map((q) {
      return List<String>.from(_svc.applyOptionOrder(q.options));
    }).toList();

    _displayCorrectIndices = widget.questions.asMap().entries.map((e) {
      return _svc.mapCorrectIndex(e.value.correctIndex, e.value.options.length);
    }).toList();
  }

  // ─── Kelime gizleme zamanlayıcısı (Sis / Kelime Flaşı) ───────────────────
  void _startWordHideTimer() {
    _hideTimer?.cancel();
    _wordVisible = true;
    _fogCtrl.reset();

    if (_event.effect.hideWordAfterMs) {
      _hideTimer = Timer(Duration(milliseconds: _event.effect.wordHideMs), () {
        if (!mounted || _answered) return;
        _fogCtrl.forward();
        setState(() => _wordVisible = false);
      });
    }
  }

  // ─── Mevcut soru ─────────────────────────────────────────────────────────
  Question get _current => widget.questions[_currentIndex];
  List<String> get _currentOptions => _orderedOptions[_currentIndex];
  int get _currentCorrectIdx => _displayCorrectIndices[_currentIndex];

  Color get _deptColor => deptColor(widget.department);

  // ─── Cevap seçimi ────────────────────────────────────────────────────────
  void _pick(int displayIdx) {
    if (_answered) return;
    _hideTimer?.cancel();

    final isCorrect = displayIdx == _currentCorrectIdx;
    HapticFeedback.selectionClick();

    // XP hesapla
    final baseXP = 20;
    final earnedXP = isCorrect
        ? _svc.calculateXP(baseXP: baseXP, isCorrect: true, combo: _combo)
        : _svc.calculateXP(baseXP: baseXP, isCorrect: false, combo: _combo);

    setState(() {
      _answered = true;
      _selectedIdx = displayIdx;

      if (isCorrect) {
        _correctCount++;
        _combo += _svc.comboIncrement();
        _totalXP += earnedXP;
        _learnedWords.add(_current.word);

        // Bonus sandık: ilk doğru cevap
        if (!_firstCorrectGiven && _event.effect.bonusChestOnFirst
            && !_svc.bonusChestClaimed) {
          _firstCorrectGiven = true;
          _bonusChestShown = true;
        }

        _xpToast = '+$earnedXP XP${_combo >= 3 ? '  🔥×$_combo' : ''}';
      } else {
        _lastFailedWord = _current.word;
        if (_event.effect.resetComboOnWrong) _combo = 0;
        if (_svc.shouldTakeDamage()) {
          _lives--;
          HapticFeedback.heavyImpact();
        }
      }
    });

    _cardCtrl.forward();
    if (isCorrect) {
      _xpCtrl.forward(from: 0);
    }
  }

  void _next() {
    // Can bitti mi?
    if (_lives <= 0) {
      widget.onDefeat(_lastFailedWord);
      return;
    }
    // Sorular bitti mi?
    if (_currentIndex >= widget.questions.length - 1) {
      widget.onComplete(SessionResult(
        department:     widget.department,
        theme:          widget.theme,
        totalQuestions: widget.questions.length,
        correctAnswers: _correctCount,
        learnedWords:   _learnedWords,
        completedAt:    DateTime.now(),
      ));
      return;
    }
    // Sonraki soru
    setState(() {
      _currentIndex++;
      _answered = false;
      _selectedIdx = null;
      _bonusChestShown = false;
    });
    _cardCtrl.reverse();
    _startWordHideTimer();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            // Aktif olay HUD
            ActiveEventHUD(event: _event),
            // Bonus sandık toast
            if (_bonusChestShown && !_svc.bonusChestClaimed)
              BonusChestToast(
                onClaim: () async {
                  await _svc.claimBonusChest();
                  setState(() => _bonusChestShown = false);
                  widget.onBonusChest(ChestRewards.treasure());
                },
              ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
                child: Column(
                  children: [
                    _buildProgressRow(),
                    const SizedBox(height: 12),
                    _buildWordCard(),
                    const SizedBox(height: 14),
                    _buildOptions(),
                    if (_answered) ...[
                      const SizedBox(height: 12),
                      _buildFeedback(),
                      const SizedBox(height: 12),
                      PrimaryButton(
                        label: _currentIndex < widget.questions.length - 1
                            ? 'Sonraki soru →'
                            : 'Sonuçları gör →',
                        onTap: _next,
                        color: _selectedIdx == _currentCorrectIdx
                            ? AppColors.saglik
                            : _deptColor,
                      ),
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

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 10),
      child: Row(
        children: [
          GestureDetector(
            onTap: widget.onBack,
            child: Container(
              width: 36, height: 36,
              decoration: BoxDecoration(
                color: AppColors.bg3,
                borderRadius: AppRadius.smBR,
                border: Border.all(color: AppColors.border2),
              ),
              child: const Icon(Icons.chevron_left_rounded,
                  color: AppColors.text, size: 20),
            ),
          ),
          const SizedBox(width: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
            decoration: BoxDecoration(
              color: deptDimColor(widget.department),
              borderRadius: AppRadius.smBR,
            ),
            child: Text(
              '${widget.department.shortLabel} · ${widget.theme}',
              style: AppTextStyles.body(12,
                  color: _deptColor, weight: FontWeight.w600),
            ),
          ),
          const Spacer(),
          // Canlar
          Row(
            children: List.generate(
              _svc.startingLives(3),
              (i) => Padding(
                padding: const EdgeInsets.only(left: 3),
                child: Icon(
                  Icons.favorite_rounded,
                  size: 18,
                  color: i < _lives ? AppColors.danger : AppColors.dim,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProgressRow() {
    final total = widget.questions.length;
    return Column(
      children: [
        Row(
          children: List.generate(total, (i) {
            Color color;
            if (i < _currentIndex)       color = _deptColor;
            else if (i == _currentIndex) color = _deptColor.withOpacity(0.5);
            else                         color = AppColors.border;
            return Expanded(
              child: Container(
                height: 3,
                margin: EdgeInsets.only(left: i == 0 ? 0 : 4),
                decoration: BoxDecoration(
                    color: color, borderRadius: BorderRadius.circular(99)),
              ),
            );
          }),
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Soru ${_currentIndex + 1} / $total',
                style: AppTextStyles.mono(12, color: AppColors.muted)),
            // XP toast
            AnimatedBuilder(
              animation: _xpFade,
              builder: (_, __) => Opacity(
                opacity: 1.0 - _xpFade.value,
                child: Text(_xpToast,
                    style: AppTextStyles.mono(12, color: AppColors.saglik,
                        weight: FontWeight.w600)),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildWordCard() {
    final word = _current.word;

    return ScaleTransition(
      scale: _cardScale,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: AppColors.bg2,
          borderRadius: AppRadius.xlBR,
          border: Border.all(color: AppColors.border2),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('TÜRKÇE ANLAMI NEDİR?',
                style: AppTextStyles.label(10, color: AppColors.muted)),
            const SizedBox(height: 14),

            // Sis/Flaş efekti: kelime gizlenince blur animasyonu
            AnimatedBuilder(
              animation: _fogCtrl,
              builder: (_, child) {
                if (!_event.effect.hideWordAfterMs) return child!;
                return AnimatedOpacity(
                  opacity: _wordVisible ? 1.0 : 0.0,
                  duration: const Duration(milliseconds: 400),
                  child: child,
                );
              },
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(word.word,
                      style: AppTextStyles.display(34, weight: FontWeight.w700)),
                  const SizedBox(height: 6),
                  // Sessiz Boss: fonetik her zaman göster ama ses yok
                  Text(word.phonetic,
                      style: AppTextStyles.mono(13, color: AppColors.muted)),
                ],
              ),
            ),

            if (!_wordVisible && _event.effect.hideWordAfterMs)
              Container(
                height: 54,
                decoration: BoxDecoration(
                  color: AppColors.border,
                  borderRadius: AppRadius.smBR,
                ),
                alignment: Alignment.center,
                child: Text('???',
                    style: AppTextStyles.display(24, color: AppColors.dim)),
              ),

            const SizedBox(height: 14),
            ExamTimeline(
              examYears: word.examYears,
              color: _deptColor,
              highProbability: word.highProbability,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOptions() {
    final letters = ['A', 'B', 'C', 'D'];
    return Column(
      children: List.generate(_currentOptions.length, (i) {
        OptionState state;
        if (!_answered)                           state = OptionState.idle;
        else if (i == _currentCorrectIdx)         state = OptionState.correct;
        else if (i == _selectedIdx)               state = OptionState.wrong;
        else                                      state = OptionState.idle;

        return Padding(
          padding: const EdgeInsets.only(bottom: 9),
          child: _OptionTile(
            letter: letters[i],
            text: _currentOptions[i],
            state: state,
            onTap: () => _pick(i),
          ),
        );
      }),
    );
  }

  Widget _buildFeedback() {
    final isCorrect = _selectedIdx == _currentCorrectIdx;
    final ef = _event.effect;

    String msg;
    if (isCorrect) {
      if (ef.doubleOrNothing) msg = 'Doğru! XP iki katlandı 🎲';
      else if (ef.singleLife)  msg = 'Doğru! Demir irade sürüyor ⚔️';
      else                     msg = 'Doğru! +${_svc.calculateXP(baseXP: 20, isCorrect: true, combo: _combo)} XP';
    } else {
      if (ef.noDamageOnWrong)  msg = 'Yanlış — ama ruh bağı seni korudu 🛡️';
      else if (ef.singleLife)  msg = 'Demir irade kırıldı 💀';
      else                     msg = 'Yanlış cevap · −1 can';
    }

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isCorrect ? AppColors.saglikDim : AppColors.dangerDim,
        borderRadius: AppRadius.mdBR,
        border: Border.all(
            color: isCorrect ? AppColors.saglik : AppColors.danger),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(msg,
              style: AppTextStyles.display(13,
                  color: isCorrect ? AppColors.saglik : AppColors.danger,
                  weight: FontWeight.w600)),
          const SizedBox(height: 4),
          RichText(
            text: TextSpan(children: [
              TextSpan(
                  text: '"${_current.word.exampleSentence}"',
                  style: AppTextStyles.body(12, color: AppColors.muted)
                      .copyWith(fontStyle: FontStyle.italic)),
            ]),
          ),
          const SizedBox(height: 2),
          Text('Türkçesi: ${_current.word.trMeaning}',
              style: AppTextStyles.body(12,
                  color: AppColors.text, weight: FontWeight.w500)),
        ],
      ),
    );
  }
}

// ─── Seçenek Satırı ──────────────────────────────────────────────────────────
class _OptionTile extends StatelessWidget {
  final String letter;
  final String text;
  final OptionState state;
  final VoidCallback onTap;

  const _OptionTile(
      {required this.letter, required this.text,
        required this.state, required this.onTap});

  @override
  Widget build(BuildContext context) {
    Color bg, border, letterBg, letterColor;
    switch (state) {
      case OptionState.correct:
        bg = AppColors.saglikDim; border = AppColors.saglik;
        letterBg = AppColors.saglik; letterColor = AppColors.bg;
      case OptionState.wrong:
        bg = AppColors.dangerDim; border = AppColors.danger;
        letterBg = AppColors.danger; letterColor = AppColors.bg;
      case OptionState.idle:
        bg = AppColors.bg3; border = AppColors.border2;
        letterBg = AppColors.bg2; letterColor = AppColors.muted;
    }
    return GestureDetector(
      onTap: state == OptionState.idle ? onTap : null,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
            color: bg, borderRadius: AppRadius.mdBR,
            border: Border.all(color: border)),
        child: Row(
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 160),
              width: 28, height: 28,
              decoration: BoxDecoration(
                  color: letterBg, borderRadius: AppRadius.smBR,
                  border: Border.all(color: border)),
              alignment: Alignment.center,
              child: Text(letter,
                  style: AppTextStyles.display(13,
                      color: letterColor, weight: FontWeight.w600)),
            ),
            const SizedBox(width: 12),
            Expanded(
                child: Text(text,
                    style: AppTextStyles.body(14, weight: FontWeight.w500))),
          ],
        ),
      ),
    );
  }
}
