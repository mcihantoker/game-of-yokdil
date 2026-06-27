import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../models/models.dart';
import '../widgets/shared_widgets.dart';

// ═══════════════════════════════════════════════════════════════════════════════
// SONUÇ EKRANI
// ═══════════════════════════════════════════════════════════════════════════════
class ResultScreen extends StatelessWidget {
  final SessionResult result;
  final VoidCallback onHome;
  final VoidCallback onReplay;

  const ResultScreen({
    super.key,
    required this.result,
    required this.onHome,
    required this.onReplay,
  });

  @override
  Widget build(BuildContext context) {
    final dept  = result.department;
    final color = deptColor(dept);
    final acc   = result.accuracy;
    final xp    = result.xpEarned;

    final emoji = acc >= 0.8 ? '🎉' : acc >= 0.6 ? '👍' : '💪';
    final title = acc >= 0.8 ? 'Mükemmel!' : acc >= 0.6 ? 'İyi iş!' : 'Devam et!';

    return Scaffold(
      backgroundColor: AppColors.bg,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 28, 20, 28),
          child: Column(
            children: [
              Text(emoji, style: const TextStyle(fontSize: 52)),
              const SizedBox(height: 10),
              Text(title, style: AppTextStyles.display(26, weight: FontWeight.w700)),
              const SizedBox(height: 4),
              Text(
                '${dept.label} · ${result.theme}',
                style: AppTextStyles.body(14, color: AppColors.muted),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),

              Row(
                children: [
                  _StatCard(value: '+$xp', label: 'XP kazanıldı', color: color),
                  const SizedBox(width: 10),
                  _StatCard(
                    value: '${(acc * 100).round()}%',
                    label: 'Doğruluk',
                    color: AppColors.saglik,
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  _StatCard(value: '🔥 0', label: 'Günlük seri', color: AppColors.sosyal),
                  const SizedBox(width: 10),
                  _StatCard(
                    value: '${result.correctAnswers}/${result.totalQuestions}',
                    label: 'Doğru/Toplam',
                    color: AppColors.text,
                  ),
                ],
              ),
              const SizedBox(height: 20),

              SurfaceCard(
                padding: const EdgeInsets.all(16),
                borderRadius: AppRadius.mdBR,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('ÖĞRENİLEN KELİMELER',
                        style: AppTextStyles.label(11, color: color)),
                    const SizedBox(height: 12),
                    ...result.learnedWords.map((w) => _LearnedWordRow(word: w)),
                    if (result.learnedWords.isEmpty)
                      Text('Bu turda kelime öğrenilmedi.',
                          style: AppTextStyles.body(13, color: AppColors.muted)),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              PrimaryButton(label: 'Ana sayfaya dön', onTap: onHome, color: color),
              const SizedBox(height: 8),
              GhostButton(label: 'Tekrar oyna', onTap: onReplay),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String value;
  final String label;
  final Color color;

  const _StatCard({required this.value, required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: AppColors.bg3,
          borderRadius: AppRadius.mdBR,
          border: Border.all(color: AppColors.border2),
        ),
        child: Column(
          children: [
            Text(value, style: AppTextStyles.display(22, color: color, weight: FontWeight.w700)),
            const SizedBox(height: 2),
            Text(label, style: AppTextStyles.body(11, color: AppColors.muted)),
          ],
        ),
      ),
    );
  }
}

class _LearnedWordRow extends StatelessWidget {
  final Word word;
  const _LearnedWordRow({required this.word});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: AppColors.border)),
      ),
      child: Row(
        children: [
          Text(word.word.toLowerCase(),
              style: AppTextStyles.display(14, weight: FontWeight.w600)),
          const Spacer(),
          Text(word.trMeaning, style: AppTextStyles.body(13, color: AppColors.muted)),
        ],
      ),
    );
  }
}


