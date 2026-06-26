import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/user_progress.dart';
import '../../services/progress_service.dart';

class ProgressScreen extends StatefulWidget {
  const ProgressScreen({super.key});

  @override
  State<ProgressScreen> createState() => _ProgressScreenState();
}

class _ProgressScreenState extends State<ProgressScreen> {
  Map<String, UserProgress> _progress = {};
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final p = await context.read<ProgressService>().loadProgress();
    setState(() {
      _progress = p;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final learned = _progress.values.where((p) => p.correctCount >= 3).length;
    final reviewing = _progress.values.where((p) => p.correctCount > 0 && p.correctCount < 3).length;
    final total = _progress.length;

    return Scaffold(
      appBar: AppBar(title: const Text('İlerleme')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            _StatCard(
              label: 'Öğrenilen kelimeler',
              value: learned.toString(),
              icon: Icons.check_circle,
              color: Colors.green,
            ),
            const SizedBox(height: 16),
            _StatCard(
              label: 'Tekrar gerektiren',
              value: reviewing.toString(),
              icon: Icons.replay,
              color: Colors.orange,
            ),
            const SizedBox(height: 16),
            _StatCard(
              label: 'Toplam çalışılan',
              value: total.toString(),
              icon: Icons.menu_book,
              color: Colors.blue,
            ),
          ],
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const _StatCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: color.withValues(alpha: 0.3)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            Icon(icon, color: color, size: 32),
            const SizedBox(width: 16),
            Expanded(child: Text(label)),
            Text(value,
                style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: color)),
          ],
        ),
      ),
    );
  }
}
