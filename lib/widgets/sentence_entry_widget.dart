import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../models/models.dart';
import '../models/sentence_model.dart';
import '../widgets/shared_widgets.dart';

// ═══════════════════════════════════════════════════════════════════════════════
// CÜMLE MOD GİRİŞ KARTI — Ana sayfada veya quiz sonrasında gösterilir
// ═══════════════════════════════════════════════════════════════════════════════
class SentenceModeEntryCard extends StatelessWidget {
  final Department department;
  final bool isUnlocked;     // çoktan seçmelide en az 3 doğru yapıldıysa açık
  final VoidCallback onTap;

  const SentenceModeEntryCard({
    super.key,
    required this.department,
    required this.isUnlocked,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = isUnlocked ? deptColor(department) : AppColors.dim;
    final dim   = isUnlocked ? deptDimColor(department) : AppColors.border;

    return GestureDetector(
      onTap: isUnlocked ? onTap : null,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.bg3,
          borderRadius: AppRadius.lgBR,
          border: Border.all(
            color: isUnlocked ? color.withOpacity(0.35) : AppColors.border,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 44, height: 44,
              decoration: BoxDecoration(color: dim, borderRadius: AppRadius.smBR),
              child: Icon(
                isUnlocked ? Icons.edit_note_rounded : Icons.lock_outline_rounded,
                color: color, size: 22,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text('Cümle İnşa Modu',
                          style: AppTextStyles.display(14,
                              weight: FontWeight.w600,
                              color: isUnlocked ? AppColors.text : AppColors.dim)),
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 7, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppColors.sosyal.withOpacity(0.15),
                          borderRadius: AppRadius.smBR,
                        ),
                        child: Text('YÖKDİL format',
                            style: AppTextStyles.mono(9,
                                color: AppColors.sosyal, weight: FontWeight.w600)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 3),
                  Text(
                    isUnlocked
                        ? 'Gerçek sınav cümleleriyle pratik yap'
                        : 'Önce 3 kelimeyi doğru yanıtla',
                    style: AppTextStyles.body(12,
                        color: isUnlocked ? AppColors.muted : AppColors.dim),
                  ),
                ],
              ),
            ),
            Icon(
              isUnlocked
                  ? Icons.arrow_forward_ios_rounded
                  : Icons.lock_outline_rounded,
              size: 16, color: color,
            ),
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// ENTEGRASYON NOTLARI — main.dart'a eklenecekler
// ═══════════════════════════════════════════════════════════════════════════════
//
// ── 1. AppPage enum'a ekle ────────────────────────────────────────────────────
//
//   enum AppPage {
//     splash, onboarding, home, map, quiz, boss, chest,
//     result, progress, gameOver,
//     sentenceBuild,   // ← yeni
//     sentenceResult,  // ← yeni
//   }
//
// ── 2. State alanları ekle ────────────────────────────────────────────────────
//
//   SentenceSessionResult? _sentenceResult;
//   bool _sentenceModeUnlocked = false; // quiz'de 3+ doğru yapılınca true
//
// ── 3. Quiz onComplete callback'ine ekle ────────────────────────────────────
//
//   onComplete: (result) {
//     setState(() {
//       _lastResult = result;
//       _totalXP += result.xpEarned;
//       _map.unlockNext();
//       // Cümle modu kilidi: 3+ doğru cevap → cümle modu açık
//       if (result.correctAnswers >= 3) _sentenceModeUnlocked = true;
//     });
//     _go(AppPage.result);
//   },
//
// ── 4. _buildPage() içine sentenceBuild ve sentenceResult ekle ──────────────
//
//   case AppPage.sentenceBuild:
//     return SentenceBuildScreen(
//       key: const ValueKey('sentenceBuild'),
//       sentenceSet: SentenceData.forDepartment(_dept),
//       onComplete: (result) {
//         setState(() => _sentenceResult = result);
//         _go(AppPage.sentenceResult);
//       },
//       onBack: () => _go(AppPage.result),
//     );
//
//   case AppPage.sentenceResult:
//     return SentenceResultScreen(
//       key: const ValueKey('sentenceResult'),
//       result: _sentenceResult!,
//       onReplay: () => _go(AppPage.sentenceBuild),
//       onHome:   () => _go(AppPage.map),
//       onStartMiniExam: _sentenceResult?.correctCount == _sentenceResult?.totalCount
//           ? () => _go(AppPage.map) // mini sınav sayfası eklenince buraya bağla
//           : null,
//     );
//
// ── 5. ResultScreen'e Cümle Modu butonu ekle ─────────────────────────────────
//
// result_progress_screens.dart → ResultScreen build() içinde, CTA butonlarının
// altına:
//
//   SentenceModeEntryCard(
//     department: result.department,
//     isUnlocked: sentenceModeUnlocked, // parent'tan parametre olarak geç
//     onTap: onSentenceMode,            // callback ekle
//   ),
//
// ── 6. İmportlar ─────────────────────────────────────────────────────────────
//
//   import 'models/sentence_model.dart';
//   import 'screens/game/sentence_build_screen.dart';
//   import 'screens/game/sentence_result_screen.dart';
//   import 'widgets/sentence_entry_widget.dart';
//
// ─────────────────────────────────────────────────────────────────────────────
