import 'dart:convert';
import 'package:flutter/services.dart';
import '../models/models.dart';

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

  List<Question> buildQuestions(List<Word> words, {int count = 10}) {
    final pool = [...words]..shuffle();
    final selection = pool.take(count).toList();
    final allMeanings = words.map((w) => w.trMeaning).toList();

    return selection.map((w) {
      final others = allMeanings.where((m) => m != w.trMeaning).toList()..shuffle();
      final opts = [w.trMeaning, others[0], others[1], others[2]]..shuffle();
      return Question(
        word: w,
        options: opts,
        correctIndex: opts.indexOf(w.trMeaning),
      );
    }).toList();
  }
}
