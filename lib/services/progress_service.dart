import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/models.dart';

class ProgressService {
  static final ProgressService _instance = ProgressService._();
  factory ProgressService() => _instance;
  ProgressService._();

  static const _progressKey = 'word_progress_v2';

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
}
