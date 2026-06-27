import 'dart:math';
import 'models.dart';

// ─── Harita Hücresi ───────────────────────────────────────────────────────────
enum CellType { locked, open, treasure, boss, current }

class MapCell {
  final int index;
  CellType type;
  bool isUnlocked;
  bool isCleared; // kelimesi doğru cevaplanmış

  MapCell({
    required this.index,
    required this.type,
    this.isUnlocked = false,
    this.isCleared = false,
  });

  // Hücre komşuları (4 yön)
  List<int> neighbors(int gridWidth, int totalCells) {
    final neighbors = <int>[];
    final row = index ~/ gridWidth;
    final col = index % gridWidth;
    if (row > 0) neighbors.add(index - gridWidth); // üst
    if (row < (totalCells ~/ gridWidth) - 1) neighbors.add(index + gridWidth); // alt
    if (col > 0) neighbors.add(index - 1); // sol
    if (col < gridWidth - 1) neighbors.add(index + 1); // sağ
    return neighbors;
  }
}

// ─── Harita Durumu ────────────────────────────────────────────────────────────
class TreasureMap {
  static const int gridWidth = 5;
  static const int gridSize = 25;

  final String departmentId;
  final String themeName;
  final List<MapCell> cells;
  int currentPosition; // oyuncunun bulunduğu hücre
  int gold;
  bool bossDefeated;

  TreasureMap({
    required this.departmentId,
    required this.themeName,
    required this.cells,
    this.currentPosition = 0,
    this.gold = 0,
    this.bossDefeated = false,
  });

  // Yeni harita oluştur
  factory TreasureMap.generate(String deptId, String theme) {
    final cells = List.generate(gridSize, (i) {
      CellType type;
      if (i == 0) {
        type = CellType.current; // başlangıç
      } else if (i == gridSize - 1) {
        type = CellType.boss; // son hücre boss
      } else if (i == 7 || i == 17) {
        type = CellType.treasure; // hazineler
      } else {
        type = CellType.locked;
      }
      return MapCell(
        index: i,
        type: type,
        isUnlocked: i == 0,
      );
    });
    return TreasureMap(
      departmentId: deptId,
      themeName: theme,
      cells: cells,
    );
  }

  // Doğru cevap sonrası hücre aç
  void unlockNext() {
    final current = cells[currentPosition];
    current.isCleared = true;
    final neighbors = current.neighbors(gridWidth, gridSize);
    for (final n in neighbors) {
      if (!cells[n].isUnlocked) {
        cells[n].isUnlocked = true;
        if (cells[n].type == CellType.locked) {
          cells[n].type = CellType.open;
        }
      }
    }
  }

  // Oyuncu hareket et
  bool moveTo(int index) {
    if (!cells[index].isUnlocked) return false;
    cells[currentPosition].type =
        cells[currentPosition].type == CellType.current
            ? CellType.open
            : cells[currentPosition].type;
    currentPosition = index;
    cells[index].type = CellType.current;
    return true;
  }

  bool get bossReachable => cells[gridSize - 1].isUnlocked;
  int get openCount => cells.where((c) => c.isCleared).length;
  int get treasureCount => cells.where((c) => c.type == CellType.treasure && c.isCleared).length;
}

// ─── Boss Savaşı ──────────────────────────────────────────────────────────────
class BossBattle {
  final Department department;
  final String bossName;
  final String bossEmoji;
  final int totalHp; // kaç doğru gerekiyor
  int currentHp;
  int combo;
  int maxCombo;
  int timePerQuestion; // saniye
  bool isDefeated;

  BossBattle({
    required this.department,
    required this.bossName,
    required this.bossEmoji,
    this.totalHp = 5,
    this.currentHp = 0,
    this.combo = 0,
    this.maxCombo = 0,
    this.timePerQuestion = 15,
    this.isDefeated = false,
  });

  double get hpPercent => currentHp / totalHp;

  // Doğru cevap
  void onCorrect() {
    currentHp = min(currentHp + 1, totalHp);
    combo++;
    maxCombo = max(combo, maxCombo);
    if (currentHp >= totalHp) isDefeated = true;
  }

  // Yanlış cevap veya süre doldu
  void onWrong() {
    currentHp = max(currentHp - 1, 0);
    combo = 0;
  }

  // Combo çarpanı (XP için)
  int get comboMultiplier => min(combo, 5);

  // Boss bilgileri dept'e göre
  static BossBattle forDepartment(Department dept) {
    switch (dept) {
      case Department.fen:
        return BossBattle(
          department: dept,
          bossName: 'Araştırma Yöntemleri Canavarı',
          bossEmoji: '👹',
          totalHp: 5,
          timePerQuestion: 15,
        );
      case Department.saglik:
        return BossBattle(
          department: dept,
          bossName: 'Klinik Terimler Ejderhası',
          bossEmoji: '🐉',
          totalHp: 6,
          timePerQuestion: 12,
        );
      case Department.sosyal:
        return BossBattle(
          department: dept,
          bossName: 'Metodoloji Kâbusu',
          bossEmoji: '👺',
          totalHp: 7,
          timePerQuestion: 10,
        );
    }
  }
}

// ─── Hazine Ödülü ─────────────────────────────────────────────────────────────
enum RewardType { xp, gold, badge, unlock }

class Reward {
  final RewardType type;
  final String title;
  final String description;
  final String emoji;
  final String value; // "+250 XP", "+80", "Yeni!" vs.

  const Reward({
    required this.type,
    required this.title,
    required this.description,
    required this.emoji,
    required this.value,
  });
}

class ChestRewards {
  final List<Reward> rewards;
  final bool isGrandChest; // boss sonrası büyük hazine mi?

  const ChestRewards({required this.rewards, this.isGrandChest = false});

  // Boss yenilince oluşan hazine
  static ChestRewards forBossVictory(Department dept, int maxCombo) {
    final xpBonus = 150 + (maxCombo * 20);
    return ChestRewards(
      isGrandChest: true,
      rewards: [
        Reward(
          type: RewardType.xp,
          title: 'XP bonusu',
          description: 'Boss yenildi + ×$maxCombo combo',
          emoji: '⭐',
          value: '+$xpBonus',
        ),
        Reward(
          type: RewardType.gold,
          title: 'Altın',
          description: 'Hazine ödülü',
          emoji: '🪙',
          value: '+80',
        ),
        Reward(
          type: RewardType.badge,
          title: '${dept.label} ustası rozeti',
          description: 'Boss ilk kez yenildi',
          emoji: '🏅',
          value: 'Yeni!',
        ),
        Reward(
          type: RewardType.unlock,
          title: 'Yeni bölge açıldı',
          description: 'Sonraki harita erişime açık',
          emoji: '🔓',
          value: '→',
        ),
      ],
    );
  }

  // Ara hazine hücresi
  static ChestRewards treasure() {
    return const ChestRewards(
      rewards: [
        Reward(type: RewardType.xp,   title: 'XP',   description: 'Hazine keşfedildi', emoji: '⭐', value: '+50'),
        Reward(type: RewardType.gold,  title: 'Altın', description: 'Hazine içeriği',   emoji: '🪙', value: '+25'),
      ],
    );
  }
}

// ─── Combo State ──────────────────────────────────────────────────────────────
class ComboState {
  int current;
  static const int max = 5;

  ComboState({this.current = 0});

  void increment() => current = min(current + 1, max);
  void reset() => current = 0;

  int get multiplier => current == 0 ? 1 : current;
  double get progress => current / max;
}
