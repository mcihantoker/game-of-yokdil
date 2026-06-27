import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../../widgets/shared_widgets.dart';
import '../../models/models.dart';

// ═══════════════════════════════════════════════════════════════════════════════
// SPLASH EKRANI — logo animasyonlu giriş
// ═══════════════════════════════════════════════════════════════════════════════
class SplashScreen extends StatefulWidget {
  final VoidCallback onComplete;
  const SplashScreen({super.key, required this.onComplete});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _fadeIn;
  late Animation<double> _scale;
  late Animation<double> _taglineFade;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 1800));

    _fadeIn = CurvedAnimation(
      parent: _ctrl,
      curve: const Interval(0.0, 0.5, curve: Curves.easeOut),
    );
    _scale = Tween<double>(begin: 0.82, end: 1.0).animate(
      CurvedAnimation(parent: _ctrl, curve: const Interval(0.0, 0.6, curve: Curves.easeOutBack)),
    );
    _taglineFade = CurvedAnimation(
      parent: _ctrl,
      curve: const Interval(0.55, 1.0, curve: Curves.easeOut),
    );

    _ctrl.forward();

    // 2.8 saniye sonra geçiş
    Future.delayed(const Duration(milliseconds: 2800), widget.onComplete);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Logo
            ScaleTransition(
              scale: _scale,
              child: FadeTransition(
                opacity: _fadeIn,
                child: Image.asset(
                  'assets/logo.png',
                  width: 280,
                  filterQuality: FilterQuality.high,
                ),
              ),
            ),
            const SizedBox(height: 28),
            // Tagline
            FadeTransition(
              opacity: _taglineFade,
              child: Column(
                children: [
                  Text(
                    'YÖKDİL\'e hazırlan, krallığını kur',
                    style: AppTextStyles.body(14, color: AppColors.muted),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 32),
                  // Loading dots
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(3, (i) => _PulseDot(delay: i * 200)),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PulseDot extends StatefulWidget {
  final int delay;
  const _PulseDot({required this.delay});

  @override
  State<_PulseDot> createState() => _PulseDotState();
}

class _PulseDotState extends State<_PulseDot> with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 700));
    _anim = Tween<double>(begin: 0.3, end: 1.0).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut),
    );
    Future.delayed(Duration(milliseconds: widget.delay), () {
      if (mounted) _ctrl.repeat(reverse: true);
    });
  }

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: FadeTransition(
        opacity: _anim,
        child: Container(
          width: 6, height: 6,
          decoration: const BoxDecoration(color: AppColors.fen, shape: BoxShape.circle),
        ),
      ),
    );
  }
}


// ═══════════════════════════════════════════════════════════════════════════════
// ONBOARDING — bölüm seçim ekranı (ilk açılışta)
// ═══════════════════════════════════════════════════════════════════════════════
class OnboardingScreen extends StatefulWidget {
  final Function(Department) onSelect;
  const OnboardingScreen({super.key, required this.onSelect});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  Department? _selected;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 32, 24, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Logo küçük
              Image.asset('assets/logo.png', width: 140, filterQuality: FilterQuality.high),
              const SizedBox(height: 24),
              Text('Hangi bölümde\nsınava gireceksin?',
                  style: AppTextStyles.display(26, weight: FontWeight.w700)),
              const SizedBox(height: 8),
              Text('Sana özel kelime seti ve haritalar hazırlayalım.',
                  style: AppTextStyles.body(14, color: AppColors.muted)),
              const SizedBox(height: 28),

              // Bölüm seçim kartları
              _DeptSelectCard(
                dept: Department.fen,
                selected: _selected == Department.fen,
                onTap: () => setState(() => _selected = Department.fen),
                icon: Icons.science_outlined,
                examples: 'hypothesis · catalyst · variable',
              ),
              const SizedBox(height: 10),
              _DeptSelectCard(
                dept: Department.saglik,
                selected: _selected == Department.saglik,
                onTap: () => setState(() => _selected = Department.saglik),
                icon: Icons.monitor_heart_outlined,
                examples: 'diagnosis · chronic · pathogen',
              ),
              const SizedBox(height: 10),
              _DeptSelectCard(
                dept: Department.sosyal,
                selected: _selected == Department.sosyal,
                onTap: () => setState(() => _selected = Department.sosyal),
                icon: Icons.menu_book_outlined,
                examples: 'paradigm · empirical · discourse',
              ),

              const SizedBox(height: 28),
              AnimatedOpacity(
                opacity: _selected != null ? 1.0 : 0.3,
                duration: const Duration(milliseconds: 200),
                child: PrimaryButton(
                  label: 'Krallığını kur →',
                  onTap: _selected != null
                      ? () => widget.onSelect(_selected!)
                      : () {},
                  color: _selected != null ? deptColor(_selected!) : AppColors.dim,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DeptSelectCard extends StatelessWidget {
  final Department dept;
  final bool selected;
  final VoidCallback onTap;
  final IconData icon;
  final String examples;

  const _DeptSelectCard({
    required this.dept,
    required this.selected,
    required this.onTap,
    required this.icon,
    required this.examples,
  });

  @override
  Widget build(BuildContext context) {
    final color = deptColor(dept);
    final dim   = deptDimColor(dept);

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: selected ? dim : AppColors.bg3,
          borderRadius: AppRadius.lgBR,
          border: Border.all(
            color: selected ? color : AppColors.border2,
            width: selected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 44, height: 44,
              decoration: BoxDecoration(
                color: selected ? color.withValues(alpha: 0.2) : AppColors.bg2,
                borderRadius: AppRadius.smBR,
              ),
              child: Icon(icon, color: color, size: 22),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(dept.label,
                      style: AppTextStyles.display(15,
                          weight: FontWeight.w600,
                          color: selected ? color : AppColors.text)),
                  const SizedBox(height: 2),
                  Text(examples, style: AppTextStyles.body(12, color: AppColors.muted)),
                ],
              ),
            ),
            if (selected)
              Icon(Icons.check_circle_rounded, color: color, size: 22)
            else
              Icon(Icons.circle_outlined, color: AppColors.dim, size: 22),
          ],
        ),
      ),
    );
  }
}
