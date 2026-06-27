import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../models/models.dart';
import '../widgets/shared_widgets.dart';

class HomeScreen extends StatelessWidget {
  final VoidCallback onStartQuiz;
  final Function(Department) onSelectDept;
  final Map<Department, int> wordCounts;

  const HomeScreen({
    super.key,
    required this.onStartQuiz,
    required this.onSelectDept,
    required this.wordCounts,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            // ── Header ─────────────────────────────────────────────────────
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(22, 24, 22, 0),
                child: Row(
                  children: [
                    RichText(
                      text: TextSpan(children: [
                        TextSpan(text: 'YÖK', style: AppTextStyles.display(20)),
                        TextSpan(text: 'DİL', style: AppTextStyles.display(20, color: AppColors.fen)),
                      ]),
                    ),
                    const Spacer(),
                    StatPill(value: '0', icon: Icons.local_fire_department_rounded, iconColor: AppColors.sosyal),
                    const SizedBox(width: 8),
                    StatPill(value: '0', icon: Icons.star_rounded, iconColor: AppColors.fen),
                  ],
                ),
              ),
            ),

            // ── Günlük Görev Kartı ─────────────────────────────────────────
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                child: _DailyMissionCard(onTap: onStartQuiz),
              ),
            ),

            // ── Bölümler Başlığı ───────────────────────────────────────────
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(22, 24, 22, 12),
                child: Text('BÖLÜMLER', style: AppTextStyles.label(11)),
              ),
            ),

            // ── Bölüm Listesi ──────────────────────────────────────────────
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  DeptListCard(
                    dept: Department.fen,
                    learned: 0,
                    total: wordCounts[Department.fen] ?? 0,
                    onTap: () => onSelectDept(Department.fen),
                  ),
                  const SizedBox(height: 10),
                  DeptListCard(
                    dept: Department.saglik,
                    learned: 0,
                    total: wordCounts[Department.saglik] ?? 0,
                    onTap: () => onSelectDept(Department.saglik),
                  ),
                  const SizedBox(height: 10),
                  DeptListCard(
                    dept: Department.sosyal,
                    learned: 0,
                    total: wordCounts[Department.sosyal] ?? 0,
                    onTap: () => onSelectDept(Department.sosyal),
                  ),
                ]),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: _AppBottomNav(currentIndex: 0),
    );
  }
}

// ─── Günlük Görev Kartı ───────────────────────────────────────────────────────
class _DailyMissionCard extends StatelessWidget {
  final VoidCallback onTap;
  const _DailyMissionCard({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.bg3,
        borderRadius: AppRadius.xlBR,
        border: Border.all(color: AppColors.border2),
      ),
      child: Stack(
        children: [
          Positioned(
            top: -30, right: -30,
            child: Container(
              width: 100, height: 100,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.fenGlow,
              ),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('BUGÜNKÜ GÖREV', style: AppTextStyles.label(10, color: AppColors.fen)),
              const SizedBox(height: 8),
              Text('Fen · Araştırma Yöntemleri',
                  style: AppTextStyles.display(18, weight: FontWeight.w600)),
              const SizedBox(height: 4),
              Text('hypothesis, variable, replicate',
                  style: AppTextStyles.body(13, color: AppColors.muted)),
              const SizedBox(height: 14),
              AppProgressBar(value: 0.0),
              const SizedBox(height: 5),
              Text('0 / 10 tamamlandı',
                  style: AppTextStyles.mono(11, color: AppColors.muted)),
              const SizedBox(height: 16),
              PrimaryButton(label: 'Başla →', onTap: onTap),
            ],
          ),
        ],
      ),
    );
  }
}

// ─── Alt Navigasyon ───────────────────────────────────────────────────────────
class _AppBottomNav extends StatelessWidget {
  final int currentIndex;
  const _AppBottomNav({required this.currentIndex});

  @override
  Widget build(BuildContext context) {
    const items = [
      BottomNavigationBarItem(icon: Icon(Icons.home_outlined),      activeIcon: Icon(Icons.home_rounded),      label: 'Ana sayfa'),
      BottomNavigationBarItem(icon: Icon(Icons.bar_chart_outlined),  activeIcon: Icon(Icons.bar_chart_rounded),  label: 'İlerleme'),
      BottomNavigationBarItem(icon: Icon(Icons.people_outline),     activeIcon: Icon(Icons.people_rounded),    label: 'Sıralama'),
      BottomNavigationBarItem(icon: Icon(Icons.emoji_events_outlined), activeIcon: Icon(Icons.emoji_events_rounded), label: 'Rozetler'),
    ];

    return Container(
      decoration: const BoxDecoration(
        color: AppColors.bg2,
        border: Border(top: BorderSide(color: AppColors.border)),
      ),
      child: BottomNavigationBar(
        currentIndex: currentIndex,
        items: items,
        backgroundColor: Colors.transparent,
        selectedItemColor: AppColors.fen,
        unselectedItemColor: AppColors.dim,
        type: BottomNavigationBarType.fixed,
        elevation: 0,
        selectedLabelStyle: AppTextStyles.body(10, weight: FontWeight.w500),
        unselectedLabelStyle: AppTextStyles.body(10),
      ),
    );
  }
}
