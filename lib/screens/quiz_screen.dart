import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../models/models.dart';
import '../widgets/shared_widgets.dart';

enum OptionState { idle, correct, wrong }

class QuizScreen extends StatefulWidget {
  final List<Question> questions;
  final Department department;
  final String theme;
  final Function(SessionResult) onComplete;
  final VoidCallback onBack;

  const QuizScreen({
    super.key,
    required this.questions,
    required this.department,
    required this.theme,
    required this.onComplete,
    required this.onBack,
  });

  @override
  State<QuizScreen> createState() => _QuizScreenState();
}

class _QuizScreenState extends State<QuizScreen> with SingleTickerProviderStateMixin {
  int _currentIndex = 0;
  int _correctCount = 0;
  int _hearts = 3;
  bool _answered = false;
  int? _selectedIndex;
  final List<Word> _learnedWords = [];

  late AnimationController _cardController;
  late Animation<double> _cardScale;

  @override
  void initState() {
    super.initState();
    _cardController = AnimationController(vsync: this, duration: const Duration(milliseconds: 200));
    _cardScale = Tween<double>(begin: 1.0, end: 0.97)
        .animate(CurvedAnimation(parent: _cardController, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _cardController.dispose();
    super.dispose();
  }

  Question get _current => widget.questions[_currentIndex];
  Color get _deptColor => deptColor(widget.department);
  Color get _deptDim   => deptDimColor(widget.department);

  void _pick(int index) {
    if (_answered) return;
    setState(() {
      _answered = true;
      _selectedIndex = index;
      final isCorrect = index == _current.correctIndex;
      if (isCorrect) {
        _correctCount++;
        _learnedWords.add(_current.word);
      } else {
        _hearts = (_hearts - 1).clamp(0, 3);
      }
    });
    _cardController.forward();
  }

  void _next() {
    if (_currentIndex < widget.questions.length - 1) {
      setState(() {
        _currentIndex++;
        _answered = false;
        _selectedIndex = null;
      });
      _cardController.reverse();
    } else {
      widget.onComplete(SessionResult(
        department:     widget.department,
        theme:          widget.theme,
        totalQuestions: widget.questions.length,
        correctAnswers: _correctCount,
        learnedWords:   _learnedWords,
        completedAt:    DateTime.now(),
      ));
    }
  }

  OptionState _stateFor(int index) {
    if (!_answered) return OptionState.idle;
    if (index == _current.correctIndex) return OptionState.correct;
    if (index == _selectedIndex) return OptionState.wrong;
    return OptionState.idle;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            _buildProgressRow(),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                child: Column(
                  children: [
                    const SizedBox(height: 8),
                    _buildWordCard(),
                    const SizedBox(height: 16),
                    _buildOptions(),
                    if (_answered) ...[
                      const SizedBox(height: 14),
                      _buildFeedback(),
                      const SizedBox(height: 14),
                      PrimaryButton(
                        label: _currentIndex < widget.questions.length - 1
                            ? 'Sonraki soru →'
                            : 'Sonuçları gör →',
                        onTap: _next,
                        color: _answered && _selectedIndex == _current.correctIndex
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
              child: const Icon(Icons.chevron_left_rounded, color: AppColors.text, size: 20),
            ),
          ),
          const SizedBox(width: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
            decoration: BoxDecoration(
              color: _deptDim,
              borderRadius: AppRadius.smBR,
            ),
            child: Text(
              '${widget.department.shortLabel} · ${widget.theme}',
              style: AppTextStyles.body(12, color: _deptColor, weight: FontWeight.w600),
            ),
          ),
          const Spacer(),
          Row(
            children: List.generate(3, (i) => Padding(
              padding: const EdgeInsets.only(left: 3),
              child: Icon(
                Icons.favorite_rounded,
                size: 18,
                color: i < _hearts ? AppColors.danger : AppColors.dim,
              ),
            )),
          ),
        ],
      ),
    );
  }

  Widget _buildProgressRow() {
    final total = widget.questions.length;
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
      child: Column(
        children: [
          Row(
            children: List.generate(total, (i) {
              Color color;
              if (i < _currentIndex) {
                color = _deptColor;
              } else if (i == _currentIndex) {
                color = _deptColor.withValues(alpha: 0.5);
              } else {
                color = AppColors.border;
              }
              return Expanded(
                child: Container(
                  height: 3,
                  margin: EdgeInsets.only(left: i == 0 ? 0 : 4),
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius: BorderRadius.circular(99),
                  ),
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
              Text('+20 XP', style: AppTextStyles.mono(12, color: _deptColor)),
            ],
          ),
        ],
      ),
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
        child: Stack(
          children: [
            Positioned(
              bottom: -20, left: 0, right: 0,
              child: Center(
                child: Container(
                  width: 180, height: 50,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(99),
                    color: _deptColor.withValues(alpha: 0.12),
                  ),
                ),
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('TÜRKÇE ANLAMI NEDİR?',
                    style: AppTextStyles.label(10, color: AppColors.muted)),
                const SizedBox(height: 16),
                Text(word.word.toUpperCase(),
                    style: AppTextStyles.display(36, weight: FontWeight.w700)),
                if (word.phonetic.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Text(word.phonetic, style: AppTextStyles.mono(13, color: AppColors.muted)),
                ],
                const SizedBox(height: 14),
                ExamTimeline(
                  examYears: word.examYears,
                  color: _deptColor,
                  highProbability: word.highProbability,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOptions() {
    final letters = ['A', 'B', 'C', 'D'];
    return Column(
      children: List.generate(_current.options.length, (i) {
        final state = _stateFor(i);
        return Padding(
          padding: const EdgeInsets.only(bottom: 9),
          child: _OptionTile(
            letter: letters[i],
            text: _current.options[i],
            state: state,
            onTap: () => _pick(i),
          ),
        );
      }),
    );
  }

  Widget _buildFeedback() {
    final isCorrect = _selectedIndex == _current.correctIndex;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isCorrect ? AppColors.saglikDim : AppColors.dangerDim,
        borderRadius: AppRadius.mdBR,
        border: Border.all(color: isCorrect ? AppColors.saglik : AppColors.danger),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            isCorrect ? 'Doğru! +20 XP' : 'Yanlış cevap',
            style: AppTextStyles.display(14,
                color: isCorrect ? AppColors.saglik : AppColors.danger,
                weight: FontWeight.w600),
          ),
          const SizedBox(height: 4),
          Text(
            '"${_current.word.exampleSentence}"',
            style: AppTextStyles.body(13, color: AppColors.muted),
          ),
          const SizedBox(height: 2),
          Text(
            'Türkçesi: ${_current.word.trMeaning}',
            style: AppTextStyles.body(13, color: AppColors.text, weight: FontWeight.w500),
          ),
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

  const _OptionTile({
    required this.letter,
    required this.text,
    required this.state,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    Color borderColor;
    Color bgColor;
    Color letterBg;
    Color letterColor;

    switch (state) {
      case OptionState.correct:
        borderColor = AppColors.saglik;
        bgColor     = AppColors.saglikDim;
        letterBg    = AppColors.saglik;
        letterColor = AppColors.bg;
      case OptionState.wrong:
        borderColor = AppColors.danger;
        bgColor     = AppColors.dangerDim;
        letterBg    = AppColors.danger;
        letterColor = AppColors.bg;
      case OptionState.idle:
        borderColor = AppColors.border2;
        bgColor     = AppColors.bg3;
        letterBg    = AppColors.bg2;
        letterColor = AppColors.muted;
    }

    return GestureDetector(
      onTap: state == OptionState.idle ? onTap : null,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: AppRadius.mdBR,
          border: Border.all(color: borderColor),
        ),
        child: Row(
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              width: 28, height: 28,
              decoration: BoxDecoration(
                color: letterBg,
                borderRadius: AppRadius.smBR,
                border: Border.all(color: borderColor),
              ),
              alignment: Alignment.center,
              child: Text(letter,
                  style: AppTextStyles.display(13, color: letterColor, weight: FontWeight.w600)),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(text, style: AppTextStyles.body(14, weight: FontWeight.w500)),
            ),
          ],
        ),
      ),
    );
  }
}
