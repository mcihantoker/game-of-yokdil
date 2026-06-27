import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../theme/app_theme.dart';
import '../../models/models.dart';
import '../../models/game_models.dart';
import '../../widgets/shared_widgets.dart';
import '../../visual/app_assets.dart';
import '../../visual/visual_effects.dart';

class MapScreen extends StatefulWidget {
  final TreasureMap map;
  final Department department;
  final int gold;
  final int streak;
  final VoidCallback onStartQuiz;
  final VoidCallback onBossReady;
  final Function(int) onTreasure;
  final VoidCallback? onBack;

  const MapScreen({
    super.key,
    required this.map,
    required this.department,
    required this.gold,
    required this.streak,
    required this.onStartQuiz,
    required this.onBossReady,
    required this.onTreasure,
    this.onBack,
  });

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> with TickerProviderStateMixin {
  late AnimationController _glowCtrl;

  @override
  void initState() {
    super.initState();
    _glowCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    )..repeat(reverse: true);
  }

  @override
  void dispose() { _glowCtrl.dispose(); super.dispose(); }

  Color get _deptColor => deptColor(widget.department);
  Color get _deptDim   => deptDimColor(widget.department);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
                child: Column(
                  children: [
                    const SizedBox(height: 4),
                    _buildMapStats(),
                    const SizedBox(height: 12),
                    _buildGrid(),
                    const SizedBox(height: 14),
                    _buildLegend(),
                    const SizedBox(height: 14),
                    _buildActionCard(),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 12),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: AppColors.border)),
      ),
      child: Row(
        children: [
          if (widget.onBack != null)
            GestureDetector(
              onTap: widget.onBack,
              child: const Padding(
                padding: EdgeInsets.only(right: 10),
                child: Icon(Icons.arrow_back_ios_new_rounded, color: AppColors.muted, size: 18),
              ),
            ),
          Image.asset('assets/logo.png', width: 80, filterQuality: FilterQuality.high),
          const Spacer(),
          StatPill(value: widget.streak.toString(),
              icon: Icons.local_fire_department_rounded, iconColor: AppColors.sosyal),
          const SizedBox(width: 8),
          StatPill(value: widget.gold.toString(),
              icon: Icons.monetization_on_rounded, iconColor: AppColors.sosyal),
        ],
      ),
    );
  }

  Widget _buildMapStats() {
    final map = widget.map;
    final pct = map.openCount / TreasureMap.gridSize;
    return SurfaceCard(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      borderRadius: AppRadius.mdBR,
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(map.themeName,
                    style: AppTextStyles.display(13, weight: FontWeight.w600)),
                const SizedBox(height: 2),
                Text('${map.openCount} / ${TreasureMap.gridSize} hücre açıldı',
                    style: AppTextStyles.body(11, color: AppColors.muted)),
                const SizedBox(height: 6),
                AppProgressBar(value: pct, color: _deptColor, height: 4),
              ],
            ),
          ),
          const SizedBox(width: 14),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(color: _deptDim, borderRadius: AppRadius.smBR),
            child: Text(
              '${(pct * 100).round()}%',
              style: AppTextStyles.mono(16, color: _deptColor, weight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGrid() {
    return MapTextureBackground(
      child: Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.bg2,
        borderRadius: AppRadius.lgBR,
        border: Border.all(color: AppColors.border2),
      ),
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: TreasureMap.gridWidth,
          crossAxisSpacing: 6,
          mainAxisSpacing: 6,
        ),
        itemCount: TreasureMap.gridSize,
        itemBuilder: (ctx, i) => _buildCell(widget.map.cells[i]),
      ),
    ));
  }

  Widget _buildCell(MapCell cell) {
    return GestureDetector(
      onTap: () => _onCellTap(cell),
      child: AnimatedBuilder(
        animation: _glowCtrl,
        builder: (ctx, child) {
          final glow = cell.type == CellType.current
              ? _glowCtrl.value * 6.0
              : cell.type == CellType.boss
              ? _glowCtrl.value * 4.0
              : 0.0;

          return AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            decoration: BoxDecoration(
              color: _cellColor(cell.type),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: _cellBorderColor(cell.type),
                width: cell.type == CellType.current ? 2 : 1,
              ),
              boxShadow: glow > 0
                  ? [BoxShadow(
                      color: _cellBorderColor(cell.type).withValues(alpha: 0.4),
                      blurRadius: glow,
                      spreadRadius: 0,
                    )]
                  : null,
            ),
            child: Center(child: _cellContent(cell)),
          );
        },
      ),
    );
  }

  Color _cellColor(CellType t) {
    switch (t) {
      case CellType.locked:  return AppColors.bg.withValues(alpha: 0.6);
      case CellType.open:    return _deptColor.withValues(alpha: 0.1);
      case CellType.current: return _deptColor.withValues(alpha: 0.22);
      case CellType.treasure:return AppColors.sosyal.withValues(alpha: 0.18);
      case CellType.boss:    return AppColors.danger.withValues(alpha: 0.14);
    }
  }

  Color _cellBorderColor(CellType t) {
    switch (t) {
      case CellType.locked:  return AppColors.border;
      case CellType.open:    return _deptColor.withValues(alpha: 0.28);
      case CellType.current: return _deptColor;
      case CellType.treasure:return AppColors.sosyal.withValues(alpha: 0.6);
      case CellType.boss:    return AppColors.danger.withValues(alpha: 0.5);
    }
  }

  Widget _cellContent(MapCell cell) {
    return CellIconImage(
      type: cell.type,
      size: 18,
      fallbackBuilder: (type) => switch (type) {
        CellType.locked   => Icon(Icons.lock_rounded, size: 13, color: AppColors.dim),
        CellType.open     => cell.isCleared
            ? Icon(Icons.check_rounded, size: 13, color: _deptColor.withValues(alpha: 0.6))
            : Icon(Icons.circle, size: 7, color: _deptColor.withValues(alpha: 0.4)),
        CellType.current  => const Text('📍', style: TextStyle(fontSize: 14)),
        CellType.treasure => const Text('💰', style: TextStyle(fontSize: 14)),
        CellType.boss     => const Text('👹', style: TextStyle(fontSize: 14)),
      },
    );
  }

  void _onCellTap(MapCell cell) {
    HapticFeedback.selectionClick();
    switch (cell.type) {
      case CellType.locked:
        _showLockedSnack();
      case CellType.open:
      case CellType.current:
        widget.onStartQuiz();
      case CellType.treasure:
        widget.onTreasure(cell.index);
      case CellType.boss:
        if (widget.map.bossReachable) {
          widget.onBossReady();
        } else {
          _showLockedSnack();
        }
    }
  }

  void _showLockedSnack() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Bu hücreye ulaşmak için etrafını temizle!',
            style: AppTextStyles.body(13)),
        backgroundColor: AppColors.bg3,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: AppRadius.mdBR),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  Widget _buildLegend() {
    return Wrap(
      spacing: 12, runSpacing: 6,
      children: [
        _legendItem(AppColors.sosyal.withValues(alpha: 0.3), '💰', 'Hazine'),
        _legendItem(AppColors.danger.withValues(alpha: 0.3), '👹', 'Boss'),
        _legendItem(_deptColor.withValues(alpha: 0.25), '📍', 'Konum'),
        _legendItem(AppColors.border, null, 'Kilitli'),
      ],
    );
  }

  Widget _legendItem(Color color, String? emoji, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 14, height: 14,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(3),
          ),
          child: emoji != null
              ? Center(child: Text(emoji, style: const TextStyle(fontSize: 8)))
              : null,
        ),
        const SizedBox(width: 5),
        Text(label, style: AppTextStyles.body(11, color: AppColors.muted)),
      ],
    );
  }

  Widget _buildActionCard() {
    final bossReady = widget.map.bossReachable;
    return SurfaceCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            bossReady ? 'Boss hazır!' : 'Haritayı keşfet',
            style: AppTextStyles.display(15, weight: FontWeight.w600,
                color: bossReady ? AppColors.danger : AppColors.text),
          ),
          const SizedBox(height: 4),
          Text(
            bossReady
                ? 'Boss hücresine ulaştın. Savaşa giriyor musun?'
                : 'Doğru cevap ver → hücre aç → hazineye ulaş → boss\'u yen.',
            style: AppTextStyles.body(12, color: AppColors.muted),
          ),
          const SizedBox(height: 12),
          PrimaryButton(
            label: bossReady ? '⚔️  Boss\'a meydan oku' : 'Soru çöz, haritayı aç →',
            onTap: bossReady ? widget.onBossReady : widget.onStartQuiz,
            color: bossReady ? AppColors.danger : _deptColor,
          ),
        ],
      ),
    );
  }
}