// ═══════════════════════════════════════════════════════════════════════════════
// İLERLEME EKRANI
// ═══════════════════════════════════════════════════════════════════════════════
class ProgressScreen extends StatelessWidget {
  final Map<Department, int> wordCounts;

  const ProgressScreen({super.key, required this.wordCounts});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(22, 28, 22, 20),
                child: Text('İlerleme', style: AppTextStyles.display(22, weight: FontWeight.w700)),
              ),
            ),

            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 0),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  _DeptProgressCard(
                    dept: Department.fen,
                    learned: 0,
                    total: wordCounts[Department.fen] ?? 0,
                    themes: const ['Araştırma', 'Biyoloji', 'Kimya', 'Fizik'],
                    themesDone: const [false, false, false, false],
                  ),
                  const SizedBox(height: 12),
                  _DeptProgressCard(
                    dept: Department.saglik,
                    learned: 0,
                    total: wordCounts[Department.saglik] ?? 0,
                    themes: const ['Klinik', 'Farmakoloji', 'Epidemiyoloji'],
                    themesDone: const [false, false, false],
                  ),
                  const SizedBox(height: 12),
                  _DeptProgressCard(
                    dept: Department.sosyal,
                    learned: 0,
                    total: wordCounts[Department.sosyal] ?? 0,
                    themes: const ['Metodoloji', 'Sosyoloji', 'Ekonomi'],
                    themesDone: const [false, false, false],
                  ),
                  const SizedBox(height: 24),
                ]),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: _ProgressBottomNav(),
    );
  }
}

class _DeptProgressCard extends StatelessWidget {
  final Department dept;
  final int learned;
  final int total;
  final List<String> themes;
  final List<bool> themesDone;

  const _DeptProgressCard({
    required this.dept,
    required this.learned,
    required this.total,
    required this.themes,
    required this.themesDone,
  });

  @override
  Widget build(BuildContext context) {
    final color = deptColor(dept);
    final dim   = deptDimColor(dept);
    final pct   = total == 0 ? 0.0 : learned / total;

    return SurfaceCard(
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(width: 10, height: 10,
                  decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
              const SizedBox(width: 8),
              Expanded(child: Text(dept.label,
                  style: AppTextStyles.display(15, weight: FontWeight.w600))),
              Text('${(pct * 100).round()}%',
                  style: AppTextStyles.mono(13, color: color, weight: FontWeight.w600)),
            ],
          ),
          const SizedBox(height: 10),
          AppProgressBar(value: pct, color: color, height: 4),
          const SizedBox(height: 4),
          Text('$learned / $total kelime', style: AppTextStyles.body(11, color: AppColors.muted)),
          const SizedBox(height: 10),
          Wrap(
            spacing: 6, runSpacing: 6,
            children: List.generate(themes.length, (i) {
              final done = i < themesDone.length && themesDone[i];
              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: done ? dim : AppColors.border,
                  borderRadius: AppRadius.smBR,
                ),
                child: Text(
                  themes[i],
                  style: AppTextStyles.body(11,
                      color: done ? color : AppColors.muted,
                      weight: FontWeight.w500),
                ),
              );
            }),
          ),
        ],
      ),
    );
  }
}

class _ProgressBottomNav extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.bg2,
        border: Border(top: BorderSide(color: AppColors.border)),
      ),
      child: BottomNavigationBar(
        currentIndex: 1,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home_outlined),     label: 'Ana sayfa'),
          BottomNavigationBarItem(icon: Icon(Icons.bar_chart_rounded),  label: 'İlerleme'),
          BottomNavigationBarItem(icon: Icon(Icons.people_outline),    label: 'Sıralama'),
          BottomNavigationBarItem(icon: Icon(Icons.emoji_events_outlined), label: 'Rozetler'),
        ],
        backgroundColor: Colors.transparent,
        selectedItemColor: AppColors.fen,
        unselectedItemColor: AppColors.dim,
        type: BottomNavigationBarType.fixed,
        elevation: 0,
      ),
    );
  }
}
