import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user_progress.dart';
import '../models/user_stats.dart';
import '../models/word.dart';
import 'sm2_service.dart';

class ProgressService {
  static const _progressKey = 'user_progress';
  static const _statsKey = 'user_stats';

  Future<Map<String, UserProgress>> loadProgress() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_progressKey);
    if (raw == null) return {};
    final map = jsonDecode(raw) as Map<String, dynamic>;
    return map.map((k, v) => MapEntry(k, UserProgress.fromJson(v as Map<String, dynamic>)));
  }

  Future<void> saveProgress(Map<String, UserProgress> progress) async {
    final prefs = await SharedPreferences.getInstance();
    final map = progress.map((k, v) => MapEntry(k, v.toJson()));
    await prefs.setString(_progressKey, jsonEncode(map));
  }

  Future<UserStats?> loadStats(String userId) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString('${_statsKey}_$userId');
    if (raw == null) return null;
    return UserStats.fromJson(jsonDecode(raw) as Map<String, dynamic>);
  }

  Future<void> saveStats(UserStats stats) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('${_statsKey}_${stats.userId}', jsonEncode(stats.toJson()));
  }

  Future<UserProgress> recordAnswer({
    required String wordId,
    required bool correct,
    required Map<String, UserProgress> allProgress,
  }) async {
    final progress = allProgress[wordId] ?? UserProgress(wordId: wordId);
    final quality = correct ? 4 : 1;
    final updated = Sm2Service.update(progress, quality);
    allProgress[wordId] = updated;
    await saveProgress(allProgress);
    return updated;
  }

  List<String> getDueWordIds(Map<String, UserProgress> progress, Department dept, List<String> deptWordIds) {
    final due = deptWordIds.where((id) {
      final p = progress[id];
      return p == null || p.isDueForReview;
    }).toList();
    return due;
  }
}
