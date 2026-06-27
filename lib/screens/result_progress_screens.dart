import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../models/models.dart';
import '../widgets/shared_widgets.dart';
import 'home_screen.dart' show AppBottomNav;

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
  final Function(int) onTabSelect;

  const ProgressScreen({super.key, required this.wordCounts, required this.onTabSelect});

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
      bottomNavigationBar: AppBottomNav(currentIndex: 1, onTap: onTabSelect),
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

// ═══════════════════════════════════════════════════════════════════════════════
// SIRALAMA EKRANI
// ═══════════════════════════════════════════════════════════════════════════════
class LeaderboardScreen extends StatelessWidget {
  final Function(int) onTabSelect;
  const LeaderboardScreen({super.key, required this.onTabSelect});

  static const _entries = [
    ('👑', 'Ahmet Y.', 4820, 'Fen'),
    ('🥈', 'Elif K.',  3910, 'Sağlık'),
    ('🥉', 'Mehmet D.', 3540, 'Sosyal'),
    ('4', 'Zeynep A.', 2980, 'Fen'),
    ('5', 'Can B.',    2710, 'Fen'),
    ('6', 'Selin T.',  2490, 'Sağlık'),
    ('7', 'Burak O.',  2200, 'Sosyal'),
    ('8', 'Ayşe M.',   1960, 'Fen'),
    ('9', 'Kaan S.',   1720, 'Sağlık'),
    ('10', 'İrem C.',   1500, 'Sosyal'),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(22, 28, 22, 4),
              child: Text('Sıralama', style: AppTextStyles.display(22, weight: FontWeight.w700)),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(22, 0, 22, 20),
              child: Text('Bu hafta en çok XP kazananlar', style: AppTextStyles.body(13, color: AppColors.muted)),
            ),
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: _entries.length,
                itemBuilder: (ctx, i) {
                  final (rank, name, xp, dept) = _entries[i];
                  final isTop3 = i < 3;
                  return Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: isTop3 ? AppColors.bg3 : AppColors.bg2,
                      borderRadius: AppRadius.mdBR,
                      border: Border.all(
                        color: isTop3 ? AppColors.fen.withValues(alpha: 0.25) : AppColors.border,
                      ),
                    ),
                    child: Row(
                      children: [
                        SizedBox(
                          width: 36,
                          child: Text(rank, style: TextStyle(fontSize: isTop3 ? 20 : 14, color: AppColors.muted)),
                        ),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(name, style: AppTextStyles.display(14, weight: FontWeight.w600)),
                              Text(dept, style: AppTextStyles.body(11, color: AppColors.muted)),
                            ],
                          ),
                        ),
                        Text('$xp XP', style: AppTextStyles.mono(13, color: AppColors.fen, weight: FontWeight.w600)),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: AppBottomNav(currentIndex: 2, onTap: onTabSelect),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// ROZETLER EKRANI
// ═══════════════════════════════════════════════════════════════════════════════
class BadgesScreen extends StatelessWidget {
  final Function(int) onTabSelect;
  const BadgesScreen({super.key, required this.onTabSelect});

  static const _badges = [
    ('🔥', 'İlk Adım', '10 kelime öğren', true),
    ('⚔️', 'İlk Zafer', 'İlk boss\'u yen', true),
    ('💰', 'Hazine Avcısı', '3 hazine aç', false),
    ('🗺️', 'Kaşif', 'Haritayı %50 tamamla', false),
    ('👹', 'Boss Katili', '5 boss\'u yen', false),
    ('📚', 'Kelime Ustası', '100 kelime öğren', false),
    ('🏆', 'Şampiyon', 'Tüm bölümleri tamamla', false),
    ('⚡', 'Combo Ustası', 'x5 combo yap', false),
    ('🌟', 'Yıldız', '7 gün üst üste oyna', false),
    ('💎', 'Elmas', 'Tüm rozetleri kazan', false),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(22, 28, 22, 4),
              child: Text('Rozetler', style: AppTextStyles.display(22, weight: FontWeight.w700)),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(22, 0, 22, 20),
              child: Text('${_badges.where((b) => b.$4).length} / ${_badges.length} kazanıldı',
                  style: AppTextStyles.body(13, color: AppColors.muted)),
            ),
            Expanded(
              child: GridView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 10,
                  mainAxisSpacing: 10,
                  childAspectRatio: 1.4,
                ),
                itemCount: _badges.length,
                itemBuilder: (ctx, i) {
                  final (emoji, title, desc, earned) = _badges[i];
                  return Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: earned ? AppColors.bg3 : AppColors.bg2,
                      borderRadius: AppRadius.mdBR,
                      border: Border.all(
                        color: earned
                            ? AppColors.sosyal.withValues(alpha: 0.4)
                            : AppColors.border,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(emoji,
                            style: TextStyle(
                              fontSize: 24,
                              color: earned ? null : const Color(0xFF333333),
                            )),
                        const SizedBox(height: 6),
                        Text(title,
                            style: AppTextStyles.display(12,
                                weight: FontWeight.w600,
                                color: earned ? AppColors.text : AppColors.muted)),
                        Text(desc,
                            style: AppTextStyles.body(10, color: AppColors.dim),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: AppBottomNav(currentIndex: 3, onTap: onTabSelect),
    );
  }
}
