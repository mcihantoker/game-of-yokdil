import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/models.dart';
import '../models/game_models.dart';

class ProgressService {
  static final ProgressService _instance = ProgressService._();
  factory ProgressService() => _instance;
  ProgressService._();

  static const _progressKey = 'word_progress_v2';
  static const _mapKeyPrefix = 'treasure_map_';
  static const _deptKey = 'selected_dept';
  static const _goldKey = 'game_gold';
  static const _streakKey = 'game_streak';

  // ─── Kelime ilerleme ─────────────────────────────────────────────────────────
  Future<Map<String, WordProgress>> load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_progressKey);
    if (raw == null) return {};
    final map = jsonDecode(raw) as Map<String, dynamic>;
    return map.map((k, v) => MapEntry(k, WordProgress.fromJson(v as Map<String, dynamic>)));
  }

  Future<void> save(Map<String, WordProgress> progress) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_progressKey, jsonEncode(
      progress.map((k, v) => MapEntry(k, v.toJson())),
    ));
  }

  Future<WordProgress> recordAnswer({
    required String wordId,
    required bool correct,
    required Map<String, WordProgress> allProgress,
  }) async {
    final p = allProgress[wordId] ?? WordProgress(wordId: wordId);
    p.updateSM2(correct ? 4 : 1);
    allProgress[wordId] = p;
    await save(allProgress);
    return p;
  }

  // ─── Harita kalıcı kaydetme ───────────────────────────────────────────────────
  Future<void> saveMap(TreasureMap map) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('$_mapKeyPrefix${map.departmentId}', jsonEncode(map.toJson()));
  }

  Future<TreasureMap?> loadMap(String deptId, String theme) async {
    final prefs = await SharedPreferences.getInstance();
    final str = prefs.getString('$_mapKeyPrefix$deptId');
    if (str == null) return null;
    try {
      return TreasureMap.fromJson(jsonDecode(str) as Map<String, dynamic>);
    } catch (_) {
      return null;
    }
  }

  // ─── Seçili bölüm kaydetme ───────────────────────────────────────────────────
  Future<void> saveSelectedDept(String deptName) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_deptKey, deptName);
  }

  Future<String?> loadSelectedDept() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_deptKey);
  }

  // ─── Altın & seri kaydetme ────────────────────────────────────────────────────
  Future<void> saveGameState({required int gold, required int streak}) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_goldKey, gold);
    await prefs.setInt(_streakKey, streak);
  }

  Future<({int gold, int streak})> loadGameState() async {
    final prefs = await SharedPreferences.getInstance();
    return (
      gold: prefs.getInt(_goldKey) ?? 0,
      streak: prefs.getInt(_streakKey) ?? 0,
    );
  }
}
