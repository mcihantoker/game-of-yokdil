// ─── Bölüm Enum ──────────────────────────────────────────────────────────────
enum Department { fen, saglik, sosyal }

extension DepartmentExt on Department {
  String get label {
    switch (this) {
      case Department.fen:    return 'Fen Bilimleri';
      case Department.saglik: return 'Sağlık Bilimleri';
      case Department.sosyal: return 'Sosyal Bilimler';
    }
  }

  String get shortLabel {
    switch (this) {
      case Department.fen:    return 'Fen';
      case Department.saglik: return 'Sağlık';
      case Department.sosyal: return 'Sosyal';
    }
  }
}

// ─── Kelime Modeli ───────────────────────────────────────────────────────────
class Word {
  final String id;
  final String word;
  final String phonetic;
  final String trMeaning;
  final String exampleSentence;
  final Department department;
  final String theme;
  final List<int> examYears;
  final bool highProbability;

  const Word({
    required this.id,
    required this.word,
    required this.phonetic,
    required this.trMeaning,
    required this.exampleSentence,
    required this.department,
    required this.theme,
    required this.examYears,
    this.highProbability = false,
  });

  factory Word.fromJson(Map<String, dynamic> j) => Word(
    id:              j['id'] as String,
    word:            j['word'] as String,
    phonetic:        j['phonetic'] as String? ?? '',
    trMeaning:       j['tr_meaning'] as String,
    exampleSentence: j['example_sentence'] as String,
    department:      Department.values.firstWhere((d) => d.name == j['department']),
    theme:           j['theme'] as String,
    examYears:       List<int>.from(j['exam_years'] as List),
    highProbability: j['high_probability'] as bool? ?? false,
  );
}

// ─── Soru Modeli ─────────────────────────────────────────────────────────────
class Question {
  final Word word;
  final List<String> options;
  final int correctIndex;

  const Question({
    required this.word,
    required this.options,
    required this.correctIndex,
  });
}

// ─── Kullanıcı İlerlemesi (SM-2) ─────────────────────────────────────────────
class WordProgress {
  final String wordId;
  int correctCount;
  int wrongCount;
  DateTime nextReviewAt;
  double easeFactor;

  WordProgress({
    required this.wordId,
    this.correctCount = 0,
    this.wrongCount = 0,
    DateTime? nextReviewAt,
    this.easeFactor = 2.5,
  }) : nextReviewAt = nextReviewAt ?? DateTime.now();

  bool get needsReview => DateTime.now().isAfter(nextReviewAt);

  void updateSM2(int q) {
    if (q >= 3) {
      correctCount++;
      final n = correctCount;
      final interval = n == 1 ? 1 : n == 2 ? 6 : (6 * easeFactor).round();
      nextReviewAt = DateTime.now().add(Duration(days: interval));
      easeFactor = (easeFactor + 0.1 - (5 - q) * (0.08 + (5 - q) * 0.02)).clamp(1.3, 2.5);
    } else {
      wrongCount++;
      correctCount = 0;
      nextReviewAt = DateTime.now().add(const Duration(minutes: 10));
    }
  }

  Map<String, dynamic> toJson() => {
    'wordId':       wordId,
    'correctCount': correctCount,
    'wrongCount':   wrongCount,
    'nextReviewAt': nextReviewAt.toIso8601String(),
    'easeFactor':   easeFactor,
  };

  factory WordProgress.fromJson(Map<String, dynamic> j) => WordProgress(
    wordId:       j['wordId'] as String,
    correctCount: j['correctCount'] as int,
    wrongCount:   j['wrongCount'] as int,
    nextReviewAt: DateTime.parse(j['nextReviewAt'] as String),
    easeFactor:   (j['easeFactor'] as num).toDouble(),
  );
}

// ─── Oturum Sonucu ───────────────────────────────────────────────────────────
class SessionResult {
  final Department department;
  final String theme;
  final int totalQuestions;
  final int correctAnswers;
  final List<Word> learnedWords;
  final DateTime completedAt;

  const SessionResult({
    required this.department,
    required this.theme,
    required this.totalQuestions,
    required this.correctAnswers,
    required this.learnedWords,
    required this.completedAt,
  });

  double get accuracy => totalQuestions == 0 ? 0 : correctAnswers / totalQuestions;
  int get xpEarned => correctAnswers * 20 + (accuracy == 1.0 ? 50 : 0);
}
