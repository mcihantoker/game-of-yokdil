import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../models/word.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 16),
              Text(
                'YÖKDİL Quest',
                style: theme.textTheme.headlineLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.primary,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Bölümünü seç ve çalışmaya başla',
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 40),
              _DeptCard(
                dept: Department.fen,
                label: 'Fen Bilimleri',
                subtitle: 'Kimya · Biyoloji · Fizik',
                icon: Icons.science,
                color: Colors.blue,
              ),
              const SizedBox(height: 16),
              _DeptCard(
                dept: Department.saglik,
                label: 'Sağlık Bilimleri',
                subtitle: 'Klinik · Farmakoloji · Epidemiyoloji',
                icon: Icons.local_hospital,
                color: Colors.green,
                locked: true,
              ),
              const SizedBox(height: 16),
              _DeptCard(
                dept: Department.sosyal,
                label: 'Sosyal Bilimler',
                subtitle: 'Metodoloji · Sosyoloji · Hukuk',
                icon: Icons.groups,
                color: Colors.orange,
                locked: true,
              ),
              const Spacer(),
              OutlinedButton.icon(
                onPressed: () => context.push('/progress'),
                icon: const Icon(Icons.bar_chart),
                label: const Text('İlerleme & İstatistikler'),
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size.fromHeight(48),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DeptCard extends StatelessWidget {
  final Department dept;
  final String label;
  final String subtitle;
  final IconData icon;
  final Color color;
  final bool locked;

  const _DeptCard({
    required this.dept,
    required this.label,
    required this.subtitle,
    required this.icon,
    required this.color,
    this.locked = false,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: color.withValues(alpha: 0.3)),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: locked
            ? () => _showPremiumDialog(context)
            : () => context.push('/quiz/${dept.name}'),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Row(
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color, size: 28),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(label,
                        style: const TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 16)),
                    const SizedBox(height: 2),
                    Text(subtitle,
                        style: TextStyle(
                            color: Colors.grey[600], fontSize: 13)),
                  ],
                ),
              ),
              Icon(
                locked ? Icons.lock_outline : Icons.arrow_forward_ios,
                size: 18,
                color: Colors.grey[400],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showPremiumDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Premium Bölüm'),
        content: const Text(
            'Bu bölüme erişmek için premium abonelik gerekiyor.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Kapat')),
          FilledButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Premium\'a Geç')),
        ],
      ),
    );
  }
}
