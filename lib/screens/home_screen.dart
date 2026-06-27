import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../models/models.dart';
import '../widgets/shared_widgets.dart';
import '../widgets/event_widgets.dart';
import '../widgets/paywall_sheet.dart';
import '../services/event_service.dart';

class HomeScreen extends StatelessWidget {
  final Function(Department) onSelectDept;
  final Map<Department, int> wordCounts;
  final Map<Department, int> learnedCounts;
  final Map<Department, int> mapOpenCounts;
  final int gold;
  final int streak;
  final Function(int) onTabSelect;
  final VoidCallback onEventTap;
  final bool isPremium;
  final Department ownedDept;

  const HomeScreen({
    super.key,
    required this.onSelectDept,
    required this.wordCounts,
    this.learnedCounts = const {},
    this.mapOpenCounts = const {},
    this.gold = 0,
    this.streak = 0,
    required this.onTabSelect,
    required this.onEventTap,
    this.isPremium = false,
    this.ownedDept = Department.fen,
  });

  bool _isLocked(Department dept) => !isPremium && dept != ownedDept;

  void _onDeptTap(BuildContext context, Department dept) {
    if (_isLocked(dept)) {
      showPaywall(context, reason: '${dept.label} bölümüne erişmek için premium gerekli.');
    } else {
      onSelectDept(dept);
    }
  }

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
                    Image.asset(
                      'assets/logo.png',
                      height: 28,
                      filterQuality: FilterQuality.high,
                    ),
                    const Spacer(),
                    StatPill(value: streak.toString(), icon: Icons.local_fire_department_rounded, iconColor: AppColors.sosyal),
                    const SizedBox(width: 8),
                    StatPill(value: gold.toString(), icon: Icons.monetization_on_rounded, iconColor: AppColors.sosyal),
                  ],
                ),
              ),
            ),

            // ── Günlük Olay Kartı ─────────────────────────────────────────
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(0, 20, 0, 0),
                child: DailyEventCard(
                  event: EventService.instance.todaysEvent,
                  onTap: onEventTap,
                ),
              ),
            ),

            // ── Günlük Görev Başlığı ───────────────────────────────────────
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(22, 8, 22, 12),
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
                    openCells: mapOpenCounts[Department.fen] ?? 0,
                    isLocked: _isLocked(Department.fen),
                    onTap: () => _onDeptTap(context, Department.fen),
                  ),
                  const SizedBox(height: 10),
                  _DailyMissionCard(
                    dept: Department.saglik,
                    openCells: mapOpenCounts[Department.saglik] ?? 0,
                    isLocked: _isLocked(Department.saglik),
                    onTap: () => _onDeptTap(context, Department.saglik),
                  ),
                  const SizedBox(height: 10),
                  _DailyMissionCard(
                    dept: Department.sosyal,
                    openCells: mapOpenCounts[Department.sosyal] ?? 0,
                    isLocked: _isLocked(Department.sosyal),
                    onTap: () => _onDeptTap(context, Department.sosyal),
                  ),
                ]),
              ),
            ),

            // ── Reklam Alanı (free) ────────────────────────────────────────
            if (!isPremium)
              SliverToBoxAdapter(
                child: _AdBanner(),
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
                  _buildDeptCard(context, Department.fen),
                  const SizedBox(height: 10),
                  _buildDeptCard(context, Department.saglik),
                  const SizedBox(height: 10),
                  _buildDeptCard(context, Department.sosyal),
                ]),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: AppBottomNav(currentIndex: 0, onTap: onTabSelect),
    );
  }

  Widget _buildDeptCard(BuildContext context, Department dept) {
    final locked = _isLocked(dept);
    final card = DeptListCard(
      dept: dept,
      learned: locked ? 0 : (learnedCounts[dept] ?? 0),
      total: wordCounts[dept] ?? 0,
      onTap: () => _onDeptTap(context, dept),
    );
    if (!locked) return card;
    return Stack(
      children: [
        AbsorbPointer(child: card),
        Positioned.fill(
          child: GestureDetector(
            onTap: () => _onDeptTap(context, dept),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.55),
                borderRadius: AppRadius.mdBR,
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.lock_rounded, color: Colors.white, size: 22),
                  const SizedBox(height: 4),
                  Text('Premium', style: AppTextStyles.label(11, color: Colors.white)),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _AdBanner extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(20, 12, 20, 0),
      height: 48,
      decoration: BoxDecoration(
        color: AppColors.bg3,
        borderRadius: AppRadius.mdBR,
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.ads_click_rounded, size: 13, color: AppColors.dim),
          const SizedBox(width: 6),
          Text('Reklam Alanı', style: AppTextStyles.body(11, color: AppColors.dim)),
        ],
      ),
    );
  }
}

// ─── Günlük Görev Kartı (bölüme göre) ────────────────────────────────────────
class _DailyMissionCard extends StatelessWidget {
  final Department dept;
  final int openCells;
  final VoidCallback onTap;
  final bool isLocked;

  const _DailyMissionCard({
    required this.dept,
    required this.openCells,
    required this.onTap,
    this.isLocked = false,
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
    return Stack(
      children: [
        Container(
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
                  AppProgressBar(value: openCells / 25, color: _color),
                  const SizedBox(height: 4),
                  Text('$openCells / 25 hücre açıldı', style: AppTextStyles.mono(11, color: AppColors.muted)),
                  const SizedBox(height: 14),
                  PrimaryButton(label: isLocked ? '🔒 Premium Gerekli' : 'Başla →', onTap: onTap, color: isLocked ? AppColors.muted : _color),
                ],
              ),
            ],
          ),
        ),
        if (isLocked)
          Positioned.fill(
            child: GestureDetector(
              onTap: onTap,
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.45),
                  borderRadius: AppRadius.xlBR,
                ),
              ),
            ),
          ),
      ],
    );
  }
}

// ─── Alt Navigasyon (paylaşımlı) ─────────────────────────────────────────────
class AppBottomNav extends StatelessWidget {
  final int currentIndex;
  final Function(int) onTap;
  const AppBottomNav({super.key, required this.currentIndex, required this.onTap});

  @override
  Widget build(BuildContext context) {
    const items = [
      BottomNavigationBarItem(icon: Icon(Icons.home_outlined),         activeIcon: Icon(Icons.home_rounded),         label: 'Ana sayfa'),
      BottomNavigationBarItem(icon: Icon(Icons.bar_chart_outlined),    activeIcon: Icon(Icons.bar_chart_rounded),    label: 'İlerleme'),
      BottomNavigationBarItem(icon: Icon(Icons.people_outline),        activeIcon: Icon(Icons.people_rounded),       label: 'Sıralama'),
      BottomNavigationBarItem(icon: Icon(Icons.emoji_events_outlined), activeIcon: Icon(Icons.emoji_events_rounded), label: 'Rozetler'),
      BottomNavigationBarItem(icon: Icon(Icons.person_outline),        activeIcon: Icon(Icons.person_rounded),       label: 'Profil'),
    ];

    return Container(
      decoration: const BoxDecoration(
        color: AppColors.bg2,
        border: Border(top: BorderSide(color: AppColors.border)),
      ),
      child: BottomNavigationBar(
        currentIndex: currentIndex,
        onTap: onTap,
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
