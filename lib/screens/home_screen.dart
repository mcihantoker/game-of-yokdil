import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../models/models.dart';
import '../widgets/shared_widgets.dart';

class HomeScreen extends StatelessWidget {
  final Function(Department) onSelectDept;
  final Map<Department, int> wordCounts;

  const HomeScreen({
    super.key,
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

            // ── Günlük Görev Başlığı ───────────────────────────────────────
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(22, 24, 22, 12),
                child: Text('GÜNLÜK GÖREVLER', style: AppTextStyles.label(11)),
              ),
            ),

            // ── 3 Bölüm Görevi ─────────────────────────────────────────────
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 0),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  _DailyMissionCard(
                    dept: Department.fen,
                    total: wordCounts[Department.fen] ?? 0,
                    onTap: () => onSelectDept(Department.fen),
                  ),
                  const SizedBox(height: 10),
                  _DailyMissionCard(
                    dept: Department.saglik,
                    total: wordCounts[Department.saglik] ?? 0,
                    onTap: () => onSelectDept(Department.saglik),
                  ),
                  const SizedBox(height: 10),
                  _DailyMissionCard(
                    dept: Department.sosyal,
                    total: wordCounts[Department.sosyal] ?? 0,
                    onTap: () => onSelectDept(Department.sosyal),
                  ),
                ]),
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

// ─── Günlük Görev Kartı (bölüme göre) ────────────────────────────────────────
class _DailyMissionCard extends StatelessWidget {
  final Department dept;
  final int total;
  final VoidCallback onTap;

  const _DailyMissionCard({
    required this.dept,
    required this.total,
    required this.onTap,
  });

  Color get _color => deptColor(dept);
  Color get _glowColor {
    switch (dept) {
      case Department.fen:    return AppColors.fenGlow;
      case Department.saglik: return const Color(0x404DD0A6);
      case Department.sosyal: return const Color(0x40F5A623);
    }
  }

  String get _subtitle {
    switch (dept) {
      case Department.fen:    return 'hypothesis, variable, replicate';
      case Department.saglik: return 'diagnosis, chronic, pathogen';
      case Department.sosyal: return 'paradigm, empirical, methodology';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.bg3,
        borderRadius: AppRadius.xlBR,
        border: Border.all(color: AppColors.border2),
      ),
      child: Stack(
        children: [
          Positioned(
            top: -24, right: -24,
            child: Container(
              width: 80, height: 80,
              decoration: BoxDecoration(shape: BoxShape.circle, color: _glowColor),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('BUGÜNKÜ GÖREV', style: AppTextStyles.label(10, color: _color)),
              const SizedBox(height: 6),
              Text(dept.label, style: AppTextStyles.display(17, weight: FontWeight.w600)),
              const SizedBox(height: 3),
              Text(_subtitle, style: AppTextStyles.body(12, color: AppColors.muted)),
              const SizedBox(height: 12),
              AppProgressBar(value: 0.0, color: _color),
              const SizedBox(height: 4),
              Text('0 / 10 tamamlandı', style: AppTextStyles.mono(11, color: AppColors.muted)),
              const SizedBox(height: 14),
              PrimaryButton(label: 'Başla →', onTap: onTap, color: _color),
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
      BottomNavigationBarItem(icon: Icon(Icons.home_outlined),        activeIcon: Icon(Icons.home_rounded),        label: 'Ana sayfa'),
      BottomNavigationBarItem(icon: Icon(Icons.bar_chart_outlined),   activeIcon: Icon(Icons.bar_chart_rounded),   label: 'İlerleme'),
      BottomNavigationBarItem(icon: Icon(Icons.people_outline),       activeIcon: Icon(Icons.people_rounded),      label: 'Sıralama'),
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
