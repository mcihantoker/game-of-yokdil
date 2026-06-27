import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../../models/models.dart';
import '../../models/sentence_model.dart';
import '../../widgets/shared_widgets.dart';

// ═══════════════════════════════════════════════════════════════════════════════
// CÜMLE İNŞA SONUÇ EKRANI
// ═══════════════════════════════════════════════════════════════════════════════
class SentenceResultScreen extends StatefulWidget {
  final SentenceSessionResult result;
  final VoidCallback onReplay;
  final VoidCallback onHome;
  final VoidCallback? onStartMiniExam; // 5 cümle tam doğru → deneme sınavı kilidi açılır

  const SentenceResultScreen({
    super.key,
    required this.result,
    required this.onReplay,
    required this.onHome,
    this.onStartMiniExam,
  });

  @override
  State<SentenceResultScreen> createState() => _SentenceResultScreenState();
}

class _SentenceResultScreenState extends State<SentenceResultScreen>
    with SingleTickerProviderStateMixin {

  late AnimationController _ctrl;
  late Animation<double> _fadeIn;
  late Animation<double> _scoreAnim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 900));
    _fadeIn = CurvedAnimation(parent: _ctrl, curve: Curves.easeOut);
    _scoreAnim = CurvedAnimation(
        parent: _ctrl, curve: const Interval(0.2, 0.9, curve: Curves.easeOut));
    _ctrl.forward();
  }

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  SentenceSessionResult get r => widget.result;
  Color get _deptColor => deptColor(r.set.department);
  Color get _deptDim   => deptDimColor(r.set.department);

  bool get _isPerfect => r.correctCount == r.totalCount;
  bool get _canUnlockExam => _isPerfect && widget.onStartMiniExam != null;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      body: SafeArea(
        child: FadeTransition(
          opacity: _fadeIn,
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 28, 20, 32),
            child: Column(
              children: [
                _buildHero(),
                const SizedBox(height: 20),
                _buildScoreCard(),
                const SizedBox(height: 14),
                _buildStatsRow(),
                const SizedBox(height: 14),
                if (r.wrongQuestions.isNotEmpty) ...[
                  _buildWrongReview(),
                  const SizedBox(height: 14),
                ],
                if (_canUnlockExam) ...[
                  _buildMiniExamUnlock(),
                  const SizedBox(height: 14),
                ],
                _buildButtons(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ─── Hero alanı ──────────────────────────────────────────────────────────
  Widget _buildHero() {
    final emoji = _isPerfect ? '🏆' : r.accuracy >= 0.6 ? '📖' : '⚔️';
    final title = _isPerfect ? 'Mükemmel!'
        : r.accuracy >= 0.6 ? 'İyi iş!'
        : 'Devam et!';
    final subtitle = _isPerfect
        ? 'Tüm cümleler doğru — sınava hazırsın'
        : '${r.correctCount} / ${r.totalCount} doğru cevap';

    return Column(
      children: [
        Text(emoji, style: const TextStyle(fontSize: 52)),
        const SizedBox(height: 10),
        Text(title, style: AppTextStyles.display(26, weight: FontWeight.w700)),
        const SizedBox(height: 4),
        Text(subtitle,
            style: AppTextStyles.body(14, color: AppColors.muted),
            textAlign: TextAlign.center),
        const SizedBox(height: 8),
        Text(
          '${r.set.department.label} · Cümle İnşa Modu',
          style: AppTextStyles.body(12, color: AppColors.dim),
        ),
      ],
    );
  }

  // ─── Sınav hazırlık puanı çubuğu ─────────────────────────────────────────
  Widget _buildScoreCard() {
    const maxPoints = 250; // 5 soru × 5 puan × 10 = maks 250
    final pct = (r.examReadinessPoints / maxPoints).clamp(0.0, 1.0);

    return SurfaceCard(
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.school_outlined, size: 16, color: _deptColor),
              const SizedBox(width: 7),
              Text('SINAV HAZIRLIK PUANI',
                  style: AppTextStyles.label(10, color: _deptColor)),
              const Spacer(),
              AnimatedBuilder(
                animation: _scoreAnim,
                builder: (_, __) => Text(
                  '${(r.examReadinessPoints * _scoreAnim.value).round()}',
                  style: AppTextStyles.mono(22,
                      color: _deptColor, weight: FontWeight.w700),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          AnimatedBuilder(
            animation: _scoreAnim,
            builder: (_, __) => AppProgressBar(
              value: pct * _scoreAnim.value,
              color: _deptColor,
              height: 8,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            _scoreLabel(pct),
            style: AppTextStyles.body(12, color: AppColors.muted),
          ),
        ],
      ),
    );
  }

  String _scoreLabel(double pct) {
    if (pct >= 0.9) return 'Bu temaya çok hazırsın — Boss\'a geçebilirsin';
    if (pct >= 0.6) return 'İyi ilerliyorsun, birkaç cümle daha yap';
    return 'Bu temayı tekrarla, cümle modunu yeniden dene';
  }

  // ─── İstatistik satırı ───────────────────────────────────────────────────
  Widget _buildStatsRow() {
    final mins = r.timeSpent.inMinutes;
    final secs = r.timeSpent.inSeconds % 60;
    final timeStr = mins > 0 ? '${mins}d ${secs}s' : '${secs}s';

    return Row(
      children: [
        _MiniStat(
          value: '${(r.accuracy * 100).round()}%',
          label: 'Doğruluk',
          color: r.accuracy >= 0.8 ? AppColors.saglik : AppColors.sosyal,
        ),
        const SizedBox(width: 10),
        _MiniStat(
          value: '+${r.xpEarned}',
          label: 'XP kazanıldı',
          color: _deptColor,
        ),
        const SizedBox(width: 10),
        _MiniStat(
          value: timeStr,
          label: 'Süre',
          color: AppColors.muted,
        ),
      ],
    );
  }

  // ─── Yanlış soruları gözden geçir ────────────────────────────────────────
  Widget _buildWrongReview() {
    return SurfaceCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.refresh_rounded, size: 15, color: AppColors.danger),
              const SizedBox(width: 7),
              Text('TEKRAR GEREKEN SORULAR',
                  style: AppTextStyles.label(10, color: AppColors.danger)),
            ],
          ),
          const SizedBox(height: 12),
          ...widget.result.wrongQuestions.map((q) => Container(
            padding: const EdgeInsets.symmetric(vertical: 10),
            decoration: const BoxDecoration(
              border: Border(
                  bottom: BorderSide(color: AppColors.border)),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        q.targetWord.word.toLowerCase(),
                        style: AppTextStyles.display(14,
                            weight: FontWeight.w600),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        _questionPreview(q),
                        style: AppTextStyles.body(12, color: AppColors.muted),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: AppColors.dangerDim,
                    borderRadius: AppRadius.smBR,
                  ),
                  child: Text(
                    q.options[q.correctIndex],
                    style: AppTextStyles.mono(11,
                        color: AppColors.danger, weight: FontWeight.w600),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          )),
        ],
      ),
    );
  }

  String _questionPreview(SentenceQuestion q) {
    if (q.type == SentenceQuestionType.fillBlank) {
      return '${q.sentenceBefore.trim()} _____ ${q.sentenceAfter.trim()}'
          .substring(0, 60.clamp(0,
          ('${q.sentenceBefore.trim()} _____ ${q.sentenceAfter.trim()}').length));
    }
    if (q.type == SentenceQuestionType.wordInContext) {
      return '"${q.underlinedWord}" — bağlamdan anlam';
    }
    return 'Doğru kullanımı bul';
  }

  // ─── Deneme sınavı kilidi ─────────────────────────────────────────────────
  Widget _buildMiniExamUnlock() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.sosyalDim,
        borderRadius: AppRadius.lgBR,
        border: Border.all(color: AppColors.sosyal.withOpacity(0.5)),
      ),
      child: Row(
        children: [
          const Text('🔓', style: TextStyle(fontSize: 28)),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Mini deneme sınavı açıldı!',
                    style: AppTextStyles.display(15,
                        color: AppColors.sosyal, weight: FontWeight.w600)),
                const SizedBox(height: 3),
                Text(
                  '5 cümleyi tam doğru yaptın — gerçek YÖKDİL formatında '
                  'mini sınavı başlat.',
                  style: AppTextStyles.body(12, color: AppColors.muted),
                ),
                const SizedBox(height: 10),
                ElevatedButton(
                  onPressed: widget.onStartMiniExam,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.sosyal,
                    foregroundColor: AppColors.bg,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 10),
                    shape: const RoundedRectangleBorder(
                        borderRadius: AppRadius.smBR),
                    elevation: 0,
                  ),
                  child: Text('Mini sınavı başlat →',
                      style: AppTextStyles.display(13,
                          color: AppColors.bg, weight: FontWeight.w600)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ─── Ana butonlar ─────────────────────────────────────────────────────────
  Widget _buildButtons() {
    return Column(
      children: [
        PrimaryButton(
          label: 'Ana sayfaya dön',
          onTap: widget.onHome,
          color: _deptColor,
        ),
        const SizedBox(height: 8),
        GhostButton(label: 'Tekrar oyna', onTap: widget.onReplay),
      ],
    );
  }
}

// ─── Mini İstatistik Kartı ───────────────────────────────────────────────────
class _MiniStat extends StatelessWidget {
  final String value;
  final String label;
  final Color color;

  const _MiniStat(
      {required this.value, required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: AppColors.bg3,
          borderRadius: AppRadius.mdBR,
          border: Border.all(color: AppColors.border2),
        ),
        child: Column(
          children: [
            Text(value,
                style: AppTextStyles.display(20,
                    color: color, weight: FontWeight.w700)),
            const SizedBox(height: 3),
            Text(label,
                style: AppTextStyles.body(10, color: AppColors.muted),
                textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
}
