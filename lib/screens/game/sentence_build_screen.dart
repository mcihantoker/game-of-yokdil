import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../theme/app_theme.dart';
import '../../models/models.dart';
import '../../models/sentence_model.dart';
import '../../widgets/shared_widgets.dart';

// ═══════════════════════════════════════════════════════════════════════════════
// CÜMLE İNŞA EKRANI
// ═══════════════════════════════════════════════════════════════════════════════
class SentenceBuildScreen extends StatefulWidget {
  final SentenceSet sentenceSet;
  final Function(SentenceSessionResult) onComplete;
  final VoidCallback onBack;

  const SentenceBuildScreen({
    super.key,
    required this.sentenceSet,
    required this.onComplete,
    required this.onBack,
  });

  @override
  State<SentenceBuildScreen> createState() => _SentenceBuildScreenState();
}

class _SentenceBuildScreenState extends State<SentenceBuildScreen>
    with TickerProviderStateMixin {

  int _currentIndex = 0;
  int _correctCount = 0;
  int _examPoints = 0;
  bool _answered = false;
  int? _selectedIdx;
  final List<SentenceQuestion> _wrongQuestions = [];
  late DateTime _startTime;

  // Animasyonlar
  late AnimationController _slideCtrl;
  late AnimationController _feedbackCtrl;
  late AnimationController _blankPulseCtrl;
  late Animation<Offset> _slideAnim;
  late Animation<double> _feedbackScale;
  late Animation<double> _blankPulse;

  // Açıklama expanded mı
  bool _explanationExpanded = false;

  @override
  void initState() {
    super.initState();
    _startTime = DateTime.now();

    _slideCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 280));
    _feedbackCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 350));
    _blankPulseCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 900))
      ..repeat(reverse: true);

    _slideAnim = Tween<Offset>(begin: const Offset(0.08, 0), end: Offset.zero)
        .animate(CurvedAnimation(parent: _slideCtrl, curve: Curves.easeOut));
    _feedbackScale = Tween<double>(begin: 0.92, end: 1.0).animate(
        CurvedAnimation(parent: _feedbackCtrl, curve: Curves.easeOutBack));
    _blankPulse = Tween<double>(begin: 0.5, end: 1.0).animate(
        CurvedAnimation(parent: _blankPulseCtrl, curve: Curves.easeInOut));

    _slideCtrl.forward();
  }

  @override
  void dispose() {
    _slideCtrl.dispose();
    _feedbackCtrl.dispose();
    _blankPulseCtrl.dispose();
    super.dispose();
  }

  SentenceQuestion get _current =>
      widget.sentenceSet.questions[_currentIndex];

  Color get _deptColor => deptColor(widget.sentenceSet.department);
  Color get _deptDim => deptDimColor(widget.sentenceSet.department);

  void _pick(int idx) {
    if (_answered) return;
    HapticFeedback.selectionClick();
    final isCorrect = idx == _current.correctIndex;

    setState(() {
      _answered = true;
      _selectedIdx = idx;
      if (isCorrect) {
        _correctCount++;
        _examPoints += _current.examRelevanceScore * 10;
      } else {
        _wrongQuestions.add(_current);
        HapticFeedback.heavyImpact();
      }
      _explanationExpanded = false;
    });

    _blankPulseCtrl.stop();
    _feedbackCtrl.forward(from: 0);
  }

  void _next() {
    final total = widget.sentenceSet.total;
    if (_currentIndex >= total - 1) {
      widget.onComplete(SentenceSessionResult(
        set: widget.sentenceSet,
        correctCount: _correctCount,
        totalCount: total,
        examReadinessPoints: _examPoints,
        wrongQuestions: _wrongQuestions,
        timeSpent: DateTime.now().difference(_startTime),
      ));
      return;
    }

    _slideCtrl.reset();
    _blankPulseCtrl.repeat(reverse: true);
    setState(() {
      _currentIndex++;
      _answered = false;
      _selectedIdx = null;
      _explanationExpanded = false;
    });
    _slideCtrl.forward();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            _buildProgressBar(),
            Expanded(
              child: SlideTransition(
                position: _slideAnim,
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildQuestionTypeTag(),
                      const SizedBox(height: 14),
                      _buildQuestionCard(),
                      const SizedBox(height: 16),
                      _buildOptions(),
                      if (_answered) ...[
                        const SizedBox(height: 14),
                        ScaleTransition(
                          scale: _feedbackScale,
                          child: _buildFeedbackCard(),
                        ),
                        const SizedBox(height: 14),
                        PrimaryButton(
                          label: _currentIndex < widget.sentenceSet.total - 1
                              ? 'Sonraki soru →'
                              : 'Sonuçları gör →',
                          onTap: _next,
                          color: _selectedIdx == _current.correctIndex
                              ? AppColors.saglik
                              : _deptColor,
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─── Header ──────────────────────────────────────────────────────────────
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
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Cümle İnşa Modu',
                  style: AppTextStyles.display(15, weight: FontWeight.w600),
                ),
                Text(
                  '${widget.sentenceSet.department.label} · ${widget.sentenceSet.theme}',
                  style: AppTextStyles.body(12, color: AppColors.muted),
                ),
              ],
            ),
          ),
          // Sınav puanı
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: _deptDim,
              borderRadius: AppRadius.smBR,
            ),
            child: Row(
              children: [
                Icon(Icons.school_outlined, size: 13, color: _deptColor),
                const SizedBox(width: 5),
                Text(
                  '$_examPoints puan',
                  style: AppTextStyles.mono(11,
                      color: _deptColor, weight: FontWeight.w600),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ─── İlerleme çubuğu ─────────────────────────────────────────────────────
  Widget _buildProgressBar() {
    final total = widget.sentenceSet.total;
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 14),
      child: Column(
        children: [
          Row(
            children: List.generate(total, (i) {
              Color c;
              if (i < _currentIndex)       c = _deptColor;
              else if (i == _currentIndex) c = _deptColor.withOpacity(0.45);
              else                         c = AppColors.border;
              return Expanded(
                child: Container(
                  height: 3,
                  margin: EdgeInsets.only(left: i == 0 ? 0 : 5),
                  decoration: BoxDecoration(
                    color: c,
                    borderRadius: BorderRadius.circular(99),
                  ),
                ),
              );
            }),
          ),
          const SizedBox(height: 7),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Soru ${_currentIndex + 1} / $total',
                style: AppTextStyles.mono(11, color: AppColors.muted),
              ),
              Text(
                '${_current.difficulty.label} · +${_current.examRelevanceScore * 10} puan',
                style: AppTextStyles.mono(11, color: AppColors.dim),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ─── Soru tipi etiketi ────────────────────────────────────────────────────
  Widget _buildQuestionTypeTag() {
    final type = _current.type;
    final (icon, label) = switch (type) {
      SentenceQuestionType.fillBlank     => (Icons.edit_outlined, 'Boşluk doldur'),
      SentenceQuestionType.wordInContext  => (Icons.search_rounded, 'Bağlamdan anla'),
      SentenceQuestionType.chooseCorrect => (Icons.check_circle_outline, 'Doğru kullanımı bul'),
    };

    // Kaynak varsa göster
    final source = _current.examSource;

    return Row(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(
            color: _deptDim,
            borderRadius: AppRadius.smBR,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 13, color: _deptColor),
              const SizedBox(width: 5),
              Text(label,
                  style: AppTextStyles.body(12,
                      color: _deptColor, weight: FontWeight.w500)),
            ],
          ),
        ),
        if (source != null) ...[
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              source,
              style: AppTextStyles.mono(10, color: AppColors.dim),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ],
    );
  }

  // ─── Soru kartı (tipe göre farklı görünüm) ───────────────────────────────
  Widget _buildQuestionCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.bg2,
        borderRadius: AppRadius.xlBR,
        border: Border.all(color: AppColors.border2),
      ),
      child: switch (_current.type) {
        SentenceQuestionType.fillBlank     => _buildFillBlankContent(),
        SentenceQuestionType.wordInContext  => _buildWordInContextContent(),
        SentenceQuestionType.chooseCorrect => _buildChooseCorrectContent(),
      },
    );
  }

  // fillBlank: cümle + animasyonlu boşluk
  Widget _buildFillBlankContent() {
    final answered = _answered;
    final correctWord = _current.options[_current.correctIndex];
    final selectedWord = answered && _selectedIdx != null
        ? _current.options[_selectedIdx!]
        : null;
    final isCorrect = answered && _selectedIdx == _current.correctIndex;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Boşluğa uygun kelimeyi seç:',
            style: AppTextStyles.label(10, color: AppColors.muted)),
        const SizedBox(height: 16),
        // Cümle + boşluk inline
        _InlineSentence(
          before: _current.sentenceBefore,
          after: _current.sentenceAfter,
          filledWord: answered ? selectedWord : null,
          correctWord: answered ? correctWord : null,
          isCorrect: isCorrect,
          blankPulse: _blankPulse,
          deptColor: _deptColor,
        ),
      ],
    );
  }

  // wordInContext: altı çizili kelime içeren cümle
  Widget _buildWordInContextContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Altı çizili kelimenin anlamı nedir?',
            style: AppTextStyles.label(10, color: AppColors.muted)),
        const SizedBox(height: 16),
        _UnderlineSentence(
          before: _current.sentenceBefore,
          after: _current.sentenceAfter,
          underlinedWord: _current.underlinedWord ?? _current.targetWord.word,
          deptColor: _deptColor,
        ),
      ],
    );
  }

  // chooseCorrect: 4 tam cümle, hangisi doğru?
  Widget _buildChooseCorrectContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(_current.sentenceBefore,
            style: AppTextStyles.body(14, color: AppColors.text)),
        const SizedBox(height: 14),
        // Hedef kelime rozeti
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: _deptDim,
            borderRadius: AppRadius.smBR,
          ),
          child: Text(
            '"${_current.targetWord.word.toUpperCase()}"',
            style: AppTextStyles.mono(13, color: _deptColor, weight: FontWeight.w700),
          ),
        ),
      ],
    );
  }

  // ─── Seçenekler ──────────────────────────────────────────────────────────
  Widget _buildOptions() {
    final isChooseCorrect =
        _current.type == SentenceQuestionType.chooseCorrect;
    final choices = _current.choices;

    return Column(
      children: List.generate(_current.options.length, (i) {
        _OptionState state;
        if (!_answered)                          state = _OptionState.idle;
        else if (i == _current.correctIndex)     state = _OptionState.correct;
        else if (i == _selectedIdx)              state = _OptionState.wrong;
        else                                     state = _OptionState.idle;

        // chooseCorrect: uzun cümle göster
        final label = (isChooseCorrect && choices != null && i < choices.length)
            ? choices[i]
            : _current.options[i];

        return Padding(
          padding: const EdgeInsets.only(bottom: 9),
          child: _OptionCard(
            label: label,
            letter: ['A', 'B', 'C', 'D'][i],
            state: state,
            isLong: isChooseCorrect,
            onTap: () => _pick(i),
          ),
        );
      }),
    );
  }

  // ─── Geri bildirim kartı ─────────────────────────────────────────────────
  Widget _buildFeedbackCard() {
    final isCorrect = _selectedIdx == _current.correctIndex;
    final borderC = isCorrect ? AppColors.saglik : AppColors.danger;
    final bgC = isCorrect ? AppColors.saglikDim : AppColors.dangerDim;

    return Container(
      decoration: BoxDecoration(
        color: bgC,
        borderRadius: AppRadius.lgBR,
        border: Border.all(color: borderC),
      ),
      child: Column(
        children: [
          // Başlık satırı
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
            child: Row(
              children: [
                Icon(
                  isCorrect ? Icons.check_circle_rounded : Icons.cancel_rounded,
                  color: borderC, size: 20,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    isCorrect ? 'Doğru! +${_current.examRelevanceScore * 10} sınav puanı'
                        : 'Yanlış — doğru cevap: ${_current.options[_current.correctIndex]}',
                    style: AppTextStyles.display(14,
                        color: borderC, weight: FontWeight.w600),
                  ),
                ),
              ],
            ),
          ),
          // Divider
          Divider(height: 0.5, color: borderC.withOpacity(0.3)),
          // Açıklama (expandable)
          GestureDetector(
            onTap: () =>
                setState(() => _explanationExpanded = !_explanationExpanded),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.lightbulb_outline_rounded,
                          size: 14, color: borderC.withOpacity(0.7)),
                      const SizedBox(width: 6),
                      Text(
                        'Neden bu cevap?',
                        style: AppTextStyles.body(12,
                            color: borderC, weight: FontWeight.w500),
                      ),
                      const Spacer(),
                      Icon(
                        _explanationExpanded
                            ? Icons.keyboard_arrow_up_rounded
                            : Icons.keyboard_arrow_down_rounded,
                        size: 18,
                        color: borderC.withOpacity(0.6),
                      ),
                    ],
                  ),
                  AnimatedCrossFade(
                    duration: const Duration(milliseconds: 220),
                    crossFadeState: _explanationExpanded
                        ? CrossFadeState.showSecond
                        : CrossFadeState.showFirst,
                    firstChild: const SizedBox.shrink(),
                    secondChild: Padding(
                      padding: const EdgeInsets.only(top: 10),
                      child: Text(
                        _current.explanation,
                        style: AppTextStyles.body(13, color: AppColors.text)
                            .copyWith(height: 1.55),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          // Kaynak
          if (_current.examSource != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
              child: Row(
                children: [
                  Icon(Icons.bookmark_outline_rounded,
                      size: 12, color: AppColors.dim),
                  const SizedBox(width: 5),
                  Text(
                    _current.examSource!,
                    style: AppTextStyles.mono(10, color: AppColors.dim),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

// ─── Inline cümle (boşluklu) ─────────────────────────────────────────────────
class _InlineSentence extends StatelessWidget {
  final String before;
  final String after;
  final String? filledWord;
  final String? correctWord;
  final bool isCorrect;
  final Animation<double> blankPulse;
  final Color deptColor;

  const _InlineSentence({
    required this.before,
    required this.after,
    required this.blankPulse,
    required this.deptColor,
    this.filledWord,
    this.correctWord,
    this.isCorrect = false,
  });

  @override
  Widget build(BuildContext context) {
    final style = GoogleFonts.inter(
      fontSize: 16,
      color: AppColors.text,
      height: 1.6,
    );

    return RichText(
      text: TextSpan(
        style: style,
        children: [
          TextSpan(text: before.trim()),
          const TextSpan(text: ' '),
          WidgetSpan(
            alignment: PlaceholderAlignment.middle,
            child: filledWord != null
                ? _FilledBlank(
                    word: filledWord!,
                    isCorrect: isCorrect,
                    correctWord: correctWord,
                  )
                : AnimatedBuilder(
                    animation: blankPulse,
                    builder: (_, __) => _EmptyBlank(
                      pulse: blankPulse.value,
                      color: deptColor,
                    ),
                  ),
          ),
          const TextSpan(text: ' '),
          TextSpan(text: after.trim()),
        ],
      ),
    );
  }
}

class _EmptyBlank extends StatelessWidget {
  final double pulse;
  final Color color;
  const _EmptyBlank({required this.pulse, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 90,
      height: 28,
      margin: const EdgeInsets.symmetric(horizontal: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(pulse * 0.12),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: color.withOpacity(pulse * 0.6),
          width: 1.5,
        ),
      ),
      alignment: Alignment.center,
      child: Text(
        '?????',
        style: AppTextStyles.mono(12,
            color: color.withOpacity(pulse), weight: FontWeight.w600),
      ),
    );
  }
}

class _FilledBlank extends StatelessWidget {
  final String word;
  final bool isCorrect;
  final String? correctWord;
  const _FilledBlank({required this.word, required this.isCorrect, this.correctWord});

  @override
  Widget build(BuildContext context) {
    final color = isCorrect ? AppColors.saglik : AppColors.danger;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      margin: const EdgeInsets.symmetric(horizontal: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withOpacity(0.6)),
      ),
      child: Text(
        word,
        style: AppTextStyles.mono(13, color: color, weight: FontWeight.w600),
      ),
    );
  }
}

// ─── Altı çizili cümle ───────────────────────────────────────────────────────
class _UnderlineSentence extends StatelessWidget {
  final String before;
  final String after;
  final String underlinedWord;
  final Color deptColor;

  const _UnderlineSentence({
    required this.before,
    required this.after,
    required this.underlinedWord,
    required this.deptColor,
  });

  @override
  Widget build(BuildContext context) {
    final base = GoogleFonts.inter(
        fontSize: 16, color: AppColors.text, height: 1.6);

    return RichText(
      text: TextSpan(
        style: base,
        children: [
          TextSpan(text: '${before.trim()} '),
          WidgetSpan(
            alignment: PlaceholderAlignment.baseline,
            baseline: TextBaseline.alphabetic,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(underlinedWord,
                    style: base.copyWith(
                        color: deptColor,
                        fontWeight: FontWeight.w600,
                        decoration: TextDecoration.underline,
                        decorationColor: deptColor,
                        decorationThickness: 2)),
              ],
            ),
          ),
          TextSpan(text: ' ${after.trim()}'),
        ],
      ),
    );
  }
}

// ─── Seçenek Kartı ───────────────────────────────────────────────────────────
enum _OptionState { idle, correct, wrong }

class _OptionCard extends StatelessWidget {
  final String label;
  final String letter;
  final _OptionState state;
  final bool isLong;
  final VoidCallback onTap;

  const _OptionCard({
    required this.label,
    required this.letter,
    required this.state,
    required this.onTap,
    this.isLong = false,
  });

  @override
  Widget build(BuildContext context) {
    Color bg, border, letterBg, letterColor;
    switch (state) {
      case _OptionState.correct:
        bg = AppColors.saglikDim; border = AppColors.saglik;
        letterBg = AppColors.saglik; letterColor = AppColors.bg;
      case _OptionState.wrong:
        bg = AppColors.dangerDim; border = AppColors.danger;
        letterBg = AppColors.danger; letterColor = AppColors.bg;
      case _OptionState.idle:
        bg = AppColors.bg3; border = AppColors.border2;
        letterBg = AppColors.bg2; letterColor = AppColors.muted;
    }

    return GestureDetector(
      onTap: state == _OptionState.idle ? onTap : null,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        padding: EdgeInsets.symmetric(
          horizontal: 14, vertical: isLong ? 12 : 13),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: AppRadius.mdBR,
          border: Border.all(color: border),
        ),
        child: Row(
          crossAxisAlignment: isLong
              ? CrossAxisAlignment.start
              : CrossAxisAlignment.center,
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 160),
              width: 28, height: 28,
              decoration: BoxDecoration(
                color: letterBg,
                borderRadius: AppRadius.smBR,
                border: Border.all(color: border),
              ),
              alignment: Alignment.center,
              child: Text(letter,
                  style: AppTextStyles.display(13,
                      color: letterColor, weight: FontWeight.w600)),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                label,
                style: AppTextStyles.body(
                    isLong ? 13 : 14, weight: FontWeight.w500),
                maxLines: isLong ? 4 : 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Extension: difficulty label ─────────────────────────────────────────────
extension DifficultyLabel on SentenceDifficulty {
  String get label {
    switch (this) {
      case SentenceDifficulty.easy:   return 'Kolay';
      case SentenceDifficulty.medium: return 'Orta';
      case SentenceDifficulty.hard:   return 'Zor';
    }
  }
}
