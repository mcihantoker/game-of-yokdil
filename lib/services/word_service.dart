import 'dart:convert';
import 'package:flutter/services.dart';
import '../models/word.dart';

class WordService {
  static final WordService _instance = WordService._();
  factory WordService() => _instance;
  WordService._();

  final Map<Department, List<Word>> _cache = {};

  Future<List<Word>> getWords(Department dept) async {
    if (_cache.containsKey(dept)) return _cache[dept]!;
    final path = 'assets/data/words_${dept.name}.json';
    final raw = await rootBundle.loadString(path);
    final list = jsonDecode(raw) as List;
    final words = list.map((e) => Word.fromJson(e as Map<String, dynamic>)).toList();
    _cache[dept] = words;
    return words;
  }

  Future<List<Word>> getDueWords(Department dept, List<String> dueIds) async {
    final words = await getWords(dept);
    return words.where((w) => dueIds.contains(w.id)).toList();
  }

  List<String> buildWrongOptions(String correctMeaning, List<Word> allWords) {
    final others = allWords
        .where((w) => w.trMeaning != correctMeaning)
        .map((w) => w.trMeaning)
        .toList()
      ..shuffle();
    return others.take(3).toList();
  }
}
